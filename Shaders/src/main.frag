#version 450

layout(location = 0) in vec3 in_position;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec3 in_texc;

layout(binding = 1) uniform sampler2D texSampler;

layout(location = 0) out vec4 outColour;

vec3 lightpos = vec3(-2000000, 0000000, 1000000);
vec3 light_colour = vec3(0.9, 0.4, 0.01);

void main() {
    vec3 lightdir = normalize(lightpos - in_position);
    float r = dot(in_normal, lightdir);
    outColour = vec4(in_normal, 1.0);
    // This is just cause my planets dont currenly create texture coordinates so just setting to values on a circle
    float u = 0.5 + (in_texc.x / (2.0f * 200000));
    float v = 0.5 + (in_texc.y / (2.0f * 200000));

    vec3 ambient = 0.2 * light_colour;

    float diff = max(dot(in_normal, lightdir), 0.0);
    vec3 diffuse = diff * light_colour;

    // outColour = texture(texSampler, vec2(u, v)) * vec4(ambient + diffuse, 1.0);
    outColour = vec4((in_normal * 0.5) + 1.0, 1.0) * vec4(ambient + diffuse, 1.0);
}