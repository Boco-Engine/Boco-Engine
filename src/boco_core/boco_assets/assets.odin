package boco_assets

import "core:os"
import "core:strings"
import "core:log"
import "core:path/filepath"

ASSETS_PATH :: #config(ASSETS_PATH, "Assets/")

asset_exists :: proc(path: string) -> bool {
    return os.exists(strings.join({ASSETS_PATH, path}, ""))
}