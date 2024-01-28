package boco_input

import "core:log"
import "../boco_event_data"

Input_event :: struct{
    key_event: boco_event_data.Key_event,
    mouse_event: boco_event_data.Mouse_event,
}

handle_key_down :: proc(key_event : boco_event_data.Key_event){
    log.info("_____________________")
    log.info("Key Pressed: ", key_event.key.name)
    log.info("_____________________")
}

handle_key_up :: proc(key_event : boco_event_data.Key_event){
    log.info("_____________________")
    log.info("Key Released: ", key_event.key.name)
    log.info("_____________________")
}

handle_mouse_down :: proc(mouse_event : boco_event_data.Mouse_event){
    log.info("_____________________")
    log.info("Mouse Pressed: ", mouse_event.button)
    log.info("_____________________")
}

handle_mouse_up :: proc(mouse_event : boco_event_data.Mouse_event){
    log.info("_____________________")
    log.info("Mouse Released: ", mouse_event.button)
    log.info("_____________________")
}

handle_mouse_move :: proc(mouse_event : boco_event_data.Mouse_event){
    log.info("_____________________")
    log.info("Mouse Moved:")
    log.info("X: ", mouse_event.x)
    log.info("Y: ", mouse_event.y)
    log.info("_____________________")
}

handle_mouse_wheel :: proc(mouse_event : boco_event_data.Mouse_event){
    log.info("_____________________")
    log.info("Mouse Wheel:")
    log.info("Wheel X: ", mouse_event.wheel_x)
    log.info("Wheel Y: ", mouse_event.wheel_y)
    log.info("_____________________")
}