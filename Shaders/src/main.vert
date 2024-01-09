#version 450

layout(location = 0) out vec3 outColour;

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 texture_coord;

layout(push_constant) uniform constants {
    mat4 mvp;
} PushConstant;

void main() {
    gl_Position = vec4(position, 1.0) * PushConstant.mvp;
    outColour = normal;
}