package renderer

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import "core:time"

import "boco:core/window"

// TODO: Probably want this a runtime selection not compile time? Might want to give choice between apis without needing two versions of the executable?
when GRAPHICS_API == "vulkan" {
    init_graphics_api :: init_vulkan
    cleanup_graphics_api :: cleanup_vulkan
} else when GRAPHICS_API == "DirectX 12" {

}

SupportedRendererFeatures :: enum 
{
    tessellationShader, 
    geometryShader,
    shaderf64,
    anisotropy,
    fillModeNonSolid,
}

RendererFeatures :: bit_set[SupportedRendererFeatures]

Renderer :: struct {
    // TODO: This feels jank
    using _renderer_internals : RendererInternals,
    main_window : ^window.Window,

    // TODO: Create data structure to handle our meshes
    mesh_ids: map[string]MeshID,
    mesh_paths: map[MeshID]string,
    meshes: map[MeshID]rawptr,

    _next_mesh_id: MeshID,
    _next_material_id: MaterialID,

    font: Font,
}

load_mesh_file :: proc(using renderer: ^Renderer, path: string) -> MeshID {
    mesh_id, exists := mesh_ids[path]
    if exists do return mesh_id

    mesh_ids[path] = _next_mesh_id
    meshes[_next_mesh_id] = cast(rawptr)init_mesh(renderer, path)
    mesh_paths[_next_mesh_id] = path
    _next_mesh_id += 1
    return mesh_ids[path]
}

create_ui_text :: proc(using renderer: ^Renderer, text: string) -> MeshID {
    mesh_ids[text] = _next_mesh_id
    meshes[_next_mesh_id] = cast(rawptr)init_ui_element(renderer, text)
    mesh_paths[_next_mesh_id] = text
    _next_mesh_id += 1
    return mesh_ids[text]
}

deinit_mesh_from_path :: proc(using renderer: ^Renderer, path: string) -> bool {
    mesh_id, exists := mesh_ids[path]
    if !exists do return false

    mesh := meshes[mesh_id]

    free_buffer(renderer, &(cast(^IndexedMesh)(mesh)).index_buffer_resource)
    free_buffer(renderer, &(cast(^IndexedMesh)(mesh)).vertex_buffer_resource)

    delete((cast(^IndexedMesh)(mesh)).vertex_data)
    delete((cast(^IndexedMesh)(mesh)).index_data)
    free(mesh)

    delete_key(&mesh_ids, path)
    delete_key(&mesh_paths, mesh_id)
    delete_key(&meshes, mesh_id)

    return true
}

deinit_mesh_from_id :: proc(using renderer: ^Renderer, mesh_id: MeshID) -> bool {
    mesh, exists := meshes[mesh_id]
    if !exists do return false
    path := mesh_paths[mesh_id]

    free_buffer(renderer, &(cast(^IndexedMesh)(mesh)).index_buffer_resource)
    free_buffer(renderer, &(cast(^IndexedMesh)(mesh)).vertex_buffer_resource)

    delete((cast(^IndexedMesh)(mesh)).vertex_data)
    delete((cast(^IndexedMesh)(mesh)).index_data)
    free(mesh)

    delete_key(&mesh_ids, path)
    delete_key(&mesh_paths, mesh_id)
    delete_key(&meshes, mesh_id)

    return true
}

deinit_mesh :: proc{deinit_mesh_from_id, deinit_mesh_from_path}

init :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
    ok = init_graphics_api(renderer)
    
    if !ok {
        log.error("Failed to initialise Vulkan")
        return
    }

    return
}

version :: proc() -> string {
    return "BOCO Renderer Version: 0.1"
}

cleanup_renderer :: proc(using renderer: ^Renderer) {
    wait_on_api(renderer)
    cleanup_scenes(renderer)
    cleanup_graphics_api(renderer)
}

cleanup_scenes :: proc(using renderer: ^Renderer) -> bool {
    // for scene in &scenes {
    //     for mesh in scene.meshes {
    //         destroy_mesh(renderer, mesh)
    //     }
    //     delete(scene.meshes)
    //     for mesh in scene.static_meshes {
    //         destroy_mesh(renderer, mesh)
    //     }
    //     delete(scene.static_meshes)
    // }
    return true
}

wait_on_api :: proc(using renderer: ^Renderer) {
	wait_on_device(renderer)
}