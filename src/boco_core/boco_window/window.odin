package boco_window

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import sdl "vendor:sdl2"
import vk "vendor:vulkan"

Window :: struct {
    main_window: ^sdl.Window,
    // Some shit
    width: u32,
    height: u32,

    Update : proc(time: int),

    child_windows: [dynamic]Window
}

init_window :: proc(using window: ^Window) -> (ok: bool = true) {
    log.info("Initialising Window")
    main_window = sdl.CreateWindow("Test", 200, 200, 1200, 1200, {.VULKAN, .RESIZABLE})

    w, h : i32
    sdl.GetWindowSize(main_window, &w, &h)
    width = cast(u32)w
    height = cast(u32)h

    return
}

create_window_surface :: proc(using window: ^Window, instance: vk.Instance, surface: ^vk.SurfaceKHR) -> bool {
    return auto_cast sdl.Vulkan_CreateSurface(main_window, instance, surface)
}

update_window :: proc(using window: ^Window) -> bool {
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .QUIT:
                return false
        }
    }

    return true
}

cleanup_window :: proc(using window: ^Window) {
    log.info("Cleaning window resources")
    sdl.DestroyWindow(main_window)
}