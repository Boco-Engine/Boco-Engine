package renderer

import "core:os"
import "core:strings"
import "core:log"
import "core:path/filepath"
import "core:strconv"
import "core:mem"
import "core:math/linalg/glsl"

import stbi "vendor:stb/image"
import vk "vendor:vulkan"

import "boco:core/assets"

// All textures loading in rgba channels even if image doesnt have all.
// TODO: Create texture map of all loaded textures so were not loading already exisiting one, and return handle rather than the texture.
load_texture :: proc(renderer: ^Renderer, file: string) -> Texture {
    file_path := make_file_path("local_tests/planet_loading/Assets/Textures/", file)

    image_width: i32
    image_height: i32
    image_channels: i32
    image := stbi.load(strings.unsafe_string_to_cstring(file_path), &image_width, &image_height, &image_channels, 4)
    image_channels = 4
    
    staging_buffer: BufferResources
    buffer_allocate(renderer, size_of(u8) * cast(u64)(image_width * image_height * image_channels), {.TRANSFER_SRC}, &staging_buffer)
    buffer_write(renderer, &staging_buffer, image[:image_width * image_height * image_channels], 0)

    texture: Texture
    texture.width = image_width
    texture.height = image_height
    texture.channels = image_channels

    stbi.image_free(image)

    ok : vk.Result
    texture.image, ok = image_create(
        renderer, 
        .R8G8B8A8_SRGB,
        vk.Extent3D {
            width = auto_cast texture.width,
            height = auto_cast texture.height,
            depth = 1,
        },
        renderer.sample_count,
        {.TRANSFER_DST, .SAMPLED},
    )

    assert(ok == .SUCCESS, "Failed to create texture image.")

    // TODO: Extract this into a function.
    memory_requirements: vk.MemoryRequirements
    vk.GetImageMemoryRequirements(renderer.logical_device, texture.image, &memory_requirements)

    allocation_info: vk.MemoryAllocateInfo
    allocation_info.sType = .MEMORY_ALLOCATE_INFO
    allocation_info.allocationSize = memory_requirements.size
    allocation_info.memoryTypeIndex = get_memory_from_properties(renderer, {.DEVICE_LOCAL})

    vk.AllocateMemory(renderer.logical_device, &allocation_info, nil, &texture.memory)

    vk.BindImageMemory(renderer.logical_device, texture.image, texture.memory, 0)
    // TODO: Above

    // TODO: Copy Staging buffer to image!
    {
        cmd_buffer := SCOPED_COMMAND(renderer)

        TransitionImageLayout(cmd_buffer[0], texture, .UNDEFINED, .TRANSFER_DST_OPTIMAL)
    }
    
    // {
    //     cmd_buffer := SCOPED_COMMAND(renderer)

    //     copy_region : vk.BufferCopy
    //     copy_region.size = 0
    //     vk.CmdCopyBuffer(cmd_buffer, src, dst, 1, &copy_region)
    // }

    {
        cmd_buffer := SCOPED_COMMAND(renderer)

        region : vk.BufferImageCopy
        region.bufferOffset = 0
        region.bufferRowLength = 0
        region.bufferImageHeight = 0

        region.imageSubresource.aspectMask = {.COLOR}
        region.imageSubresource.mipLevel = 0
        region.imageSubresource.baseArrayLayer = 0
        region.imageSubresource.layerCount = 1

        region.imageOffset = {0, 0, 0}
        region.imageExtent = {
            cast(u32)texture.width,
            cast(u32)texture.height,
            1,
        }

        vk.CmdCopyBufferToImage(cmd_buffer[0], staging_buffer.buffer, texture.image, .TRANSFER_DST_OPTIMAL, 1, &region)
    }

    {
        cmd_buffer := SCOPED_COMMAND(renderer)

        TransitionImageLayout(cmd_buffer[0], texture, .TRANSFER_DST_OPTIMAL, .SHADER_READ_ONLY_OPTIMAL)
    }

    texture.image_view = imageview_create(renderer, texture.image, .R8G8B8A8_SRGB, {.COLOR})

    // TEXTURE SAMPLER
    sampler_info : vk.SamplerCreateInfo
    sampler_info.sType = .SAMPLER_CREATE_INFO
    sampler_info.magFilter = .LINEAR
    sampler_info.minFilter = .LINEAR
    sampler_info.addressModeU = .REPEAT
    sampler_info.addressModeV = .REPEAT
    sampler_info.addressModeW = .REPEAT
    sampler_info.anisotropyEnable = true

    props : vk.PhysicalDeviceProperties
    vk.GetPhysicalDeviceProperties(renderer.physical_device, &props)
    
    sampler_info.maxAnisotropy = props.limits.maxSamplerAnisotropy
    sampler_info.borderColor = .INT_OPAQUE_BLACK
    sampler_info.unnormalizedCoordinates = false
    sampler_info.compareEnable = false
    sampler_info.compareOp = .ALWAYS
    sampler_info.mipmapMode = .LINEAR
    sampler_info.mipLodBias = 0.0
    sampler_info.minLod = 0.0
    sampler_info.maxLod = 0.0

    vk.CreateSampler(renderer.logical_device, &sampler_info, nil, &texture.sampler)

    return texture
}

init_ui_element :: proc(renderer: ^Renderer, text: string) -> ^UIMesh {
    mesh := new(UIMesh)

    c := strings.count(text, " ")
    mesh.vertex_data = make([]UIVertex, (len(text) - c) * 4)
    mesh.index_data = make([]u32, (len(text) - c) * 6)

    current_x : f32 = -300
    current_y : f32 = 100

    spaces := 0

    for char, i in text {
        if (char == ' ') {
            current_x += 20
            spaces += 1
            continue
        }
        index := i - spaces

        info := renderer.font[char]

        height := cast(f32)(info.y1 - info.y0)
        width := cast(f32)(info.x1 - info.x0)

        // WANTED:
        // cast(i32)(a.x1 - a.x0), cast(i32)(a.y1 - a.y0), 1, cast(rawptr)&pixels[cast(i32)a.x0 + (size * cast(i32)a.y0)], size
        // X,                       Y,                     ,?, starting index,                                              stride

        mesh.vertex_data[(index * 4) + 0] = UIVertex{{current_x + info.xoff, current_y + info.yoff},                    {cast(f32)info.x0 / 576, cast(f32)info.y0 / 576}}
        mesh.vertex_data[(index * 4) + 1] = UIVertex{{current_x + width + info.xoff, current_y + height + info.yoff},   {(cast(f32)info.x0 + width) / 576, (cast(f32)info.y0 + height) / 576}}
        mesh.vertex_data[(index * 4) + 2] = UIVertex{{current_x + info.xoff, current_y + height + info.yoff},           {cast(f32)info.x0 / 576,( cast(f32)info.y0 + height) / 576}}
        mesh.vertex_data[(index * 4) + 3] = UIVertex{{current_x + width + info.xoff, current_y + info.yoff},            {(cast(f32)info.x0 + width) / 576, cast(f32)info.y0 / 576}}

        mesh.index_data[(index * 6) + 0] = cast(u32)(index * 4) + 0
        mesh.index_data[(index * 6) + 1] = cast(u32)(index * 4) + 1
        mesh.index_data[(index * 6) + 2] = cast(u32)(index * 4) + 2

        mesh.index_data[(index * 6) + 3] = cast(u32)(index * 4) + 0
        mesh.index_data[(index * 6) + 4] = cast(u32)(index * 4) + 3
        mesh.index_data[(index * 6) + 5] = cast(u32)(index * 4) + 1

        current_x += info.xadvance
    }

    // CREATE VERTEX BUFFER
    buffer_allocate(renderer, size_of(UIVertex) * auto_cast len(mesh.vertex_data), {.VERTEX_BUFFER}, &mesh.vertex_buffer_resource)
    buffer_write(renderer, &mesh.vertex_buffer_resource, mesh.vertex_data, 0)
    // CREATE INDEX BUFFER
    buffer_allocate(renderer, size_of(u32) * auto_cast len(mesh.index_data), {.INDEX_BUFFER}, &mesh.index_buffer_resource)
    buffer_write(renderer, &mesh.index_buffer_resource, mesh.index_data, 0)

    return mesh
}

init_mesh :: proc(renderer: ^Renderer, file: string) -> ^IndexedMesh {
    mesh : ^IndexedMesh
    mesh_err : bool
    ext := filepath.ext(file)
    if ext == ".bocom" {
        mesh = new(IndexedMesh)
        mesh^, mesh_err = read_bocom_mesh(file)
    } else if ext == ".bocobm" {
        mesh, mesh_err = read_bocobm_mesh(file)
    } else if ext == ".obj" {
        mesh, mesh_err = read_obj_mesh(file)
    }

    mesh.push_constant.m = matrix[4, 4]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }

    // CREATE VERTEX BUFFER
    buffer_allocate(renderer, size_of(Vertex) * auto_cast len(mesh.vertex_data), {.VERTEX_BUFFER}, &mesh.vertex_buffer_resource)
    buffer_write(renderer, &mesh.vertex_buffer_resource, mesh.vertex_data, 0)
    // CREATE INDEX BUFFER
    buffer_allocate(renderer, size_of(u32) * auto_cast len(mesh.index_data), {.INDEX_BUFFER}, &mesh.index_buffer_resource)
    buffer_write(renderer, &mesh.index_buffer_resource, mesh.index_data, 0)

    return mesh
}

make_file_path :: proc(folder : string, file : string) -> (path : string) {
    builder := strings.builder_make(0, len(folder) + len(file) + 1)
    defer(strings.builder_destroy(&builder))

    strings.write_string(&builder, folder)
    strings.write_string(&builder, "/")
    strings.write_string(&builder, file)

    // NOTE: Return a copy of the string from string builder as the builder is destroyed.
    return 	strings.clone(strings.to_string(builder))
}

read_spirv :: proc(file_name : string) -> (code : []u8, err : bool = true) {
    path : string = make_file_path("Shaders/compiled", file_name)

    file_contents, ok := os.read_entire_file(path, context.allocator)

    if (!ok) {
        log.error("Failed to read file:", file_name)
        return {}, false
    }
    log.info("Successfully read file:", file_name)

    return file_contents, err
}

read_mesh :: proc(file_name : string) -> (mesh : ^IndexedMesh, err: bool = false) {
    file_type := (strings.cut(file_name, strings.last_index(file_name, "."), 0))

    switch file_type {
        case ".obj":
            return read_obj_mesh(file_name)
        case:
            log.error("Unsupported file type being loaded.")
    }

    return {}, false
}

// NOTE: Pretty sure these are making copies to return which is very expensive for large meshes...
read_bocobm_mesh :: proc(file_name: string) -> (mesh: ^IndexedMesh, err: bool = false) {
    // log.info("Reading BOCOM: ", file_name)
    // TODO: More Robust way to find files
    // file_path := make_file_path("local_tests/planet_loading/Assets/Meshes", file_name)

    data_bytes, ok := assets.read_file(file_name)
    data := cast([]u8)data_bytes
    assert(ok, "Failed to read BOCOBM file")

    defer delete(data_bytes, context.allocator)

    mesh = new(IndexedMesh)

    info_bytes := 256
    info := make([]u8, info_bytes)
    mem.copy(cast(rawptr)(&info[0]), cast(rawptr)(&data[0]), info_bytes);

    byte_info := strings.split(string(info), " ")
    vertex_bytes := strconv.atoi(byte_info[0])
    index_bytes := strconv.atoi(byte_info[1])

    mesh.vertex_data = make([]Vertex, vertex_bytes / size_of(Vertex))
    mesh.index_data = make([]u32, index_bytes / size_of(u32))
    

    mem.copy(cast(rawptr)(&mesh.vertex_data[0]), cast(rawptr)(&data[info_bytes]), vertex_bytes)
    mem.copy(cast(rawptr)(&mesh.index_data[0]), cast(rawptr)(&data[vertex_bytes]), index_bytes)

    return mesh, true
}

read_bocom_mesh :: proc(file_name: string) -> (mesh: IndexedMesh, err: bool = false) {
    file_path := make_file_path("local_tests/planet_loading/Assets/Meshes", file_name)
    
    file_contents, ok := assets.read_file(file_path)
    assert(ok, "Failed to read BOCOM file")

    defer delete(file_contents, context.allocator)

    data := string(file_contents)

    vertex_count := 0
    index_count := 0

    processing := 0

    lines := strings.split_lines(data)
    index := 0
    for index = 0; index < len(lines); index += 1 {
        if lines[index][0] == '#' do continue

        if lines[index][0:2] == "v:" {
            vertex_count = strconv.atoi(lines[index][3:])
            index += 1;
            break;
        }
    }

    mesh.vertex_data = make([]Vertex, vertex_count)
    for vertex in 0..<vertex_count {
        parts := strings.split(lines[index], "/")
        position := parts[0]
        position_parts := strings.split(position, " ")

        mesh.vertex_data[vertex].position = {
            auto_cast strconv.atof(position_parts[0]),
            auto_cast strconv.atof(position_parts[1]),
            auto_cast strconv.atof(position_parts[2]),
        }

        normal := parts[1]
        normal_parts := strings.split(normal, " ")

        mesh.vertex_data[vertex].normal = {
            auto_cast strconv.atof(normal_parts[0]),
            auto_cast strconv.atof(normal_parts[1]),
            auto_cast strconv.atof(normal_parts[2]),
        }

        index += 1
    }

    for index = index; index < len(lines); index += 1 {
        if lines[index][0] == '#' do continue

        if lines[index][0:2] == "i:" {
            index_count = strconv.atoi(lines[index][3:])

            index += 1;
            break;
        }
    }

    mesh.index_data = make([]u32, index_count)
    for i in 0..<(index_count/3) {
        parts := strings.split(lines[index], " ")

        mesh.index_data[i * 3] = cast(u32)strconv.atoi(parts[0])
        mesh.index_data[i * 3 + 1] = cast(u32)strconv.atoi(parts[1])
        mesh.index_data[i * 3 + 2] = cast(u32)strconv.atoi(parts[2])

        // TEMP NORMALS CALC
        // tri1 := mesh.vertex_data[mesh.index_data[i * 3]]
        // tri2 := mesh.vertex_data[mesh.index_data[i * 3 + 1]]
        // tri3 := mesh.vertex_data[mesh.index_data[i * 3 + 2]]

        // A := tri2.position - tri1.position
        // B := tri3.position - tri1.position

        // normal := Vec3{
        //     A[1] * B[2] - A[2] * B[1],
        //     A[2] * B[0] - A[0] * B[2],
        //     A[0] * B[1] - A[1] * B[0],
        // }

        // normal = auto_cast glsl.normalize_vec3(auto_cast normal)
        // normal += 1
        // normal /= 2

        // mesh.vertex_data[mesh.index_data[i * 3]].normal = normal
        // mesh.vertex_data[mesh.index_data[i * 3 + 1]].normal = normal
        // mesh.vertex_data[mesh.index_data[i * 3 + 2]].normal = normal

        // dist := (glsl.length_vec3(auto_cast mesh.vertex_data[mesh.index_data[i * 3]].position) - 980.0) / 100.0

        // mesh.vertex_data[mesh.index_data[i * 3]].normal = auto_cast glsl.vec3{dist, dist, dist}
        // mesh.vertex_data[mesh.index_data[i * 3 + 1]].normal = auto_cast glsl.vec3{dist, dist, dist}
        // mesh.vertex_data[mesh.index_data[i * 3 + 2]].normal = auto_cast glsl.vec3{dist, dist, dist}

        index += 1
    }

    return mesh, true
}

// // TODO: This mesh reading needs complete rework.
// // NOTE: Do we want this to allocate the buffers as well? or more control by leaving?
read_obj_mesh :: proc(file_name : string) -> (mesh : ^IndexedMesh, err: bool = false) {
    mesh = new(IndexedMesh)
    log.info("Reading OBJ: ", file_name)

    file_path := make_file_path("local_tests/planet_loading/Assets/Meshes", file_name)

    file_contents, ok := os.read_entire_file(file_path, context.allocator)
    assert(ok, "Failed to read file")

    defer delete(file_contents, context.allocator)

    data := string(file_contents)

    vertex_count := 0
    texture_count := 0
    normal_count := 0
    face_count := 0
    index_count := 0

    // Count vertices and indicies first to allocate the memory
    // NOTE: Can also use dynamic arrays, should time both to see which is faster.
    // NOTE: Will only create vertices for number of unique vertices in file, however faces will have different normals.
    for line in strings.split_lines_iterator(&data) {
        parts := strings.split(line, " ")

        switch parts[0] {
            case "v":
                vertex_count += 1
            case "vt":
                texture_count += 1
            case "vn":
                normal_count += 1
            case "f":
                face_count += 1
                index_count += 3
                if len(parts) > 4 {
                    index_count += 3 * (len(parts) - 4)
                }
            case:
                continue
        }
    }

    log.info("Vertices:", vertex_count)
    log.info("Indices:", index_count)

    mesh.vertex_data = make([]Vertex, vertex_count)
    mesh.index_data = make([]u32, index_count)
    normals := make([]Vec3, normal_count)
    texture_coords := make([]Vec2, texture_count)

    defer {
        delete(normals)
        delete(texture_coords)
    }

    vertex_normal_count := make([]u32, vertex_count)
    defer delete(vertex_normal_count)

    vertex_count = 0
    texture_count = 0
    normal_count = 0
    face_count = 0
    index_count = 0

    data = string(file_contents)

    for line in strings.split_lines_iterator(&data) {
        parts := strings.split(line, " ")

        switch parts[0] {
            case "v":
                x, y, z : f32
                ok : bool
                x, ok = strconv.parse_f32(parts[1])
                // assert(ok, "Failed reading vertex")
                y, ok = strconv.parse_f32(parts[2])
                // assert(ok, "Failed reading vertex")
                z, ok = strconv.parse_f32(parts[3])
                // assert(ok, "Failed reading vertex")
                mesh.vertex_data[vertex_count].position = {x, y, z}

                vertex_count += 1
            case "vt":
                x, y : f32
                ok : bool
                x, ok = strconv.parse_f32(parts[1])
                assert(ok, "Failed reading texture")
                y, ok = strconv.parse_f32(parts[2])
                assert(ok, "Failed reading texture")
                texture_coords[texture_count] = {x, y}

                texture_count += 1
            case "vn":
                x, y, z : f32
                ok : bool
                x, ok = strconv.parse_f32(parts[1])
                assert(ok, "Failed reading normal")
                y, ok = strconv.parse_f32(parts[2])
                assert(ok, "Failed reading normal")
                z, ok = strconv.parse_f32(parts[3])
                assert(ok, "Failed reading normal")
                normals[normal_count] = {x, y, z}

                normal_count += 1
            case "f":
                // If Triangle
                if (len(parts) == 4) {
                    index := 1
                    for index < len(parts) {
                        face_indices := strings.split(parts[index], "/")

                        vertex_index, texture_index, normal_index : uint
                        ok : bool
                        vertex_index, ok = strconv.parse_uint(face_indices[0])
                        texture_index, ok = strconv.parse_uint(face_indices[1])
                        normal_index, ok = strconv.parse_uint(face_indices[2])

                        mesh.index_data[index_count] = cast(u32)vertex_index - 1
                        mesh.vertex_data[vertex_index - 1].normal += normals[normal_index - 1]
                        mesh.vertex_data[vertex_index - 1].texture_coords = texture_coords[texture_index - 1]
                        vertex_normal_count[vertex_index - 1] += 1

                        index += 1

                        index_count += 1
                    }
                // Quad TODO: This is not how this works apparently
                } else if len(parts) == 5 { 
                    // FIRST
                    face1_indices := strings.split(parts[1], "/")
                    vertex1_index, texture1_index, normal1_index : uint
                    ok : bool

                    vertex1_index, ok = strconv.parse_uint(face1_indices[0])
                    texture1_index, ok = strconv.parse_uint(face1_indices[1])
                    normal1_index, ok = strconv.parse_uint(face1_indices[2])

                    mesh.index_data[index_count] = cast(u32)vertex1_index - 1
                    mesh.vertex_data[vertex1_index - 1].normal += normals[normal1_index - 1]
                    mesh.vertex_data[vertex1_index - 1].texture_coords = texture_coords[texture1_index - 1]
                    vertex_normal_count[vertex1_index - 1] += 1

                    index_count += 1

                    // SECOND
                    face2_indices := strings.split(parts[2], "/")
                    vertex2_index, texture2_index, normal2_index : uint

                    vertex2_index, ok = strconv.parse_uint(face2_indices[0])
                    texture2_index, ok = strconv.parse_uint(face2_indices[1])
                    normal2_index, ok = strconv.parse_uint(face2_indices[2])

                    mesh.index_data[index_count] = cast(u32)vertex2_index - 1
                    mesh.vertex_data[vertex2_index - 1].normal += normals[normal2_index - 1]
                    mesh.vertex_data[vertex2_index - 1].texture_coords = texture_coords[texture2_index - 1]
                    vertex_normal_count[vertex2_index - 1] += 1

                    index_count += 1

                    // THIRD
                    face3_indices := strings.split(parts[3], "/")
                    vertex3_index, texture3_index, normal3_index : uint

                    vertex3_index, ok = strconv.parse_uint(face3_indices[0])
                    texture3_index, ok = strconv.parse_uint(face3_indices[1])
                    normal3_index, ok = strconv.parse_uint(face3_indices[2])

                    mesh.index_data[index_count] = cast(u32)vertex3_index - 1
                    mesh.vertex_data[vertex3_index - 1].normal += normals[normal3_index - 1]
                    mesh.vertex_data[vertex3_index - 1].texture_coords = texture_coords[texture3_index - 1]
                    vertex_normal_count[vertex3_index - 1] += 1
                    
                    index_count += 1

                    // RE-ADD THIRD AND SECOND
                    mesh.index_data[index_count] = cast(u32)vertex1_index - 1
                    index_count += 1
                    mesh.index_data[index_count] = cast(u32)vertex3_index - 1
                    index_count += 1

                    // FOURTH
                    face4_indices := strings.split(parts[4], "/")
                    vertex4_index, texture4_index, normal4_index : uint

                    vertex4_index, ok = strconv.parse_uint(face4_indices[0])
                    texture4_index, ok = strconv.parse_uint(face4_indices[1])
                    normal4_index, ok = strconv.parse_uint(face4_indices[2])

                    mesh.index_data[index_count] = cast(u32)vertex4_index - 1
                    mesh.vertex_data[vertex4_index - 1].normal += normals[normal4_index - 1]
                    mesh.vertex_data[vertex4_index - 1].texture_coords = texture_coords[texture4_index - 1]
                    vertex_normal_count[vertex4_index - 1] += 1
                    
                    index_count += 1
                }

                face_count += 1
            case:
                continue
        }
    }

    for vertex, index in mesh.vertex_data {
        mesh.vertex_data[index].normal /= cast(f32)vertex_normal_count[index]
    }
    
    return mesh, true
}