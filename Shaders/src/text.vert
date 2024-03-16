#version 450

layout(location = 2) out vec2 out_position;
layout(location = 3) out vec2 out_texture_coord;

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texture_coord;


void main() {
    gl_Position = vec4((position / 400.0f), 0.0, 1.0f);

    out_position = position;
    out_texture_coord = texture_coord;
}