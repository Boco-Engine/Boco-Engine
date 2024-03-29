package input

import "core:log"
import "core:time"

import "boco:core/event_data"

Input_data :: struct{
    key_state_info : [event_data.Key_name]Key_state_info,
    mouse_data : Mouse_data,
}

Mouse_data :: struct{
    mouse_state_info : [8]Mouse_state_info,
    x: i32,
    y: i32,
    wheel_x: i32,
    wheel_y: i32,
}

Input_event :: union{
    event_data.Key_event,
    event_data.Mouse_event,
}

Key_state_info :: struct{
    key_state: event_data.Key_state,
    duration: f32, // TODO: Add duration
}

Mouse_state_info :: struct{
    mouse_state: event_data.Mouse_state,
    duration: f32, // TODO: Add duration
}

handle_key_down :: proc(key_event : event_data.Key_event, input_data : ^Input_data){
    key_state_info := &input_data.key_state_info[key_event.key.name];
    key_state_info.key_state = .Pressed;
}

handle_key_up :: proc(key_event : event_data.Key_event, input_data : ^Input_data){
    // key_state_info := input_data.key_state_info[key_event.key.name];
    input_data.key_state_info[key_event.key.name].key_state = event_data.Key_state.Released;
}

handle_mouse_down :: proc(mouse_event : event_data.Mouse_event, input_data : ^Input_data){
    mouse_state_info := &input_data.mouse_data.mouse_state_info[cast(int)(mouse_event.button) + 2];
    mouse_state_info.mouse_state = .Pressed;
}

handle_mouse_up :: proc(mouse_event : event_data.Mouse_event, input_data : ^Input_data){
    mouse_state_info := &input_data.mouse_data.mouse_state_info[cast(int)(mouse_event.button) + 2];
    mouse_state_info.mouse_state = .Released;
}

handle_mouse_move :: proc(mouse_event : event_data.Mouse_event, input_data : ^Input_data){
    mouse_state_info := &input_data.mouse_data.mouse_state_info[0];
    mouse_state_info.mouse_state = .Moved;

    mouse_data_x := &input_data.mouse_data.x;
    mouse_data_x^ = mouse_event.x;
    mouse_data_y := &input_data.mouse_data.y;
    mouse_data_y^ = mouse_event.y;
}

handle_mouse_wheel :: proc(mouse_event : event_data.Mouse_event, input_data : ^Input_data){
    mouse_state_info := &input_data.mouse_data.mouse_state_info[1];
    mouse_state_info.mouse_state = .Wheel;
    mouse_data_x := &input_data.mouse_data.wheel_x;
    mouse_data_x^ = mouse_event.wheel_x;
    mouse_data_y := &input_data.mouse_data.wheel_y;
    mouse_data_y^ = mouse_event.wheel_y;
}