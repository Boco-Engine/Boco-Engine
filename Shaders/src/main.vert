#version 450

layout(location = 0) out vec3 outColour;
layout(location = 1) out vec3 outPos;

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texture_coord;

layout(push_constant) uniform constants {
    mat4 mvp;
    mat4 m;
} PushConstant;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    gl_Position = vec4(vec3(position), 1.0f) * PushConstant.mvp;
    outColour = normal;
    outPos = (normalize(gl_Position.xyz));
}