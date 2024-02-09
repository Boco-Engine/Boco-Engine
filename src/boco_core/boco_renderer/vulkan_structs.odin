package boco_renderer

import vk "vendor:vulkan"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Mat4 :: matrix[4, 4]f32
MeshID :: u32

PushConstant :: struct {
    mvp: Mat4,
    m: Mat4,
}

BufferResources :: struct {
    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    data_ptr: rawptr
}

Vertex :: struct {
	position: Vec3,
	normal: Vec3,
	texture_coords: Vec2
}

IndexedMesh :: struct {
    // Data
    // TODO: Texture Data
    push_constant: PushConstant,
    vertex_data: []Vertex,
    index_data: []u32,

    // Resources
    // TODO: Offset and size of buffer resource to allow preallocating large buffers.
    vertex_buffer_resource: BufferResources,
    index_buffer_resource: BufferResources,
}

Texture :: struct {
    image_data: [^]u8,
    width: i32,
    height: i32,
    channels: i32,

    image: vk.Image,
    memory: vk.DeviceMemory
}