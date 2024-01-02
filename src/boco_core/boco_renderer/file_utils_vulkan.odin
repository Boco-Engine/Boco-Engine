package boco_renderer

import "core:os"
import "core:strings"
import "core:log"

make_file_path :: proc(folder : string, file : string) -> (path : string) {
    builder := strings.builder_make(0, len(folder) + len(file) + 1)
    strings.write_string(&builder, folder)
    strings.write_string(&builder, "/")
    strings.write_string(&builder, file)
    return strings.to_string(builder)
}

read_spirv :: proc(file_name : string) -> (code : []u8, err : bool = true) {
    path : string = make_file_path("Shaders/compiled", file_name)

    file_contents, ok := os.read_entire_file(path, context.allocator)

    if (!ok) {
        log.error("Failed to read file:", file_name)
        return {}, false
    }
    log.info("Successfully read file:", file_name)

    return file_contents, err
}