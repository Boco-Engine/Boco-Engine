package window

import "core:log"

import sdl "vendor:sdl2"

import "boco:core/event_data"
import "boco:core/input"

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
            key_event: event_data.Key_event
            input_event: input.Input_event
            input_event = key_event
            handle_key_event(&window.input_data, event, &input_event, event_data.Key_state.Pressed)
        case .KEYUP:
            window_event.state = Window_state.Key
            key_event: event_data.Key_event
            input_event: input.Input_event
            input_event = key_event
            handle_key_event(&window.input_data, event, &input_event, event_data.Key_state.Released)
        case .MOUSEBUTTONDOWN:
            window_event.state = Window_state.Mouse
            mouse_event: event_data.Mouse_event
            input_event: input.Input_event
            input_event = mouse_event
            handle_mouse_event(&window.input_data, event, &input_event, event_data.Mouse_state.Pressed, 0, 0, 0, 0)
        case .MOUSEBUTTONUP:
            window_event.state = Window_state.Mouse
            mouse_event: event_data.Mouse_event
            input_event: input.Input_event
            input_event = mouse_event
            handle_mouse_event(&window.input_data, event, &input_event, event_data.Mouse_state.Released, 0, 0, 0, 0)
        case .MOUSEMOTION:
            window_event.state = Window_state.Mouse
            mouse_event: event_data.Mouse_event
            input_event: input.Input_event
            input_event = mouse_event
            handle_mouse_event(&window.input_data, event, &input_event, event_data.Mouse_state.Moved, event.motion.x, event.motion.y, 0, 0)
        case .MOUSEWHEEL:
            window_event.state = Window_state.Mouse
            mouse_event: event_data.Mouse_event
            input_event: input.Input_event
            input_event = mouse_event
            handle_mouse_event(&window.input_data, event, &input_event, event_data.Mouse_state.Wheel, 0, 0, event.wheel.x, event.wheel.y)
        }
    }
}

handle_key_event :: proc(input_data : ^input.Input_data, event : sdl.Event, input_event : ^input.Input_event, key_state : event_data.Key_state){
    key_event := input_event.(event_data.Key_event)
    key_from_code := event_data.key_name_from_code
    scancode := cast(int)event.key.keysym.scancode
    if scancode < len(key_from_code) {
        key_event.key.name = key_from_code[scancode]
    } else {
        log.info("Invalid key scancode:", scancode)
        key_event.key.name = event_data.Key_name.Unknown
    }
    key_event.key.code = cast(u32)event.key.keysym.scancode
    key_event.state = key_state

    #partial switch key_state{
        case event_data.Key_state.Pressed:
            input.handle_key_down(key_event, input_data)
            log.debug(key_event)
        case event_data.Key_state.Released:
            input.handle_key_up(key_event, input_data)
    }
}

handle_mouse_event :: proc(input_data : ^input.Input_data, event : sdl.Event, input_event : ^input.Input_event, mouse_state : event_data.Mouse_state, motion_x : i32, motion_y : i32, scroll_x : i32, scroll_y : i32){
    mouse_event := input_event.(event_data.Mouse_event)
    mouse_event.state = mouse_state
    mouse_event.x = motion_x
    mouse_event.y = motion_y
    mouse_event.wheel_x = scroll_x
    mouse_event.wheel_y = scroll_y
    
    #partial switch mouse_state{
        case event_data.Mouse_state.Pressed, event_data.Mouse_state.Released:
            button_from_code := event_data.mouse_button_from_code
            button_state := cast(int)event.button.button
            length := len(button_from_code)
            if button_state < length {
                mouse_event.button = button_from_code[button_state]
            }
            else {
                //TODO: Decide how to handle unknown mouse buttons
                log.info("Invalid mouse button state:", button_state)
                mouse_event.button = event_data.Mouse_button.Unknown
            }
        case:
            mouse_event.button = event_data.Mouse_button.Unknown
    }

    #partial switch mouse_state{
        case event_data.Mouse_state.Pressed:
            input.handle_mouse_down(mouse_event, input_data)
        case event_data.Mouse_state.Released:
            input.handle_mouse_up(mouse_event, input_data)
        case event_data.Mouse_state.Moved:
            input.handle_mouse_move(mouse_event, input_data)
        case event_data.Mouse_state.Wheel:
            input.handle_mouse_wheel(mouse_event, input_data)
    }
}