package boco_window

import "core:log"

Window :: struct {
    // Some shit
    width: u32,
    height: u32,
}

init_window :: proc() -> (ok: bool = true) {
    log.info("Initialising Window")

    return
}

cleanup_window :: proc() {
    log.info("Cleaning window resources")
}