package boco_renderer

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import "core:time"
import "../boco_window"

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
    geometryShader
}

RendererFeatures :: bit_set[SupportedRendererFeatures]

Renderer :: struct {
    using _renderer_internals : RendererInternals,
    main_window : ^boco_window.Window,

    needs_recreation : bool,

    indexed_meshes: [dynamic]^IndexedMesh,
}

init_renderer :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
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
    cleanup_graphics_api(renderer)
}

add_mesh :: proc(using renderer: ^Renderer, mesh: ^IndexedMesh) {
    append(&renderer.indexed_meshes, mesh);
}