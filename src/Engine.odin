package BocoEngine

import "core:fmt"
import "core:log"
import "boco_core/boco_renderer"
import "boco_core/boco_window"
import "core:runtime"

Engine :: struct {
    running : bool,

    window : boco_window.Window,
    renderer : boco_renderer.Renderer,
}

init :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
    }

    boco_window.init(&window) or_return
    boco_renderer.init_renderer(&renderer) or_return

    running = true
    return true
}

run :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        running &= boco_window.update(&window)
    }
}

cleanup :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup(&window)
    boco_renderer.cleanup_renderer(&renderer)
}