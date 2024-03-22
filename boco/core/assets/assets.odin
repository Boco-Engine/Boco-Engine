package assets

import "core:os"
import "core:strings"
import "core:log"
import "core:path/filepath"

ASSETS_PATH :: #config(ASSETS_PATH, "Assets/")

exists :: proc(path: string) -> bool {
    return os.exists(strings.join({ASSETS_PATH, path}, ""))
}

read_file :: proc(rel_path: string) -> ([]byte, bool) {
    log.info("Reading asset file: ", rel_path);

    path := strings.join({ASSETS_PATH, rel_path}, "")
    if !os.exists(path) do return nil, false
    return os.read_entire_file(path, context.allocator)
}

get_files_by_regex ::proc(regex: string) -> ([]string, bool) {
    file_path := strings.join({ASSETS_PATH, regex}, "")
    files, ok := filepath.glob(file_path)
    defer(delete(files))

    if ok != .None {
        return {}, false
    }

    files_rel := make([]string, len(files))

    for file, i in files {
        files_rel[i] = file[len(ASSETS_PATH):]
    }

    return files_rel, true
    
}