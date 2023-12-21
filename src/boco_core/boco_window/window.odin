package boco_window

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import sdl "vendor:sdl2"

Window :: struct {
    windows: [dynamic]sdl.Window,
    // Some shit
    width: u32,
    height: u32,

    Update : proc(time: int),

    child_windows: [dynamic]Window
}

init_window :: proc(using window: ^Window) -> (ok: bool = true) {
    log.info("Initialising Window")

    return
}

cleanup_window :: proc(using window: ^Window) {
    log.info("Cleaning window resources")
}