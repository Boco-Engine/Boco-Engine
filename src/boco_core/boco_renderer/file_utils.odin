package boco_renderer

import "core:os"
import "core:strings"
import "core:log"
import "core:strconv"
import "core:math/linalg/glsl"
import stbi "vendor:stb/image"

load_texture :: proc(renderer: ^Renderer, file: string, channels: i32) {
    texture: Texture

    file_path := make_file_path("local_tests/planet_loading/Assets/Textures/", file)

    image_width: i32
    image_height: i32
    image_channels: i32
    image := stbi.load(strings.unsafe_string_to_cstring(file_path), &image_width, &image_height, &image_channels, channels)
    
    staging_buffer: BufferResources
    allocate_buffer(renderer, )
}

init_mesh :: proc(renderer: ^Renderer, file: string) -> ^IndexedMesh {
    mesh := new(IndexedMesh)
    mesh_err : bool
    mesh^, mesh_err = read_bocom_mesh(file)

    mesh.push_constant.m = matrix[4, 4]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }

    // CREATE VERTEX BUFFER
    allocate_buffer(renderer, Vertex, auto_cast len(mesh.vertex_data), {.VERTEX_BUFFER}, &mesh.vertex_buffer_resource)
    write_to_buffer(renderer, &mesh.vertex_buffer_resource, mesh.vertex_data, 0)
    // CREATE INDEX BUFFER
    allocate_buffer(renderer, u32, auto_cast len(mesh.index_data), {.INDEX_BUFFER}, &mesh.index_buffer_resource)
    write_to_buffer(renderer, &mesh.index_buffer_resource, mesh.index_data, 0)
    // ADD TO DRAW LIST
    return mesh
}

make_file_path :: proc(folder : string, file : string) -> (path : string) {
    builder := strings.builder_make(0, len(folder) + len(file) + 1)
    strings.write_string(&builder, folder)
    strings.write_string(&builder, "/")
    strings.write_string(&builder, file)
    return strings.to_string(builder)
}

read_spirv :: proc(file_name : string) -> (code : []u8, err : bool = true) {
    // TODO: More robust way to get the folder path.
    path : string = make_file_path("../Boco-Engine/Shaders/compiled", file_name)

    file_contents, ok := os.read_entire_file(path, context.allocator)

    if (!ok) {
        log.error("Failed to read file:", file_name)
        return {}, false
    }
    log.info("Successfully read file:", file_name)

    return file_contents, err
}

read_mesh :: proc(file_name : string) -> (mesh : IndexedMesh, err: bool = false) {
    file_type := (strings.cut(file_name, strings.last_index(file_name, "."), 0))

    switch file_type {
        case ".obj":
            return read_obj_mesh(file_name)
        case:
            log.error("Unsupported file type being loaded.")
    }

    return {}, false
}

read_bocom_mesh :: proc(file_name: string) -> (mesh: IndexedMesh, err: bool = false) {
    log.info("Reading BOCOM: ", file_name)
    // TODO: More Robust way to find files
    file_path := make_file_path("local_tests/planet_loading/Assets/Meshes", file_name)

    file_contents, ok := os.read_entire_file(file_path, context.allocator)
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
            cast(f32)strconv.atof(position_parts[0]),
            cast(f32)strconv.atof(position_parts[1]),
            cast(f32)strconv.atof(position_parts[2]),
        }

        normal := parts[1]
        normal_parts := strings.split(normal, " ")

        mesh.vertex_data[vertex].normal = {
            cast(f32)strconv.atof(normal_parts[0]),
            cast(f32)strconv.atof(normal_parts[1]),
            cast(f32)strconv.atof(normal_parts[2]),
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

    log.debug("Vertices: ", len(mesh.vertex_data))

    return mesh, true
}

// TODO: This mesh reading needs complete rework.
// NOTE: Do we want this to allocate the buffers as well? or more control by leaving?
read_obj_mesh :: proc(file_name : string) -> (mesh : IndexedMesh, err: bool = false) {
    log.info("Reading OBJ: ", file_name)

    file_path := make_file_path("Assets/Meshes", file_name)

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
    log.info("Made arrays")
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