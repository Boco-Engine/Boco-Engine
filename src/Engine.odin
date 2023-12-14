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

init_engine :: proc(using engine: ^Engine) -> (ok: bool = true) {
    log.info("Started Boco Engine")

    ok = boco_renderer.init_renderer(&renderer)
    if !ok {
        log.error("Failed initialising renderer")
        return
    }

    ok = boco_window.init_window()
    if !ok {
        log.error("Failed to initialise Window")
        return
    }

    running = true
    return
}

run_engine :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        running = false
    }
}

cleanup_engine :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
}