#version 460 core

in vec3 vCol;
in vec2 iResolution;
in float iTime;

out vec4 FragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution.xy * 2.0 - 1.0;
    uv.x *= (iResolution.x / iResolution.y);

    float R = 0.25;
    float d = step(0.0, R - length(uv));
    float t = abs(sin(iTime) * 0.5) + 0.5;
    FragColor = vec4(vCol * t, d);
}