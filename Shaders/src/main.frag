#version 450


layout(location = 0) in vec3 inColour;
layout(location = 1) in vec3 inPos;
layout(location = 0) out vec4 outColour;

vec3 lightpos = vec3(0, 0, -10000);

void main() {
    vec3 lightdir = normalize(lightpos - inPos);
    outColour = max(dot(inColour, lightdir), 0.0) * vec4(0.61, 0.46, 0.33, 1);
    outColour = vec4(inColour, 1.0);
}