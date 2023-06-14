
#version 460 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aCol;

uniform vec2 resolution;
uniform float time;

out vec3 vCol;
out vec2 iResolution;
out float iTime;

void main() {
    vCol = aCol;
    iResolution = resolution;
    iTime = time;

    gl_Position = vec4(aPos, 1.0);
}