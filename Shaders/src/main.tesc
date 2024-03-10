#version 450

layout(vertices=3) out;

layout(binding = 2) uniform CameraPosition {
    vec3 position;
} camera;

layout(location = 0) out vec2 TextureCoords[3];

void main() {
    float dist = length(camera.position - gl_in[gl_InvocationID].gl_Position.xyz);

    float val = 32.0;

    if (dist > 500000) {
        val = 1.0;
    } else if (dist > 250000) {
        val = 8.0;
    }

    gl_TessLevelOuter[0] = val;
    gl_TessLevelOuter[1] = val;
    gl_TessLevelOuter[2] = val;

    gl_TessLevelInner[0] = val;
    gl_TessLevelInner[1] = val;

    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    TextureCoords[gl_InvocationID] = vec2(0, 0);
}