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

// MARK: - Wave (distortion effect)

[[ stitchable ]]
float2 mlWave(float2 position, float time, float amplitude, float wavelength, float speed) {
    float2 p = position;
    p.y += sin(time * speed + position.x / wavelength) * amplitude;
    p.x += cos(time * speed * 0.8 + position.y / wavelength) * amplitude * 0.5;
    return p;
}

// MARK: - Pixelate (layer effect)

[[ stitchable ]]
half4 mlPixelate(float2 position, SwiftUI::Layer layer, float size) {
    float s = max(size, 1.0);
    float2 cell = floor(position / s) * s + s * 0.5;
    return layer.sample(cell);
}

// MARK: - Glitch (layer effect)
// `split` is the resting R/B offset in points, `sliceHeight` the band height, `rate` how often bands re-roll per second.

[[ stitchable ]]
half4 mlGlitch(float2 position, SwiftUI::Layer layer, float time, float intensity,
               float split, float sliceHeight, float rate) {
    float band = floor(position.y / max(sliceHeight, 2.0));
    float r = max(rate, 0.5);
    float frame = floor(time * r * 2.0);
    float jitter = (mlHash(float2(band, frame)) - 0.5) * 2.0;
    float active = step(0.78, mlHash(float2(floor(time * r), band * 0.37)));
    float shift = jitter * intensity * 26.0 * active;
    float offset = split * (0.35 + intensity * 1.3);
    float2 p = position + float2(shift, 0.0);
    half4 base = layer.sample(p);
    half4 red = layer.sample(p + float2(offset, 0.0));
    half4 blue = layer.sample(p - float2(offset, 0.0));
    half4 color = half4(red.r, base.g, blue.b, max(base.a, max(red.a, blue.a)));
    float scan = 0.93 + 0.07 * sin(position.y * 3.14159);
    color.rgb *= half(scan);
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

[[ stitchable ]]
half4 mlPlasma(float2 position, half4 color, float2 size, float time, float scale) {
    float2 uv = position / max(size, float2(1.0));
    float v = sin(uv.x * 6.0 * scale + time)
            + sin(uv.y * 7.0 * scale - time * 1.3)
            + sin((uv.x + uv.y) * 5.0 * scale + time * 0.7)
            + sin(length(uv - 0.5) * 12.0 * scale - time * 2.0);
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
// Same displacement as mlWave, plus fold lighting from the wave's slope: crests catch light, troughs shade.

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
    float r = length(d) * zoom;
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
                        float band, float fade, float mode) {
    float d = mode < 0.5 ? (focusY - position.y) : (abs(position.y - focusY) - band);
    float amount = smoothstep(0.0, max(fade, 1.0), d);
    float radius = maxRadius * amount;
    if (radius < 0.5) {
        return layer.sample(position);
    }
    float jitter = mlHash(floor(position * 3.0)) * 6.2831853;
    half4 acc = half4(0.0h);
    float total = 0.0;
    for (int i = 0; i < 32; i++) {
        float fi = float(i) + 0.5;
        float rr = sqrt(fi / 32.0) * radius;
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
