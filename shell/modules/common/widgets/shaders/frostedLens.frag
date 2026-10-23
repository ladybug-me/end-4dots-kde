#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    vec4 radii;
    vec4 wash;
    float qt_Opacity;
    vec2 size;
    float rimWidth;
    float pull;
    float split;
    float haze;
    float vividness;
    float sheen;
};

layout(binding = 1) uniform sampler2D backdrop;

float roundedDist(vec2 p, vec2 half_, vec4 radii) {
    float r = p.x > 0.0 ? (p.y > 0.0 ? radii.z : radii.y) : (p.y > 0.0 ? radii.w : radii.x);
    r = min(r, min(half_.x, half_.y));
    vec2 q = abs(p) - half_ + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

vec3 softSample(vec2 px, float lod) {
    vec2 uv = clamp((px + size * 0.5) / size, vec2(0.002), vec2(0.998));
    return textureLod(backdrop, uv, lod).rgb;
}

vec3 hazeSample(vec2 px, float lod, float reach) {
    vec3 sum = softSample(px, lod) * 2.0;
    for (int i = 0; i < 6; ++i) {
        float a = 1.0471976 * float(i) + 0.3;
        sum += softSample(px + vec2(cos(a), sin(a)) * reach, lod);
    }
    return sum / 8.0;
}

void main() {
    vec2 p = qt_TexCoord0 * size - size * 0.5;
    float d = roundedDist(p, size * 0.5, radii);
    float cover = clamp(0.5 - d, 0.0, 1.0);
    if (cover <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float depth = max(-d, 0.0);
    vec2 e = vec2(0.8, 0.0);
    vec2 n = vec2(
        roundedDist(p + e.xy, size * 0.5, radii) - roundedDist(p - e.xy, size * 0.5, radii),
        roundedDist(p + e.yx, size * 0.5, radii) - roundedDist(p - e.yx, size * 0.5, radii));
    n = length(n) > 1e-4 ? normalize(n) : vec2(0.0, -1.0);

    float k = clamp(1.0 - depth / rimWidth, 0.0, 1.0);
    float bend = k * k * (1.6 - 0.6 * k);
    vec2 shift = -n * bend * pull;

    float lod = log2(max(haze, 1.0));
    float reach = haze * 0.6;
    vec3 col;
    col.r = hazeSample(p + shift * (1.0 + split), lod, reach).r;
    col.g = hazeSample(p + shift, lod, reach).g;
    col.b = hazeSample(p + shift * (1.0 - split), lod, reach).b;

    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, vividness);

    vec2 L = normalize(vec2(-0.6, -0.8));
    float facing = dot(n, L);
    float lit = pow(max(facing, 0.0), 2.0);
    float back = pow(max(-facing, 0.0), 2.5);

    float hairline = exp(-depth / 0.9);
    float soft = exp(-depth / (rimWidth * 0.55));
    float glint = (hairline * (0.22 + 0.7 * lit) + soft * 0.16 * lit + hairline * 0.12 * back) * sheen;

    col *= 1.0 - 0.12 * soft * back;

    float top = 1.0 - smoothstep(0.0, size.y * 0.55, p.y + size.y * 0.5);
    col += vec3(0.035 * top * sheen);

    col = mix(col, wash.rgb, wash.a);
    col += vec3(glint);

    fragColor = vec4(clamp(col, 0.0, 1.0) * cover, cover) * qt_Opacity;
}
