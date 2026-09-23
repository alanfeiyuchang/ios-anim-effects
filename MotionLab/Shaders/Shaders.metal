#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Helpers

static float mlHash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

static float mlNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = mlHash(i);
    float b = mlHash(i + float2(1.0, 0.0));
    float c = mlHash(i + float2(0.0, 1.0));
    float d = mlHash(i + float2(1.0, 1.0));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static float mlFbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int k = 0; k < 4; k++) {
        value += amplitude * mlNoise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// MARK: - Ripple (layer effect)
// A damped sine wave radiating from `origin`, after Apple's WWDC24 sample.

[[ stitchable ]]
half4 mlRipple(float2 position, SwiftUI::Layer layer, float2 origin, float time,
               float amplitude, float frequency, float decay, float speed) {
    float distance = length(position - origin);
    float delay = distance / speed;
    float t = max(0.0, time - delay);
    float rippleAmount = amplitude * sin(frequency * t) * exp(-decay * t);
    float2 direction = distance > 0.0001 ? (position - origin) / distance : float2(0.0);
    float2 newPosition = position + rippleAmount * direction;
    half4 color = layer.sample(newPosition);
    color.rgb += half(0.3 * (rippleAmount / max(amplitude, 0.0001))) * color.a;
    return color;
}

// MARK: - Pixelate (layer effect)

[[ stitchable ]]
half4 mlPixelate(float2 position, SwiftUI::Layer layer, float size) {
    float s = max(size, 1.0);
    float2 cell = floor(position / s) * s + s * 0.5;
    return layer.sample(cell);
}

// MARK: - Glitch (layer effect)
// Digital codec corruption, not analog tape: the image is cut into `block`-sized macro-blocks and, per step
// of `rate` Hz, clusters of 4×2 blocks are hit. A hit block either jumps to a neighbouring block (2D offset
// quantized to half-blocks) or freezes into vertical streaks of its own top row; R/B split by `split` and
// hit blocks also swap channels. Near full intensity (the tap burst) the palette posterizes to 4 levels.
// Samples move at most one block plus the split, so the caller's maxSampleOffset is block + split × 1.7.

[[ stitchable ]]
half4 mlGlitch(float2 position, SwiftUI::Layer layer, float time, float intensity,
               float split, float block, float rate) {
    float s = max(block, 4.0);
    float2 cell = floor(position / s);
    float frame = floor(time * max(rate, 0.5));
    float2 region = floor(cell / float2(4.0, 2.0));
    float hit = step(1.0 - (0.04 + 0.22 * intensity), mlHash(region + float2(frame * 0.713, frame * 0.291)));
    float h1 = mlHash(cell + float2(frame * 1.37, 3.1));
    float h2 = mlHash(cell * 1.91 + float2(7.7, frame * 0.53));
    float2 p = position;
    if (hit > 0.5) {
        if (h1 < 0.55) {
            float2 jump = floor(float2(h1 / 0.55, h2) * 5.0) - 2.0;
            p += jump * s * 0.5;
        } else {
            p.y = cell.y * s + 0.5;
        }
    }
    float offset = split * (0.35 + intensity * 1.3);
    float2 chroma = float2(offset, offset * 0.5 * hit);
    half4 base = layer.sample(p);
    half4 red = layer.sample(p + chroma);
    half4 blue = layer.sample(p - chroma);
    half4 color = half4(red.r, base.g, blue.b, max(base.a, max(red.a, blue.a)));
    if (hit > 0.5 && h2 > 0.7) {
        color.rgb = color.gbr;
    }
    float posterize = smoothstep(0.75, 1.0, intensity);
    if (posterize > 0.0 && color.a > 0.001h) {
        float3 rgb = float3(color.rgb) / float(color.a);
        float3 stepped = floor(rgb * 3.0 + 0.5) / 3.0;
        color.rgb = half3(mix(rgb, stepped, posterize) * float(color.a));
    }
    return color;
}

// MARK: - Noise dissolve (color effect)
// The cut is anti-aliased over a tiny noise band; just inside it an ember ramp runs
// white-hot core → edge color → charred rim → untouched artwork.

[[ stitchable ]]
half4 mlDissolve(float2 position, half4 color, float progress, float scale, half4 edgeColor) {
    if (color.a < 0.001h) {
        return color;
    }
    float n = mlFbm(position / max(scale, 1.0));
    float threshold = progress * 1.2 - 0.1;
    float d = n - threshold;
    float alpha = smoothstep(-0.006, 0.006, d);
    if (alpha <= 0.0) {
        return half4(0.0h);
    }
    float3 rgb = float3(color.rgb) / float(color.a);
    float3 edge = float3(edgeColor.rgb);
    float t = clamp(d / 0.1, 0.0, 1.0);
    float3 hot = mix(float3(1.0, 0.97, 0.84), edge, smoothstep(0.0, 0.3, t));
    float3 burnt = mix(hot, edge * 0.28, smoothstep(0.3, 0.62, t));
    float3 outColor = mix(burnt, rgb, smoothstep(0.55, 1.0, t));
    float a = float(color.a) * alpha;
    return half4(half3(outColor * a), half(a));
}

// MARK: - Bulge / magnifier (distortion effect)

[[ stitchable ]]
float2 mlBulge(float2 position, float2 center, float radius, float strength) {
    float2 d = position - center;
    float dist = length(d);
    if (dist >= radius) {
        return position;
    }
    float t = dist / radius;
    float factor = mix(1.0 - strength, 1.0, t * t);
    return center + d * factor;
}

// MARK: - Liquid lens droplet (distortion effect)
// iOS 18 fallback for the Liquid Glass lens: a bulge whose footprint is an ellipse stretched by `stretch`
// along `heading` (radians, y-down), matching the droplet's rotate(−θ) → scale → rotate(θ) transform.
// `ripple` in (0, 1) runs a water-bead ring outward through the lens and fades; 0 (or 1) turns it off.

[[ stitchable ]]
float2 mlLensDrop(float2 position, float2 center, float radius, float strength, float heading,
                  float stretch, float ripple) {
    float2 d = position - center;
    float c = cos(heading);
    float s = sin(heading);
    float2 local = float2(c * d.x + s * d.y, -s * d.x + c * d.y);
    float2 axes = max(radius * float2(1.0 + stretch, 1.0 - stretch * 0.6), float2(1.0));
    float t = length(local / axes);
    float2 source = local;
    if (t < 1.0) {
        source = local * mix(1.0 - strength, 1.0, t * t);
    }
    if (ripple > 0.001 && ripple < 0.999 && t < 1.4) {
        float band = t - ripple * 1.35;
        float wave = exp(-band * band * 40.0) * sin(band * 18.0) * (1.0 - ripple);
        float len = length(local);
        if (len > 0.001) {
            source += (local / len) * wave * 6.0;
        }
    }
    return center + float2(c * source.x - s * source.y, s * source.x + c * source.y);
}

// MARK: - Swirl (distortion effect)

[[ stitchable ]]
float2 mlSwirl(float2 position, float2 center, float radius, float angle) {
    float2 d = position - center;
    float dist = length(d);
    if (dist >= radius) {
        return position;
    }
    float t = 1.0 - dist / radius;
    float a = angle * t * t;
    float s = sin(a);
    float c = cos(a);
    return center + float2(d.x * c - d.y * s, d.x * s + d.y * c);
}

// MARK: - Plasma (color effect, generative)
// Four summed sine fields mapped onto a limited, cyclic cyan → violet → gold ramp over deep indigo troughs.

static float3 mlPlasmaRamp(float t) {
    float3 cyan = float3(0.16, 0.86, 1.0);
    float3 violet = float3(0.56, 0.30, 1.0);
    float3 gold = float3(1.0, 0.77, 0.30);
    float x = fract(t) * 3.0;
    float3 a = x < 1.0 ? cyan : (x < 2.0 ? violet : gold);
    float3 b = x < 1.0 ? violet : (x < 2.0 ? gold : cyan);
    return mix(a, b, smoothstep(0.0, 1.0, fract(x)));
}

// `origin` / `age` (seconds, < 0 when idle) inject a tap ripple: a ring travelling at ~260 pt/s that
// perturbs the field and fades out over ~2.5 s.
[[ stitchable ]]
half4 mlPlasma(float2 position, half4 color, float2 size, float time, float scale, float2 origin, float age) {
    float2 uv = position / max(size, float2(1.0));
    float v = sin(uv.x * 6.0 * scale + time)
            + sin(uv.y * 7.0 * scale - time * 1.3)
            + sin((uv.x + uv.y) * 5.0 * scale + time * 0.7)
            + sin(length(uv - 0.5) * 12.0 * scale - time * 2.0);
    if (age >= 0.0 && age < 2.5) {
        float d = length(position - origin);
        float ring = (d - age * 260.0) / 46.0;
        v += 1.6 * exp(-ring * ring) * exp(-age * 1.4) * sin(d * 0.07 - age * 9.0);
    }
    v *= 0.25;
    float3 col = mlPlasmaRamp(v * 0.8 + time * 0.03);
    float shade = 0.62 + 0.38 * cos(v * 6.28318);
    col = mix(float3(0.05, 0.04, 0.17), col, shade);
    return half4(half3(col), 1.0h) * color.a;
}

// MARK: - CRT (layer effect)
// `scanlines` is the scanline depth (0 = none), `bleed` the phosphor R/B offset in points.

[[ stitchable ]]
half4 mlCRT(float2 position, SwiftUI::Layer layer, float2 size, float time, float curvature,
            float scanlines, float bleed) {
    float2 uv = position / max(size, float2(1.0)) * 2.0 - 1.0;
    float2 bend = uv.yx * uv.yx * curvature;
    uv = uv + uv * bend;
    if (abs(uv.x) > 1.0 || abs(uv.y) > 1.0) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }
    float2 p = (uv * 0.5 + 0.5) * size;
    half4 base = layer.sample(p);
    half4 red = layer.sample(p + float2(bleed, 0.0));
    half4 blue = layer.sample(p - float2(bleed, 0.0));
    half4 smear = layer.sample(p - float2(bleed * 2.0, 0.0));
    half4 c = half4(red.r, base.g, blue.b, base.a);
    c.rgb = mix(c.rgb, max(c.rgb, smear.rgb), half(0.35 * clamp(bleed / 3.0, 0.0, 1.0)));
    float scan = 1.0 - scanlines + scanlines * sin(p.y * 2.4 + time * 10.0);
    float roll = 0.96 + 0.04 * sin((p.y / size.y - time * 0.35) * 6.28318);
    float vignette = 1.0 - 0.28 * dot(uv, uv);
    c.rgb *= half(scan * roll * vignette);
    return c;
}

// MARK: - CMYK halftone (layer effect)
// Four rotated dot screens (C 15°, M 75°, Y 0°, K 45°, plus `angle`), each sampled at its own cell center.
// Dot area follows the ink amount (× `gain`); inks multiply over paper like real process printing.

[[ stitchable ]]
half4 mlHalftoneCMYK(float2 position, SwiftUI::Layer layer, float cell, float angle, float gain) {
    half4 here = layer.sample(position);
    if (here.a < 0.01h) {
        return half4(0.0h);
    }
    float s = max(cell, 3.0);
    float3 result = float3(0.99, 0.97, 0.93);
    for (int k = 0; k < 4; k++) {
        float theta = angle + (k == 0 ? 0.2618 : (k == 1 ? 1.3090 : (k == 2 ? 0.0 : 0.7854)));
        float cs = cos(theta);
        float sn = sin(theta);
        float2 rp = float2(cs * position.x + sn * position.y, -sn * position.x + cs * position.y);
        float2 rc = (floor(rp / s) + 0.5) * s;
        float2 center = float2(cs * rc.x - sn * rc.y, sn * rc.x + cs * rc.y);
        half4 c = layer.sample(center);
        float3 rgb = c.a > 0.001h ? float3(c.rgb) / float(c.a) : float3(1.0);
        float black = 1.0 - max(rgb.r, max(rgb.g, rgb.b));
        float denom = max(1.0 - black, 0.001);
        float amount = k == 0 ? (1.0 - rgb.r - black) / denom
                     : (k == 1 ? (1.0 - rgb.g - black) / denom
                     : (k == 2 ? (1.0 - rgb.b - black) / denom : black));
        amount = clamp(amount * gain, 0.0, 1.0);
        float radius = s * 0.7071 * sqrt(amount);
        float d = length(rp - rc);
        float coverage = 1.0 - smoothstep(radius - 0.6, radius + 0.6, d);
        float3 ink = k == 0 ? float3(0.0, 0.66, 0.93)
                   : (k == 1 ? float3(0.92, 0.05, 0.55)
                   : (k == 2 ? float3(1.0, 0.92, 0.05) : float3(0.12, 0.12, 0.15)));
        result *= mix(float3(1.0), ink, coverage * 0.94);
    }
    return half4(half3(result), 1.0h) * here.a;
}

// MARK: - Shaded flag wave (layer effect)
// A sine along x displaces y, a slower cosine along y displaces x at half the amplitude,
// plus fold lighting from the wave's slope: crests catch light, troughs shade.

[[ stitchable ]]
half4 mlFlagWave(float2 position, SwiftUI::Layer layer, float time, float amplitude, float wavelength, float shade) {
    float wl = max(wavelength, 1.0);
    float phaseX = time + position.x / wl;
    float phaseY = time * 0.8 + position.y / wl;
    float2 p = position + float2(cos(phaseY) * amplitude * 0.5, sin(phaseX) * amplitude);
    half4 c = layer.sample(p);
    float slope = cos(phaseX) * amplitude / wl;
    float light = clamp(1.0 + shade * slope * 2.2, 0.55, 1.45);
    c.rgb = min(c.rgb * half(light), half3(c.a));
    return c;
}

// MARK: - Chromatic aberration (layer effect)
// R and B are sampled on either side of G along the motion vector, plus a radial lens fringe toward the edges.

[[ stitchable ]]
half4 mlChromatic(float2 position, SwiftUI::Layer layer, float2 size, float2 shift, float radial) {
    float2 center = size * 0.5;
    float2 fromCenter = (position - center) / max(size.x, 1.0);
    float2 offset = shift + fromCenter * radial;
    half4 g = layer.sample(position);
    half4 r = layer.sample(position + offset);
    half4 b = layer.sample(position - offset);
    half a = max(g.a, max(r.a, b.a));
    return half4(r.r, g.g, b.b, a);
}

// MARK: - Kaleidoscope (layer effect)
// Folds the polar angle into n mirrored wedges: wrap into [0, 2π/n), then mirror about the wedge center
// so every output angle lands in [0, π/n] and neighboring wedges meet seamlessly.
// `rotation` turns the output rosette, `spin` turns the sampled slice of the source (the "tube").
// Samples can land up to the full view size away, so the caller must pass a matching maxSampleOffset.

[[ stitchable ]]
half4 mlKaleidoscope(float2 position, SwiftUI::Layer layer, float2 size, float segments, float rotation, float spin, float zoom) {
    float2 c = size * 0.5;
    float2 d = position - c;
    // zoom ≥ 1 magnifies, so every sample stays inside the source circle (no clamped rim streaks).
    float r = length(d) / max(zoom, 1.0);
    float seg = 6.2831853 / max(floor(segments), 2.0);
    float a = atan2(d.y, d.x) + rotation;
    a = a - seg * floor(a / seg);
    a = abs(a - seg * 0.5);
    float2 p = c + float2(cos(a + spin), sin(a + spin)) * r;
    p = clamp(p, float2(0.5), size - 0.5);
    return layer.sample(p);
}

// MARK: - Edge scan (layer effect)
// Sobel edges on luminance render as neon wireframe above a glowing scan line; below it the original shows.

static float mlLuma(half4 c) {
    return dot(float3(c.rgb), float3(0.299, 0.587, 0.114));
}

[[ stitchable ]]
half4 mlEdgeScan(float2 position, SwiftUI::Layer layer, float scanY, float band, half4 tint, float strength) {
    half4 base = layer.sample(position);
    float s = 1.5;
    float tl = mlLuma(layer.sample(position + float2(-s, -s)));
    float tc = mlLuma(layer.sample(position + float2(0.0, -s)));
    float tr = mlLuma(layer.sample(position + float2(s, -s)));
    float ml = mlLuma(layer.sample(position + float2(-s, 0.0)));
    float mr = mlLuma(layer.sample(position + float2(s, 0.0)));
    float bl = mlLuma(layer.sample(position + float2(-s, s)));
    float bc = mlLuma(layer.sample(position + float2(0.0, s)));
    float br = mlLuma(layer.sample(position + float2(s, s)));
    float gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
    float gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);
    float e = clamp(length(float2(gx, gy)) * strength, 0.0, 1.0);

    half4 dark = half4(0.03h, 0.04h, 0.09h, 1.0h) * base.a;
    half4 neon = dark + base * 0.08h + half4(tint.rgb, 1.0h) * half(e) * base.a;

    float d = scanY - position.y;
    float reveal = smoothstep(-1.0, 1.0, d);
    float glow = exp(-abs(d) / max(band, 1.0));
    half4 color = mix(base, neon, half(reveal));
    color += half4(tint.rgb, 1.0h) * half(glow * 0.85) * base.a;
    color = min(color, half4(1.0h));
    color.rgb = min(color.rgb, half3(color.a));
    return color;
}

// MARK: - Grain gradient (color effect, generative)
// Three soft color fields drift over a base color on domain-warped coordinates, finished with static, per-pixel film grain.

[[ stitchable ]]
half4 mlGrainGradient(float2 position, half4 color, float2 size, float time, float grain,
                      half4 c0, half4 c1, half4 c2, half4 c3, float2 focus, float pixelScale) {
    float2 uv = position / max(size, float2(1.0));
    float2 aspect = float2(size.x / max(size.y, 1.0), 1.0);
    float2 warp = float2(mlFbm(uv * 2.2 + float2(time * 0.07, 0.0)),
                         mlFbm(uv * 2.2 + float2(5.2, time * 0.06)));
    float2 q = uv + 0.14 * (warp - 0.5);

    float2 p1 = float2(0.78 + 0.14 * cos(time * 0.23), 0.28 + 0.16 * sin(time * 0.35));
    float2 p2 = float2(0.28 + 0.18 * cos(time * 0.19 + 1.7), 0.78 + 0.12 * sin(time * 0.29));
    float2 d1 = (q - p1) * aspect;
    float2 d2 = (q - p2) * aspect;
    float2 d3 = (q - focus) * aspect;
    float w1 = exp(-dot(d1, d1) * 4.5);
    float w2 = exp(-dot(d2, d2) * 4.0);
    float w3 = exp(-dot(d3, d3) * 7.0);

    float3 col = float3(c0.rgb);
    col = mix(col, float3(c1.rgb), w1);
    col = mix(col, float3(c2.rgb), w2);
    col = mix(col, float3(c3.rgb), w3);

    // One grain value per device pixel (not per point), so the texture stays fine on 2× and 3× screens.
    float n = mlHash(floor(position * max(pixelScale, 1.0))) - 0.5;
    col += n * grain * 0.16;
    col = clamp(col, float3(0.0), float3(1.0));
    return half4(half3(col), 1.0h) * color.a;
}

// MARK: - Glass lens (layer effect)
// A spherical glass cap: the core magnifies, the steep rim bends rays inward, and red/blue refract by
// different amounts toward the rim (dispersion), so edges pick up a thin chromatic fringe. A specular
// highlight from the top-left sells the curvature.

[[ stitchable ]]
half4 mlGlassLens(float2 position, SwiftUI::Layer layer, float2 center, float radius, float magnify, float dispersion) {
    half4 outside = layer.sample(position);
    float2 d = position - center;
    float dist = length(d);
    float rad = max(radius, 1.0);
    if (dist >= rad) {
        return outside;
    }
    float t = dist / rad;
    float z = sqrt(max(1.0 - t * t, 0.0));
    float2 dir = dist > 0.001 ? d / dist : float2(0.0);
    float core = dist * mix(1.0 - magnify, 1.0, t * t);
    float rim = (1.0 - z) * rad * 0.28;
    float spread = dispersion * (1.0 - z);
    half4 g = layer.sample(center + dir * (core - rim));
    half4 r = layer.sample(center + dir * (core - rim * (1.0 - spread)));
    half4 b = layer.sample(center + dir * (core - rim * (1.0 + spread)));
    half4 lens = half4(r.r, g.g, b.b, max(g.a, max(r.a, b.a)));
    float3 normal = normalize(float3(d / rad, z));
    float3 light = normalize(float3(-0.45, -0.6, 0.66));
    float spec = pow(max(dot(normal, light), 0.0), 36.0);
    float shade = 0.9 + 0.1 * z;
    lens.rgb = lens.rgb * half(shade) + half(spec * 0.75) * lens.a;
    lens = min(lens, half4(1.0h));
    lens.rgb = min(lens.rgb, half3(lens.a));
    float blend = smoothstep(rad - 1.2, rad, dist);
    return mix(lens, outside, half(blend));
}

// MARK: - Progressive blur (layer effect)
// A variable-radius disc blur: radius ramps from 0 to `maxRadius` along a vertical mask.
// mode 0 (edge): full blur above `focusY - fade`, sharp below `focusY`.
// mode 1 (tilt-shift): sharp within `band` of `focusY`, ramping to full blur `fade` beyond it.
// 32 golden-angle taps with a per-pixel rotation keep the kernel smooth instead of ghosted.

[[ stitchable ]]
half4 mlProgressiveBlur(float2 position, SwiftUI::Layer layer, float maxRadius, float focusY,
                        float band, float fade, float mode, float taps) {
    float d = mode < 0.5 ? (focusY - position.y) : (abs(position.y - focusY) - band);
    float amount = smoothstep(0.0, max(fade, 1.0), d);
    float radius = maxRadius * amount;
    if (radius < 0.5) {
        return layer.sample(position);
    }
    float jitter = mlHash(floor(position * 3.0)) * 6.2831853;
    // `taps` (1…32) trades quality for cost: small grid thumbnails use 16, the detail stage 32.
    int count = int(clamp(taps, 1.0, 32.0));
    float n = float(count);
    half4 acc = half4(0.0h);
    float total = 0.0;
    for (int i = 0; i < count; i++) {
        float fi = float(i) + 0.5;
        float rr = sqrt(fi / n) * radius;
        float th = fi * 2.3999632 + jitter;
        float w = 1.0 - 0.45 * (rr / radius);
        acc += layer.sample(position + float2(cos(th), sin(th)) * rr) * half(w);
        total += w;
    }
    return acc / half(total);
}

// MARK: - Caustics (layer effect)
// A pool floor seen through moving water. A sum-of-sines height field (plus an optional ripple ring from
// the last tap) refracts the floor via its gradient, and an iterative caustic network — sharpened
// with pow(·, 8) — adds dancing light, shifted by the same refraction.

static float mlWaterHeight(float2 p, float t, float2 origin, float age) {
    float h = sin(p.x * 0.045 + t * 1.3) * 0.5
            + sin(p.y * 0.052 - t * 1.1) * 0.5
            + sin((p.x + p.y) * 0.031 + t * 0.9) * 0.6
            + (mlNoise(p * 0.03 + float2(t * 0.35, -t * 0.2)) - 0.5) * 1.2;
    if (age >= 0.0 && age < 3.0) {
        float dist = length(p - origin);
        float front = age * 240.0;
        float envelope = exp(-abs(dist - front) / 34.0) * exp(-age * 1.6);
        h += sin((dist - front) * 0.11) * 3.2 * envelope;
    }
    return h;
}

static float mlCausticNetwork(float2 uv, float time) {
    // Deliberately not wrapped with fract(): the pattern never needs to tile, so there is no seam.
    float2 p = uv * 6.2831853 - 250.0;
    float2 i = p;
    float c = 1.0;
    float inten = 0.005;
    for (int n = 0; n < 5; n++) {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= 5.0;
    c = 1.17 - pow(c, 1.4);
    return pow(abs(c), 8.0);
}

[[ stitchable ]]
half4 mlCaustics(float2 position, SwiftUI::Layer layer, float time, float intensity, float refraction,
                 float2 origin, float age) {
    float e = 2.0;
    float h = mlWaterHeight(position, time, origin, age);
    float hx = mlWaterHeight(position + float2(e, 0.0), time, origin, age);
    float hy = mlWaterHeight(position + float2(0.0, e), time, origin, age);
    float2 grad = float2(hx - h, hy - h) / e;
    float2 offset = grad * refraction * 6.0;
    half4 floorColor = layer.sample(position + offset);
    float light = mlCausticNetwork((position + offset * 2.0) / 240.0, time * 0.5);
    float3 rgb = float3(floorColor.rgb) * float3(0.80, 0.93, 1.0);
    rgb += float3(0.80, 0.96, 1.0) * light * intensity * float(floorColor.a);
    rgb = min(rgb, float3(floorColor.a));
    return half4(half3(rgb), floorColor.a);
}

// MARK: - Jelly press (layer effect)
// A soft dome under the finger: strength > 0 pulls samples toward the center (bulge), strength < 0 pushes
// them out (dent), so a spring that overshoots through zero reads as a wobbling jelly. `stretch` smears the
// dome's content opposite to the drag velocity. The falloff (1 − t²)² has zero slope at the rim, so no seam.
// Max displacement ≈ 0.29 · radius · |strength| + |stretch|.

[[ stitchable ]]
half4 mlJellyPress(float2 position, SwiftUI::Layer layer, float2 center, float radius, float strength, float2 stretch) {
    float rad = max(radius, 1.0);
    float2 d = position - center;
    float dist = length(d);
    if (dist >= rad) {
        return layer.sample(position);
    }
    float t = dist / rad;
    float fall = (1.0 - t * t) * (1.0 - t * t);
    // + stretch: content lags behind the drag (shifts against the velocity), like a viscous gel.
    float2 p = position - d * strength * fall + stretch * fall;
    half4 c = layer.sample(p);
    float2 dir = dist > 0.001 ? d / dist : float2(0.0);
    float slope = strength * 4.0 * t * (1.0 - t * t);
    float light = clamp(1.0 + 0.35 * slope * dot(dir, float2(-0.6, -0.8)), 0.6, 1.4);
    c.rgb = min(c.rgb * half(light), half3(c.a));
    return c;
}

// MARK: - Liquid wipe (layer effect, applied to the outgoing scene)
// A wavy liquid surface rises from the bottom; below it the outgoing scene is transparent (the incoming scene
// sits underneath), just above it the content is pulled toward the surface like a meniscus, and a bright rim
// traces the waterline. Wave height follows sin(π · progress), so the surface starts and ends flat.
// Samples move up to `amplitude` points vertically.

[[ stitchable ]]
half4 mlLiquidWipe(float2 position, SwiftUI::Layer layer, float2 size, float progress, float amplitude, float time) {
    float pr = clamp(progress, 0.0, 1.0);
    float a = amplitude * sin(3.14159265 * pr);
    float span = size.y + amplitude * 4.0;
    float level = size.y + amplitude * 2.0 - pr * span;
    float wave = sin(position.x * 0.034 + time * 4.2) * a
               + sin(position.x * 0.079 - time * 2.7) * a * 0.45;
    float d = position.y - (level + wave);
    float above = max(-d, 0.0);
    float lens = exp(-above / 16.0);
    float2 p = position - float2(0.0, lens * a * 0.9);
    half4 c = layer.sample(p);
    float keep = 1.0 - smoothstep(-0.8, 0.8, d);
    c *= half(keep);
    float mask = float(layer.sample(position).a);
    float live = smoothstep(0.0, 0.08, pr) * (1.0 - smoothstep(0.92, 1.0, pr));
    float rim = exp(-abs(d) / 2.2) * mask * live;
    c += half4(half3(half(rim * 0.9)), half(rim * 0.9));
    c = min(c, half4(1.0h));
    c.rgb = min(c.rgb, half3(c.a));
    return c;
}

// MARK: - Tile scatter (layer effect)
// The view is cut into square tiles. A wave front leaves `origin`; each tile starts when it arrives
// (delay ∝ distance · spread), flashes briefly, then shrinks to nothing while turning by a random angle.
// Rotation grows with e², so a turning tile never pokes outside its own cell. Samples stay inside the cell.

[[ stitchable ]]
half4 mlTileScatter(float2 position, SwiftUI::Layer layer, float2 size, float2 origin, float progress,
                    float tile, float spread) {
    float s = max(tile, 4.0);
    float2 cell = floor(position / s);
    float2 center = (cell + 0.5) * s;
    float reach = max(length(size), 1.0);
    float delay = length(center - origin) / reach * spread;
    float local = clamp(progress * (1.0 + spread) - delay, 0.0, 1.0);
    float e = local * local * (3.0 - 2.0 * local);
    float scale = 1.0 - e;
    if (scale <= 0.002) {
        return half4(0.0h);
    }
    float spin = (mlHash(cell + 7.1) - 0.5) * 2.4 * e * e;
    float cs = cos(spin);
    float sn = sin(spin);
    float2 lp = position - center;
    float2 q = float2(cs * lp.x + sn * lp.y, -sn * lp.x + cs * lp.y) / scale;
    float hs = s * 0.5;
    if (abs(q.x) > hs || abs(q.y) > hs) {
        return half4(0.0h);
    }
    half4 c = layer.sample(center + q);
    float flash = smoothstep(0.0, 0.15, e) * (1.0 - smoothstep(0.15, 0.6, e));
    c.rgb = min(c.rgb + half3(half(flash * 0.35)) * c.a, half3(c.a));
    c *= half(1.0 - e * e);
    return c;
}

// MARK: - Reeded glass (layer effect)
// A vertical panel of fluted glass centered at `panelX`. Each rib of width `rib` acts as a cylindrical lens:
// the sample shifts by u · rib · strength (u ∈ −0.5…0.5 across the rib), so every flute shows a squeezed,
// mirrored slice. A 5-tap vertical smear (`frost`) softens it; rib shading, a specular line per flute and a
// bright bevel at both panel edges sell the material. Samples move ≤ rib · strength / 2 horizontally, 4 · frost vertically.

[[ stitchable ]]
half4 mlReededGlass(float2 position, SwiftUI::Layer layer, float panelX, float panelWidth, float rib,
                    float strength, float frost) {
    float left = panelX - panelWidth * 0.5;
    float local = position.x - left;
    if (local < 0.0 || local > panelWidth) {
        return layer.sample(position);
    }
    float w = max(rib, 2.0);
    float u = fract(local / w) - 0.5;
    float2 p = position + float2(u * w * strength, 0.0);
    float f = max(frost, 0.0);
    half4 c = layer.sample(p) * 0.36h
            + layer.sample(p + float2(0.0, 2.0 * f)) * 0.2h
            + layer.sample(p - float2(0.0, 2.0 * f)) * 0.2h
            + layer.sample(p + float2(0.0, 4.0 * f)) * 0.12h
            + layer.sample(p - float2(0.0, 4.0 * f)) * 0.12h;
    float shade = 0.9 + 0.1 * cos(u * 6.2831853);
    float su = u + 0.28;
    float spec = exp(-(su * su) / 0.004) * 0.32;
    float edge = min(local, panelWidth - local);
    spec += exp(-edge / 1.2) * 0.45;
    c.rgb = c.rgb * half(shade) + half(spec) * c.a;
    c.rgb += half3(0.03h, 0.035h, 0.05h) * c.a;
    c = min(c, half4(1.0h));
    c.rgb = min(c.rgb, half3(c.a));
    return c;
}

// MARK: - Ordered dither (layer effect)
// Pixelates to `pixel`-point cells, then quantizes each cell's luminance to `levels` tones with a 4×4 Bayer
// threshold matrix and maps the result onto a two-color ramp (dark → light), like 1-bit / Game Boy screens.

[[ stitchable ]]
half4 mlDither(float2 position, SwiftUI::Layer layer, float pixel, float levels, half4 dark, half4 light) {
    float s = max(pixel, 1.0);
    float2 cell = max(floor(position / s), float2(0.0));
    half4 c = layer.sample((cell + 0.5) * s);
    if (c.a < 0.01h) {
        return half4(0.0h);
    }
    float3 rgb = float3(c.rgb) / float(c.a);
    float l = dot(rgb, float3(0.299, 0.587, 0.114));
    uint x = uint(cell.x) & 3u;
    uint y = uint(cell.y) & 3u;
    uint x0 = x & 1u;
    uint y0 = y & 1u;
    uint x1 = (x >> 1u) & 1u;
    uint y1 = (y >> 1u) & 1u;
    uint bayer = 4u * (((x0 ^ y0) << 1u) | y0) + (((x1 ^ y1) << 1u) | y1);
    float threshold = (float(bayer) + 0.5) / 16.0;
    float n = max(floor(levels), 2.0) - 1.0;
    float q = clamp(floor(l * n + threshold) / n, 0.0, 1.0);
    float3 col = mix(float3(dark.rgb), float3(light.rgb), q);
    return half4(half3(col), 1.0h) * c.a;
}

// MARK: - VHS tape (layer effect)
// Per-scanline horizontal wobble from animated value noise, a noisy tracking band rolling down the frame,
// head-switching noise in the bottom 14 pt, chroma delayed to the right while luma stays sharp, tape snow in
// the band and soft scanlines. Horizontal sample offsets stay below wobble/2 + 20·tracking + 12 + 2·chroma.

[[ stitchable ]]
half4 mlVHS(float2 position, SwiftUI::Layer layer, float2 size, float time, float tracking, float wobble, float chroma) {
    float y = position.y;
    float dx = (mlNoise(float2(y * 0.35, time * 18.0)) - 0.5) * wobble;
    float bandY = fract(time * 0.13) * (size.y + 80.0) - 40.0;
    float bw = 10.0 + 30.0 * tracking;
    float bd = (y - bandY) / bw;
    float inBand = exp(-bd * bd);
    float tear = mlHash(float2(floor(y * 0.5), floor(fract(time) * 30.0))) - 0.5;
    dx += inBand * tracking * tear * 40.0;
    float head = smoothstep(size.y - 14.0, size.y, y);
    dx += head * 12.0 * sin(y * 0.9 + time * 40.0);
    float2 p = position + float2(dx, 0.0);
    half4 base = layer.sample(p);
    half4 cr = layer.sample(p + float2(chroma, 0.0));
    half4 cb = layer.sample(p + float2(chroma * 2.0, 0.0));
    float3 weights = float3(0.299, 0.587, 0.114);
    float luma = dot(float3(base.rgb), weights);
    float3 shifted = float3(float(cr.r), float(base.g), float(cb.b));
    float3 col = shifted + (luma - dot(shifted, weights));
    float2 snowSeed = position * 0.7 + float2(fract(time * 7.3) * 100.0, fract(time * 3.1) * 100.0);
    float snow = mlHash(snowSeed);
    col = mix(col, float3(snow), inBand * tracking * 0.55 * float(base.a));
    col *= 0.94 + 0.06 * sin(y * 3.14159);
    col = clamp(col, float3(0.0), float3(float(base.a)));
    return half4(half3(col), base.a);
}

// MARK: - Voronoi cells (color effect, generative)
// Animated Worley cells: each feature point wobbles inside its grid cell, borders (F2 − F1 ≈ 0) glow, and each
// cell takes a hashed color. A tap sends a ring (320 pt/s, fading over ~2 s) that shoves the cells outward and
// brightens them as it passes. `pulse` < 0 means no ring.

[[ stitchable ]]
half4 mlVoronoiCells(float2 position, half4 color, float2 size, float time, float density, float2 touch,
                     float pulse, float glow) {
    float2 fromTouch = position - touch;
    float dist = length(fromTouch);
    float ring = 0.0;
    if (pulse >= 0.0) {
        float rd = (dist - pulse * 320.0) / 26.0;
        ring = exp(-rd * rd) * exp(-pulse * 1.6);
    }
    float2 uv = position / max(size.y, 1.0) * density;
    uv += (dist > 0.5 ? fromTouch / dist : float2(0.0)) * ring * 0.25;
    float2 g = floor(uv);
    float2 f = fract(uv);
    float d1 = 8.0;
    float d2 = 8.0;
    float2 best = g;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 o = float2(float(i), float(j));
            float2 h = float2(mlHash(g + o), mlHash(g + o + 17.31));
            float2 pt = o + 0.5 + 0.38 * sin(time * (0.6 + h * 0.9) + 6.2831853 * h);
            float d = length(pt - f);
            if (d < d1) {
                d2 = d1;
                d1 = d;
                best = g + o;
            } else if (d < d2) {
                d2 = d;
            }
        }
    }
    float edge = d2 - d1;
    float tone = mlHash(best * 1.37 + 3.1);
    float3 base = mix(float3(0.10, 0.08, 0.28), float3(0.20, 0.55, 0.95), tone);
    base = mix(base, float3(1.0, 0.45, 0.65), smoothstep(0.72, 1.0, tone));
    float border = exp(-edge * 18.0) * glow;
    float core = (1.0 - smoothstep(0.0, 0.5, d1)) * 0.35;
    float3 col = base * (0.55 + core);
    col += float3(0.55, 0.85, 1.0) * border * (0.55 + ring * 2.0);
    col += base * ring * 0.8;
    col = clamp(col, float3(0.0), float3(1.0));
    return half4(half3(col), 1.0h) * color.a;
}

// MARK: - Hyperspace tunnel (color effect, generative)
// Polar-coordinate tunnel: depth z = 0.28 / r + time scrolls toward the viewer, the angle is twisted by depth,
// and a grid of `lanes` longitudinal lines × rings is drawn on the wall with a cosine hue ramp along z.
// The far end fades into a white-violet core so the dense center never aliases.

[[ stitchable ]]
half4 mlTunnel(float2 position, half4 color, float2 size, float time, float2 center, float twist, float lanes) {
    float2 d = (position - center) / max(size.y, 1.0);
    float r = max(length(d), 0.0001);
    float a = atan2(d.y, d.x) / 6.2831853;
    float z = 0.28 / r + time;
    float u = a + twist * 0.05 * z;
    float n = max(floor(lanes), 3.0);
    float gu = fract(u * n);
    float gz = fract(z * 1.5);
    float lu = 1.0 - smoothstep(0.0, 0.07, min(gu, 1.0 - gu));
    float lz = 1.0 - smoothstep(0.0, 0.07, min(gz, 1.0 - gz));
    float line = max(lu, lz);
    float3 hue = 0.5 + 0.5 * cos(6.2831853 * (z * 0.06 + float3(0.0, 0.33, 0.67)));
    float fog = smoothstep(0.015, 0.22, r);
    float3 col = float3(0.02, 0.015, 0.06);
    col += hue * line * fog * 1.1;
    col += hue * 0.12 * fog;
    col += float3(0.9, 0.85, 1.0) * exp(-r * 9.0) * 0.9;
    col = clamp(col, float3(0.0), float3(1.0));
    return half4(half3(col), 1.0h) * color.a;
}
