package renderer

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

UniformBufferObject :: struct {
    model: Mat4,
    view: Mat4,
    proj: Mat4,
}

CameraBufferObject :: struct {
    camera_position: Vec3,
}

BufferResources :: struct {
    length: u32,
    capacity: u32,

    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    data_ptr: rawptr
}

Vertex :: struct {
	position: [3]f32,
	normal: [3]f32,
	texture_coords: [2]f32
}

UIVertex :: struct {
    position: [2]f32,
    texture_coord: [2]f32
}

IndexedMesh :: struct {
    // Data
    // TODO: Remove These from here, these dont need to be stored once they are copied to the buffers.
    push_constant: PushConstant,
    vertex_data: []Vertex,
    index_data: []u32,

    // Resources
    // DESIGN: Buffer resources. We want to be able to allocate one buffer for several things so need some way to keep track of buffer, offset, and size.
    vertex_buffer_resource: BufferResources,
    index_buffer_resource: BufferResources,
}

UIMesh :: struct {
    vertex_data: []UIVertex,
    index_data: []u32,

    vertex_buffer_resource: BufferResources,
    index_buffer_resource: BufferResources,
}

Texture :: struct {
    width: i32,
    height: i32,
    channels: i32,

    image: vk.Image,
    image_view: vk.ImageView,
    sampler: vk.Sampler,
    memory: vk.DeviceMemory
}