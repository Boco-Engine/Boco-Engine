package renderer

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import "core:time"

import "vendor:microui"

import "boco:core/window"

// Not sure I like this, but makes swapping out Graphics APIs pretty easy if we decide to add XBOX/PS Support
// Would be better to just import the file and have these already defined, but cant put import in a when.
when GRAPHICS_API == "vulkan" {
    init_graphics_api :: init_vulkan
    cleanup_graphics_api :: cleanup_vulkan
} 
else when GRAPHICS_API == "DirectX 12" 
{

}

SupportedRendererFeatures :: enum 
{
    tessellationShader, 
    geometryShader,
    shaderf64,
    anisotropy
}

RendererFeatures :: bit_set[SupportedRendererFeatures]

Renderer :: struct {
    using _renderer_internals : RendererInternals,
    main_window : ^window.Window,

    needs_recreation : bool,

    current_scene_id: u32,

    ui_context: microui.Context,

    // Duplicate data to avoid having to check for all paths on removal of mesh.
    mesh_ids: map[string]MeshID,
    mesh_paths: map[MeshID]string,
    meshes: map[MeshID]^IndexedMesh,

    _next_mesh_id: u32,
}

load_mesh_file :: proc(using renderer: ^Renderer, path: string) -> MeshID {
    mesh_id, exists := mesh_ids[path]
    if exists do return mesh_id

    mesh_ids[path] = _next_mesh_id
    meshes[_next_mesh_id] = init_mesh(renderer, path)
    log.debug(meshes[_next_mesh_id].vertex_data[:10])
    mesh_paths[_next_mesh_id] = path
    _next_mesh_id += 1
    return mesh_ids[path]
}

deinit_mesh_from_path :: proc(using renderer: ^Renderer, path: string) -> bool {
    mesh_id, exists := mesh_ids[path]
    if !exists do return false

    mesh := meshes[mesh_id]

    free_buffer(renderer, &mesh.index_buffer_resource)
    free_buffer(renderer, &mesh.vertex_buffer_resource)

    delete(mesh.vertex_data)
    delete(mesh.index_data)
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

    free_buffer(renderer, &mesh.index_buffer_resource)
    free_buffer(renderer, &mesh.vertex_buffer_resource)

    delete(mesh.vertex_data)
    delete(mesh.index_data)
    free(mesh)

    delete_key(&mesh_ids, path)
    delete_key(&mesh_paths, mesh_id)
    delete_key(&meshes, mesh_id)

    return true
}

deinit_mesh :: proc{deinit_mesh_from_id, deinit_mesh_from_path}

init_ui :: proc(using renderer: ^Renderer) {
    microui.init(&ui_context)
    ui_context.text_width = proc(font: microui.Font, str: string) -> i32 { return auto_cast (10 * len(str)) }
    ui_context.text_height = proc(font: microui.Font) -> i32 { return 10 }
}

init :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
    ok = init_graphics_api(renderer)
    
    if !ok {
        log.error("Failed to initialise Vulkan")
        return
    }

    return
}

update :: proc(using renderer: ^Renderer) -> bool {
    return true
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