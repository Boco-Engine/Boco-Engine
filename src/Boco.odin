package BocoEngine

import "core:log"

create_logger :: proc() -> (log.Logger) {
    LOGGER_OPTIONS :: log.Options{
        .Level,
        .Terminal_Color,
        .Short_File_Path,
        .Time,
        .Thread_Id
    }

    when ODIN_DEBUG {
        return log.create_console_logger(lowest = .Info, opt = LOGGER_OPTIONS)
    }

    // NOTE: In release probably want to log to a file (log.create_file_logger())
    return log.create_console_logger(lowest = .Error, opt = LOGGER_OPTIONS)
}

main :: proc() {
    context.logger = create_logger()

    engine : Engine

    ok := init_engine(&engine)
    if !ok {
        log.error("Failed initialising engine")
        return 
    }

    run_engine(&engine)

    cleanup_engine(&engine)
}