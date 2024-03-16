#version 450

layout(location = 2) in vec2 in_position;
layout(location = 3) in vec2 in_texture_coord;

layout(binding = 1) uniform sampler2D texSampler;

layout(location = 0) out vec4 outColour;

void main() {
    //vec4 c = texture(texSampler, in_texture_coord);
    //if (c.r == 0) {
    //    c = vec4(0, 0, 0, 0);
    //    discard;
    //}
    //outColour = c;
    // outColour = vec4(1.0, 1.0, 0.0, 1.0);
}