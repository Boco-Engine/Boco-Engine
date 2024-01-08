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

    child_windows: [dynamic]Window
}

create_window_surface :: proc(using window: ^Window, instance: vk.Instance, surface: ^vk.SurfaceKHR) -> bool {
    return auto_cast sdl.Vulkan_CreateSurface(main_window, instance, surface)
}

init :: proc(using window: ^Window) -> (ok: bool = true) {
    log.info("Initialising Window")
    view_window = sdl.CreateWindow("BOCO", sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, 500, 500, {.VULKAN, .RESIZABLE})
    
    w, h : i32
    sdl.GetWindowSize(main_window, &w, &h)
    width = cast(u32)w
    height = cast(u32)h

    return
}

update :: proc(using window: ^Window) -> (ok: bool = true) {
    event: sdl.Event
    if event.window.windowID == sdl.GetWindowID(window.view_window){
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT:
                return false
            }
        }
    }
    update_child_windows(window)
    
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
            unordered_remove(&child_windows, i)
        }
    }
}

cleanup :: proc(using window: ^Window) {
    log.info("Cleaning window resources")

    length := len(&child_windows)
    for &window in child_windows{
        cleanup(&window)
    }
    delete(child_windows)

    sdl.DestroyWindow(view_window)
}