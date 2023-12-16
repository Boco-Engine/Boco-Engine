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

init_engine :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
    }

    boco_window.init_window() or_return
    boco_renderer.init_renderer(&renderer) or_return

    running = true
    return true
}

run_engine :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        running = false
    }
}

cleanup_engine :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup_window(&window)
    boco_renderer.cleanup_renderer(&renderer)
}