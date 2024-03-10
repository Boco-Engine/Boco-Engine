package window

import "boco:core/event_data"
import "boco:core/input"

Window_event :: struct{
    window: ^Window,
    state: Window_state,
    propagate_to_parent: bool,
    event_handled: bool,
}

Window_state :: enum{
    Quit,
    Resize,
    Focus,
    Unfocus,
    Move,
    Minimize,
    Maximize,
    Restore,
    Enter,
    Leave,
    Key,
    Mouse,
}