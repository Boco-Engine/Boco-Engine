package boco_window

import "core:log"

handle_key_down :: proc(using window: ^Window, window_event: ^Window_event){
    log.info("_____________________")
    log.info("Key Pressed: ", window_event.input_event.key_event.key.name)
    log.info("_____________________")
    receive_event(parent_window, window_event)
}

handle_key_up :: proc(using window: ^Window, window_event: ^Window_event){
    log.info("_____________________")
    log.info("Key Released: ", window_event.input_event.key_event.key.name)
    log.info("_____________________")
    receive_event(parent_window, window_event)
}

handle_mouse_down :: proc(using window: ^Window, window_event: ^Window_event){
    log.info("_____________________")
    log.info("Mouse Pressed: ", window_event.input_event.mouse_event.button)
    log.info("X: ", window_event.input_event.mouse_event.x)
    log.info("Y: ", window_event.input_event.mouse_event.y)
    log.info("_____________________")
    receive_event(parent_window, window_event)
}

handle_mouse_up :: proc(using window: ^Window, window_event: ^Window_event){
    log.info("_____________________")
    log.info("Mouse Released: ", window_event.input_event.mouse_event.button)
    log.info("X: ", window_event.input_event.mouse_event.x)
    log.info("Y: ", window_event.input_event.mouse_event.y)
    log.info("_____________________")
    receive_event(parent_window, window_event)
}

handle_mouse_move :: proc(using window: ^Window, window_event: ^Window_event){
    log.info("_____________________")
    log.info("Mouse Moved:")
    log.info("X: ", window_event.input_event.mouse_event.x)
    log.info("Y: ", window_event.input_event.mouse_event.y)
    log.info("_____________________")
    receive_event(parent_window, window_event)
}

handle_mouse_wheel :: proc(using window: ^Window, window_event: ^Window_event){
    log.info("_____________________")
    log.info("Mouse Wheel:")
    log.info("X: ", window_event.input_event.mouse_event.x)
    log.info("Y: ", window_event.input_event.mouse_event.y)
    log.info("Wheel X: ", window_event.input_event.mouse_event.wheel_x)
    log.info("Wheel Y: ", window_event.input_event.mouse_event.wheel_y)
    log.info("_____________________")
    receive_event(parent_window, window_event)
}