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

[[ stitchable ]]
half4 mlGlitch(float2 position, SwiftUI::Layer layer, float time, float intensity) {
    float band = floor(position.y / 14.0);
    float frame = floor(time * 12.0);
    float jitter = (mlHash(float2(band, frame)) - 0.5) * 2.0;
    float active = step(0.78, mlHash(float2(floor(time * 6.0), band * 0.37)));
    float shift = jitter * intensity * 26.0 * active;
    float split = intensity * 6.0;
    float2 p = position + float2(shift, 0.0);
    half4 base = layer.sample(p);
    half4 red = layer.sample(p + float2(split, 0.0));
    half4 blue = layer.sample(p - float2(split, 0.0));
    half4 color = half4(red.r, base.g, blue.b, max(base.a, max(red.a, blue.a)));
    float scan = 0.93 + 0.07 * sin(position.y * 3.14159);
    color.rgb *= half(scan);
    return color;
}

// MARK: - Noise dissolve (color effect)

[[ stitchable ]]
half4 mlDissolve(float2 position, half4 color, float progress, float scale, half4 edgeColor) {
    float n = mlFbm(position / max(scale, 1.0));
    float threshold = progress * 1.15 - 0.075;
    if (n < threshold) {
        return half4(0.0);
    }
    float edge = smoothstep(threshold, threshold + 0.07, n);
    half4 glow = half4(edgeColor.rgb, 1.0) * color.a;
    return mix(glow, color, half(edge));
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

[[ stitchable ]]
half4 mlPlasma(float2 position, half4 color, float2 size, float time, float scale) {
    float2 uv = position / max(size, float2(1.0));
    float v = sin(uv.x * 6.0 * scale + time)
            + sin(uv.y * 7.0 * scale - time * 1.3)
            + sin((uv.x + uv.y) * 5.0 * scale + time * 0.7)
            + sin(length(uv - 0.5) * 12.0 * scale - time * 2.0);
    v *= 0.25;
    float3 col = 0.55 + 0.45 * cos(6.28318 * (v + float3(0.0, 0.33, 0.67)) + time * 0.2);
    return half4(half3(col), 1.0) * color.a;
}

// MARK: - CRT (layer effect)

[[ stitchable ]]
half4 mlCRT(float2 position, SwiftUI::Layer layer, float2 size, float time, float curvature) {
    float2 uv = position / max(size, float2(1.0)) * 2.0 - 1.0;
    float2 bend = uv.yx * uv.yx * curvature;
    uv = uv + uv * bend;
    if (abs(uv.x) > 1.0 || abs(uv.y) > 1.0) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }
    float2 p = (uv * 0.5 + 0.5) * size;
    half4 base = layer.sample(p);
    half r = layer.sample(p + float2(1.2, 0.0)).r;
    half b = layer.sample(p - float2(1.2, 0.0)).b;
    half4 c = half4(r, base.g, b, base.a);
    float scan = 0.82 + 0.18 * sin(p.y * 2.4 + time * 10.0);
    float roll = 0.96 + 0.04 * sin((p.y / size.y - time * 0.35) * 6.28318);
    float vignette = 1.0 - 0.28 * dot(uv, uv);
    c.rgb *= half(scan * roll * vignette);
    return c;
}

// MARK: - Halftone (layer effect)

[[ stitchable ]]
half4 mlHalftone(float2 position, SwiftUI::Layer layer, float cell) {
    float s = max(cell, 2.0);
    float2 center = (floor(position / s) + 0.5) * s;
    half4 c = layer.sample(center);
    if (c.a < 0.01) {
        return half4(0.0);
    }
    float3 rgb = float3(c.rgb) / float(c.a);
    float lum = dot(rgb, float3(0.299, 0.587, 0.114));
    float radius = s * 0.5 * (1.05 - lum * 0.55);
    float d = length(position - center);
    float coverage = 1.0 - smoothstep(radius - 0.8, radius + 0.8, d);
    return c * half(coverage);
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
// Folds the polar angle into mirrored wedges; `spin` turns the sampled wedge (the "tube"), `rotation` the output.

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
// Three soft colour fields drift over a base colour on domain-warped coordinates, finished with static film grain.

[[ stitchable ]]
half4 mlGrainGradient(float2 position, half4 color, float2 size, float time, float grain,
                      half4 c0, half4 c1, half4 c2, half4 c3, float2 focus) {
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

    float n = mlHash(floor(position)) - 0.5;
    col += n * grain * 0.16;
    col = clamp(col, float3(0.0), float3(1.0));
    return half4(half3(col), 1.0h) * color.a;
}
