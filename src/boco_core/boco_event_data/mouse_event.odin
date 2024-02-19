package boco_event_data

Mouse_event :: struct{
    state: Mouse_state,
    button: Mouse_button,
    x: i32,
    y: i32,
    wheel_x: i32,
    wheel_y: i32,
}

Mouse_state :: enum{
    Pressed,
    Released,
    Moved,
    Wheel,
}

Mouse_button :: enum{
    Unknown,
    Left,
    Right,
    Middle,
    X1,
    X2,
}

mouse_button_from_code :: [?]Mouse_button{
    Mouse_button.Unknown,
    Mouse_button.Left,
    Mouse_button.Middle,
    Mouse_button.Right,
    Mouse_button.X2,
    Mouse_button.X1,
}