package BocoEngine

import "core:log"
import "core:fmt"
import "core:os"

GRAPHICS_API :: #config(GRAPHICS_API, "vulkan")
LOG_LEVEL :: #config(LOG_LEVEL, 0)

create_logger :: proc() -> (log.Logger) {
    DEBUG_LOGGER_OPTIONS :: log.Options{
        .Level,
        .Terminal_Color,
        .Short_File_Path,
        .Line,
        .Time,
        .Procedure,
        .Thread_Id,
    }

    LOGGER_OPTIONS :: log.Options{
        .Level,
        .Short_File_Path,
        .Line,
        .Time,
        .Procedure,
        .Thread_Id,
    }

    when ODIN_DEBUG {
        return log.create_console_logger(lowest = cast(log.Level)LOG_LEVEL, opt = DEBUG_LOGGER_OPTIONS)
    }

    os.make_directory("temp")
    os.make_directory("temp/logs")
    handle, ok := os.open("temp/logs/temp_log.txt", (os.O_CREATE|os.O_TRUNC))
    return log.create_file_logger(handle, lowest = cast(log.Level)LOG_LEVEL, opt = LOGGER_OPTIONS)
}