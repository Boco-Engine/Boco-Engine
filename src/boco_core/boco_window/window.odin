package boco_window

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import sdl "vendor:sdl2"

Window :: struct {
    width: u32,
    height: u32,
    view_window: ^sdl.Window,
    view_area: ViewArea,
    child_windows: [dynamic]Window,
    parent_window: ^Window,
    is_ready_to_close: bool
}

init :: proc(using window: ^Window) -> (ok: bool = true) {
    log.info("Initialising Window")
    view_window = sdl.CreateWindow("BOCO", sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, 500, 500, {.VULKAN, .RESIZABLE})
    return
}

update :: proc(using window: ^Window) -> (should_close: bool = true){
    if (is_ready_to_close) {
        log.info("Closing Window")
        return false
    }

    update_child_windows(window)

    handle_window_event_or_delegate(window)

    return true
}

receive_event :: proc(window: ^Window, window_event: ^Window_event){
    #partial switch window_event.state{
        case .Quit:
        case .Focus:
        case .Unfocus:
        case .Move:
        case .Resize:
        case .Key:
    }
}

handle_window_event_or_delegate :: proc(using window: ^Window){
    event: sdl.Event
    window_event: Window_event

    if event.window.windowID == sdl.GetWindowID(window.view_window){
        window_event.window = window
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT:
                window_event.state = Window_state.Quit
                if (window.parent_window != nil){
                    is_ready_to_close = true
                }
            case .WINDOWEVENT:
                #partial switch event.window.event {
                case .FOCUS_GAINED:
                    window_event.state = Window_state.Focus
                case .FOCUS_LOST:
                    window_event.state = Window_state.Unfocus
                case .MOVED:
                    window_event.state = Window_state.Move
                case .RESIZED:
                    window_event.state = Window_state.Resize
                case .SIZE_CHANGED:
                    window_event.state = Window_state.Resize
                case .MINIMIZED:
                    window_event.state = Window_state.Minimize
                case .MAXIMIZED:
                    window_event.state = Window_state.Maximize
                case .RESTORED:
                    window_event.state = Window_state.Restore
                case .ENTER:
                    window_event.state = Window_state.Enter
                case .LEAVE:
                    window_event.state = Window_state.Leave
            }
            case .KEYDOWN:
                window_event.state = Window_state.Key
                key_from_code := key_name_from_code
                window_event.key_event.key.name = key_from_code[event.key.keysym.sym]
                window_event.key_event.key.code = cast(u32)event.key.keysym.sym
                window_event.key_event.state = Key_state.Pressed
                receive_event(parent_window, &window_event)
            case .KEYUP:
                window_event.state = Window_state.Key
                key_from_code := key_name_from_code
                window_event.key_event.key.name = key_from_code[event.key.keysym.sym]
                window_event.key_event.key.code = cast(u32)event.key.keysym.sym
                window_event.key_event.state = Key_state.Released
                receive_event(parent_window, &window_event)
            }
        }
    }
}

create_child_window :: proc(using window: ^Window){
    new_window:Window
    new_window.parent_window = window
    append(&child_windows, new_window)
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