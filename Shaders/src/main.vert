#version 450

layout(location = 0) out vec3 outColour;
layout(location = 1) out vec3 outPos;

layout(location = 0) in vec3 position;
layout(location = 2) in vec3 normal;
layout(location = 3) in vec2 texture_coord;

layout(push_constant) uniform constants {
    mat4 mvp;
    mat4 m;
} PushConstant;

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

void main() {
    // TODO: Make all inputs/outputs floats and convert 64 input to local coordinates
    gl_Position = vec4(position, 1.0f) * PushConstant.mvp;
    outColour = normal;
    outPos = position;
}