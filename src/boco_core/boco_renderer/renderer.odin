package boco_renderer

GRAPHICS_API :: "Vulkan"

import "core:log"

SupportedRendererFeatures :: enum {
    tessellationShader,
    geometryShader,
}

RendererFeatures :: bit_set[SupportedRendererFeatures]

Renderer :: struct {
    using _renderer_internals : RendererInternals,
    features : RendererFeatures,
    needs_recreation : bool
}

init_renderer :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
    when GRAPHICS_API == "Vulkan" {
        ok = init_vulkan(renderer)
    } else {
        log.error("Unsupported Graphics API")
        return false
    }

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
    cleanup_vulkan(renderer)
}