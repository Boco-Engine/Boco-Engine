package boco_window

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import sdl "vendor:sdl2"

Window :: struct {
    // Some shit
    width: u32,
    height: u32,
    view_window: ^sdl.Window,
    view_area: ^ViewArea,
    child_windows: [dynamic]Window
}

init :: proc(using window: ^Window) -> (ok: bool = true) {
    log.info("Initialising Window")
    view_window = sdl.CreateWindow("BOCO", sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, 500, 500, {.VULKAN, .RESIZABLE})
    return
}

update :: proc(using window: ^Window) -> (ok: bool = true) {
    update_child_windows(window)
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            return false
        }
    }
    return true
}

create_child_window :: proc(using window: ^Window){
    new_window:Window
    append(&child_windows, new_window)
}

update_child_windows :: proc(using window: ^Window){
    length := len(&child_windows)
    for i := length - 1; i >= 0; i -= 1{
        child_window := &child_windows[i]
        if (!update(child_window)){
            cleanup(child_window)
            ordered_remove(&child_windows, i)
        }
    }
}

cleanup :: proc(using window: ^Window) {
    log.info("Cleaning window resources")

    length := len(&child_windows)
    for i := length - 1; i >= 0; i -= 1{
        child_window := &child_windows[i]
        cleanup(child_window)
    }
    delete(child_windows)

    sdl.DestroyWindow(view_window)
}