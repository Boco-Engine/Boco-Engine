package event_data

Key_event :: struct{
    key: Key,
    state: Key_state,
}

Key :: struct{
    code: u32,
    name: Key_name,
    hold_time: f32,
}

Key_state :: enum{
    Released,
    Pressed,
    Held,
    Moved,
    Wheel,
    Unknown
}

Key_name :: enum{
    Unknown,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    Num1,
    Num2,
    Num3,
    Num4,
    Num5,
    Num6,
    Num7,
    Num8,
    Num9,
    Num0,
    Enter,
    Escape,
    Backspace,
    Tab,
    Space,
    Minus,
    Equal,
    LeftBracket,
    RightBracket,
    Backslash,
    Nonushash,
    Semicolon,
    Apostrophe,
    Grave,
    Comma,
    Period,
    Slash,
    CapsLock,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    PrintScreen,
    ScrollLock,
    Pause,
    Insert,
    Home,
    PageUp,
    Delete,
    End,
    PageDown,
    Right,
    Left,
    Down,
    Up,
    NumLockClear,
    KeypadDivide,
    KeypadMultiply,
    KeypadMinus,
    KeypadPlus,
    KeypadEnter,
    Keypad1,
    Keypad2,
    Keypad3,
    Keypad4,
    Keypad5,
    Keypad6,
    Keypad7,
    Keypad8,
    Keypad9,
    Keypad0,
    KeypadPeriod,
    NonusBackslash,
    Application,
    Power,
    KeypadEquals,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    F21,
    F22,
    F23,
    F24,
    Execute,
    Help,
    Menu,
    Select,
    Stop,
    Again,
    Undo,
    Cut,
    Copy,
    Paste,
    Find,
    Mute,
    VolumeUp,
    VolumeDown,
    KeypadComma,
    KeypadEqualsAS400,
    International1,
    International2,
    International3,
    International4,
    International5,
    International6,
    International7,
    International8,
    International9,
    Lang1,
    Lang2,
    Lang3,
    Lang4,
    Lang5,
    Lang6,
    Lang7,
    Lang8,
    Lang9,
    AlternateErase,
    SysReq,
    Cancel,
    Clear,
    Prior,
    Return2,
    Separator,
    Out,
    Oper,
    ClearAgain,
    Crsel,
    Exsel,
    Keypad00,
    Keypad000,
    ThousandsSeparator,
    DecimalSeparator,
    CurrencyUnit,
    CurrencySubUnit,
    KeypadLeftParen,
    KeypadRightParen,
    KeypadLeftBrace,
    KeypadRightBrace,
    KeypadTab,
    KeypadBackspace,
    KeypadA,
    KeypadB,
    KeypadC,
    KeypadD,
    KeypadE,
    KeypadF,
    KeypadXor,
    KeypadPower,
    KeypadPercent,
    KeypadLess,
    KeypadGreater,
    KeypadAmpersand,
    KeypadDblAmpersand,
    KeypadVerticalBar,
    KeypadDblVerticalBar,
    KeypadColon,
    KeypadHash,
    KeypadSpace,
    KeypadAt,
    KeypadExclam,
    KeypadMemStore,
    KeypadMemRecall,
    KeypadMemClear,
    KeypadMemAdd,
    KeypadMemSubtract,
    KeypadMemMultiply,
    KeypadMemDivide,
    KeypadPlusMinus,
    KeypadClear,
    KeypadClearEntry,
    KeypadBinary,
    KeypadOctal,
    KeypadDecimal,
    KeypadHexadecimal,
    LeftControl,
    LeftShift,
    LeftAlt,
    LeftGUI,
    RightControl,
    RightShift,
    RightAlt,
    RightGUI,
    Mode,
    AudioNext,
    AudioPrev,
    AudioStop,
    AudioPlay,
    AudioMute,
    MediaSelect,
    WWW,
    Mail,
    Calculator,
    Computer,
    ACSearch,
    ACHome,
    ACBack,
    ACForward,
    ACStop,
    ACRefresh,
    ACBookmarks,
    BrightnessDown,
    BrightnessUp,
    DisplaySwitch,
    KBDIllumToggle,
    KBDIllumDown,
    KBDIllumUp,
    Eject,
    Sleep,
    App1,
    App2
}

key_name_from_code :: [?]Key_name{
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.A,
    Key_name.B,
    Key_name.C,
    Key_name.D,
    Key_name.E,
    Key_name.F,
    Key_name.G,
    Key_name.H,
    Key_name.I,
    Key_name.J,
    Key_name.K,
    Key_name.L,
    Key_name.M,
    Key_name.N,
    Key_name.O,
    Key_name.P,
    Key_name.Q,
    Key_name.R,
    Key_name.S,
    Key_name.T,
    Key_name.U,
    Key_name.V,
    Key_name.W,
    Key_name.X,
    Key_name.Y,
    Key_name.Z,
    Key_name.Num1,
    Key_name.Num2,
    Key_name.Num3,
    Key_name.Num4,
    Key_name.Num5,
    Key_name.Num6,
    Key_name.Num7,
    Key_name.Num8,
    Key_name.Num9,
    Key_name.Num0,
    Key_name.Enter,
    Key_name.Escape,
    Key_name.Backspace,
    Key_name.Tab,
    Key_name.Space,
    Key_name.Minus,
    Key_name.Equal,
    Key_name.LeftBracket,
    Key_name.RightBracket,
    Key_name.Backslash,
    Key_name.Nonushash,
    Key_name.Semicolon,
    Key_name.Apostrophe,
    Key_name.Grave,
    Key_name.Comma,
    Key_name.Period,
    Key_name.Slash,
    Key_name.CapsLock,
    Key_name.F1,
    Key_name.F2,
    Key_name.F3,
    Key_name.F4,
    Key_name.F5,
    Key_name.F6,
    Key_name.F7,
    Key_name.F8,
    Key_name.F9,
    Key_name.F10,
    Key_name.F11,
    Key_name.F12,
    Key_name.PrintScreen,
    Key_name.ScrollLock,
    Key_name.Pause,
    Key_name.Insert,
    Key_name.Home,
    Key_name.PageUp,
    Key_name.Delete,
    Key_name.End,
    Key_name.PageDown,
    Key_name.Right,
    Key_name.Left,
    Key_name.Down,
    Key_name.Up,
    Key_name.NumLockClear,
    Key_name.KeypadDivide,
    Key_name.KeypadMultiply,
    Key_name.KeypadMinus,
    Key_name.KeypadPlus,
    Key_name.KeypadEnter,
    Key_name.Keypad1,
    Key_name.Keypad2,
    Key_name.Keypad3,
    Key_name.Keypad4,
    Key_name.Keypad5,
    Key_name.Keypad6,
    Key_name.Keypad7,
    Key_name.Keypad8,
    Key_name.Keypad9,
    Key_name.Keypad0,
    Key_name.KeypadPeriod,
    Key_name.NonusBackslash,
    Key_name.Application,
    Key_name.Power,
    Key_name.KeypadEquals,
    Key_name.F13,
    Key_name.F14,
    Key_name.F15,
    Key_name.F16,
    Key_name.F17,
    Key_name.F18,
    Key_name.F19,
    Key_name.F20,
    Key_name.F21,
    Key_name.F22,
    Key_name.F23,
    Key_name.F24,
    Key_name.Execute,
    Key_name.Help,
    Key_name.Menu,
    Key_name.Select,
    Key_name.Stop,
    Key_name.Again,
    Key_name.Undo,
    Key_name.Cut,
    Key_name.Copy,
    Key_name.Paste,
    Key_name.Find,
    Key_name.Mute,
    Key_name.VolumeUp,
    Key_name.VolumeDown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.KeypadComma,
    Key_name.KeypadEqualsAS400,
    Key_name.International1,
    Key_name.International2,
    Key_name.International3,
    Key_name.International4,
    Key_name.International5,
    Key_name.International6,
    Key_name.International7,
    Key_name.International8,
    Key_name.International9,
    Key_name.Lang1,
    Key_name.Lang2,
    Key_name.Lang3,
    Key_name.Lang4,
    Key_name.Lang5,
    Key_name.Lang6,
    Key_name.Lang7,
    Key_name.Lang8,
    Key_name.Lang9,
    Key_name.AlternateErase,
    Key_name.SysReq,
    Key_name.Cancel,
    Key_name.Clear,
    Key_name.Prior,
    Key_name.Return2,
    Key_name.Separator,
    Key_name.Out,
    Key_name.Oper,
    Key_name.ClearAgain,
    Key_name.Crsel,
    Key_name.Exsel,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Keypad00,
    Key_name.Keypad000,
    Key_name.ThousandsSeparator,
    Key_name.DecimalSeparator,
    Key_name.CurrencyUnit,
    Key_name.CurrencySubUnit,
    Key_name.KeypadLeftParen,
    Key_name.KeypadRightParen,
    Key_name.KeypadLeftBrace,
    Key_name.KeypadRightBrace,
    Key_name.KeypadTab,
    Key_name.KeypadBackspace,
    Key_name.KeypadA,
    Key_name.KeypadB,
    Key_name.KeypadC,
    Key_name.KeypadD,
    Key_name.KeypadE,
    Key_name.KeypadF,
    Key_name.KeypadXor,
    Key_name.KeypadPower,
    Key_name.KeypadPercent,
    Key_name.KeypadLess,
    Key_name.KeypadGreater,
    Key_name.KeypadAmpersand,
    Key_name.KeypadDblAmpersand,
    Key_name.KeypadVerticalBar,
    Key_name.KeypadDblVerticalBar,
    Key_name.KeypadColon,
    Key_name.KeypadHash,
    Key_name.KeypadSpace,
    Key_name.KeypadAt,
    Key_name.KeypadExclam,
    Key_name.KeypadMemStore,
    Key_name.KeypadMemRecall,
    Key_name.KeypadMemClear,
    Key_name.KeypadMemAdd,
    Key_name.KeypadMemSubtract,
    Key_name.KeypadMemMultiply,
    Key_name.KeypadMemDivide,
    Key_name.KeypadPlusMinus,
    Key_name.KeypadClear,
    Key_name.KeypadClearEntry,
    Key_name.KeypadBinary,
    Key_name.KeypadOctal,
    Key_name.KeypadDecimal,
    Key_name.KeypadHexadecimal,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.LeftControl,
    Key_name.LeftShift,
    Key_name.LeftAlt,
    Key_name.LeftGUI,
    Key_name.RightControl,
    Key_name.RightShift,
    Key_name.RightAlt,
    Key_name.RightGUI,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Unknown,
    Key_name.Mode,
    Key_name.AudioNext,
    Key_name.AudioPrev,
    Key_name.AudioStop,
    Key_name.AudioPlay,
    Key_name.AudioMute,
    Key_name.MediaSelect,
    Key_name.WWW,
    Key_name.Mail,
    Key_name.Calculator,
    Key_name.Computer,
    Key_name.ACSearch,
    Key_name.ACHome,
    Key_name.ACBack,
    Key_name.ACForward,
    Key_name.ACStop,
    Key_name.ACRefresh,
    Key_name.ACBookmarks,
    Key_name.BrightnessDown,
    Key_name.BrightnessUp,
    Key_name.DisplaySwitch,
    Key_name.KBDIllumToggle,
    Key_name.KBDIllumDown,
    Key_name.KBDIllumUp,
    Key_name.Eject,
    Key_name.Sleep,
    Key_name.App1,
    Key_name.App2,
}