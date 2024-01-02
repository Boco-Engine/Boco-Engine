package boco_renderer

import vk "vendor:vulkan"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Mat4 :: matrix[4, 4]f32

PushConstant :: struct {
    mvp: Mat4,
}

BufferResources :: struct {
    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    data_ptr: rawptr
}

IndexedMesh :: struct {
    // Data
    vertices: []Vec3,
    indicies: []u32,
    normals: []Vec3,

    // Resources
    vertex_buffer: BufferResources,
    index_buffer: BufferResources,

}