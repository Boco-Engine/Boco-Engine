package boco_window

import "core:log"
import sdl "vendor:sdl2"

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
                        w, h : i32
                        sdl.GetWindowSize(view_window, &w, &h)
                        width = cast(u32)w
                        height = cast(u32)h
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
            scancode := cast(int)event.key.keysym.scancode
            if scancode < len(key_from_code) {
                window_event.input_event.key_event.key.name = key_from_code[scancode]
            } else {
                log.info("Invalid key scancode:", scancode)
            }
            window_event.input_event.key_event.key.code = cast(u32)event.key.keysym.scancode
            window_event.input_event.key_event.state = Key_state.Pressed
            handle_key_down(window, &window_event)
        case .KEYUP:
            window_event.state = Window_state.Key
            key_from_code := key_name_from_code
            scancode := cast(int)event.key.keysym.scancode
            if scancode < len(key_from_code) {
                window_event.input_event.key_event.key.name = key_from_code[scancode]
            } else {
                log.info("Invalid key scancode:", scancode)
            }
            window_event.input_event.key_event.key.code = cast(u32)event.key.keysym.scancode
            window_event.input_event.key_event.state = Key_state.Released
            handle_key_up(window, &window_event)
        case .MOUSEBUTTONDOWN:
            window_event.state = Window_state.Mouse
            button_from_code := mouse_button_from_code
            button_state := cast(int)event.button.button
            length := len(button_from_code)
            if button_state < length {
                window_event.input_event.mouse_event.button = button_from_code[button_state]
            }
            else {
                log.info("Invalid mouse button state:", button_state)
            }
            window_event.input_event.mouse_event.state = Mouse_state.Pressed
            window_event.input_event.mouse_event.x = event.motion.x
            window_event.input_event.mouse_event.y = event.motion.y
            handle_mouse_down(window, &window_event)
        case .MOUSEBUTTONUP:
            window_event.state = Window_state.Mouse
            button_from_code := mouse_button_from_code
            button_state := cast(int)event.button.button
            length := len(button_from_code)
            if button_state < length {
                window_event.input_event.mouse_event.button = button_from_code[button_state]
            }
            else {
                log.info("Invalid mouse button state:", button_state)
            }
            window_event.input_event.mouse_event.state = Mouse_state.Released
            window_event.input_event.mouse_event.x = event.motion.x
            window_event.input_event.mouse_event.y = event.motion.y
            handle_mouse_up(window, &window_event)
        case .MOUSEMOTION:
            window_event.state = Window_state.Mouse
            button_from_code := mouse_button_from_code
            button_state := cast(int)event.button.state
            length := len(button_from_code)
            if button_state < length {
                window_event.input_event.mouse_event.button = button_from_code[button_state]
            }
            else {
                log.info("Invalid mouse button state:", button_state)
            }
            window_event.input_event.mouse_event.state = Mouse_state.Moved
            window_event.input_event.mouse_event.x = event.motion.x
            window_event.input_event.mouse_event.y = event.motion.y
            handle_mouse_move(window, &window_event)
        case .MOUSEWHEEL:
            window_event.state = Window_state.Mouse
            window_event.input_event.mouse_event.state = Mouse_state.Wheel
            window_event.input_event.mouse_event.x = event.motion.x
            window_event.input_event.mouse_event.y = event.motion.y
            window_event.input_event.mouse_event.wheel_x = event.wheel.x
            window_event.input_event.mouse_event.wheel_y = event.wheel.y
            handle_mouse_wheel(window, &window_event)
        }
    }
}