package boco_window

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")

import "core:log"
import sdl "vendor:sdl2"

Window :: struct {
    name: cstring,
    width: u32,
    height: u32,
    view_window: ^sdl.Window,
    window_id: u32,
    view_area: ViewArea,
    child_windows: [dynamic]Window,
    parent_window: ^Window,
    is_ready_to_close: bool
}

init :: proc(using window: ^Window, title: cstring = "BOCO") -> (ok: bool = true) {
    name = title
    log.info("Initialising Window:", name)
    view_window = sdl.CreateWindow(name, sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED, 500, 500, {.VULKAN, .RESIZABLE})
    window_id = sdl.GetWindowID(view_window)
    log.info("WindowID", window_id)
    return
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

    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            window_event.state = Window_state.Quit
            is_ready_to_close = true
            log.info("Closing Application")
        case .WINDOWEVENT:
            if event.window.windowID == window_id{
                window_event.window = window
                log.info("_____________________")
                log.info("Event window ID:", event.window.windowID)
                log.info("----- window ID:", window_id)
                log.info("_____________________")
                #partial switch event.window.event {
                    case .CLOSE:
                        window_event.state = Window_state.Quit
                        is_ready_to_close = true
                        log.info("Closing Window:", name)
                    case .FOCUS_GAINED:
                        window_event.state = Window_state.Focus
                        log.info("Focusing Window:", name)
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
            }
        case .KEYDOWN:
            window_event.state = Window_state.Key
            key_from_code := key_name_from_code
            window_event.key_event.key.name = key_from_code[event.key.keysym.scancode]
            window_event.key_event.key.code = cast(u32)event.key.keysym.scancode
            window_event.key_event.state = Key_state.Pressed
            log.info("_____________________")
            log.info("Key Pressed on window:", name)
            log.info(window_event.key_event.key.name)
            log.info("_____________________")
            receive_event(parent_window, &window_event)
        case .KEYUP:
            window_event.state = Window_state.Key
            key_from_code := key_name_from_code
            window_event.key_event.key.name = key_from_code[event.key.keysym.scancode]
            window_event.key_event.key.code = cast(u32)event.key.keysym.scancode
            window_event.key_event.state = Key_state.Released
            log.info("_____________________")
            log.info("Key Released on window:", name)
            log.info(window_event.key_event.key.name)
            log.info("_____________________")
            receive_event(parent_window, &window_event)
        }
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