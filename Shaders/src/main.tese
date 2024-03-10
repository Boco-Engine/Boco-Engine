#version 450

layout(triangles, equal_spacing, cw) in;

layout(location = 0) in vec2 TextureCoords[];

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

vec4 interpolate(in vec4 v0, in vec4 v1, in vec4 v2) {
    return gl_TessCoord.x * v0 + gl_TessCoord.y * v1 + gl_TessCoord.z * v2;
}

void main() {
    gl_Position = interpolate(
        gl_in[0].gl_Position,
        gl_in[1].gl_Position,
        gl_in[2].gl_Position
    );
}