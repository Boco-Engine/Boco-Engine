package boco_window

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import "../boco_input"
import sdl "vendor:sdl2"
import vk "vendor:vulkan"

Window :: struct {
    name: cstring,
    width: u32,
    height: u32,
    view_window: ^sdl.Window,
    window_id: u32,
    view_area: ViewArea,
    child_windows: [dynamic]Window,
    parent_window: ^Window,
    is_ready_to_close: bool,
    input_data: boco_input.Input_data
}

update_size :: proc(using window: ^Window) {
    w, h : i32
    sdl.GetWindowSize(view_window, &w, &h)
    width = cast(u32)w
    height = cast(u32)h
    log.error("WIDTH: ", width, " HEIGHT: ", height)
}

init :: proc(using window: ^Window, title: cstring = "BOCO") -> (ok: bool = true) {
    name = title
    log.info("Initialising Window:", name)
    view_window = sdl.CreateWindow(name, sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, 500, 500, {.VULKAN, .RESIZABLE})
    window_id = sdl.GetWindowID(view_window)
    log.info("WindowID", window_id)
    
    // Added size query -> Need to update on resize
    w, h : i32
    sdl.GetWindowSize(view_window, &w, &h)
    width = cast(u32)w
    height = cast(u32)h
    
    return
}

create_window_surface :: proc(using window: ^Window, instance: vk.Instance, surface: ^vk.SurfaceKHR) -> bool {
    return auto_cast sdl.Vulkan_CreateSurface(view_window, instance, surface)
}

update :: proc(using window: ^Window) -> (should_close: bool = true){
    if (is_ready_to_close) {
        log.info("Closing Window:", name)
        return false
    }

    update_child_windows(window)

    handle_window_event_or_delegate(window)

    return true
}

receive_event :: proc(window: ^Window, window_event: ^Window_event){
    //TODO: Decide if we want to propogate events up the chain or not
    #partial switch window_event.state{
        case .Quit:
        case .Focus:
        case .Unfocus:
        case .Move:
        case .Resize:
        case .Key:
    }
}

create_child_window :: proc(using window: ^Window, title: cstring = "BOCO"){
    new_window:Window
    new_window.parent_window = window
    append(&child_windows, new_window)
    init(&child_windows[len(child_windows) - 1], title)
}

update_child_windows :: proc(using window: ^Window){
    length := len(&child_windows)
    for i := length - 1; i >= 0; i -= 1{
        child_window := &child_windows[i]
        if (!update(child_window)){
            cleanup(child_window)
            unordered_remove(&child_windows, i)
            continue
        }
    }
}

close_child_window :: proc(using window: ^Window){
    length := len(&child_windows)
    for i := length - 1; i >= 0; i -= 1{
        child_window := &child_windows[i]
        if (child_window == window){
            cleanup(child_window)
            unordered_remove(&child_windows, i)
            return
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