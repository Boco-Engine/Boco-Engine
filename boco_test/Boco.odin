package boco_test

import boco "../src"
import "../src/boco_core/boco_renderer"
import "../src/boco_core/boco_window"
import "../src/boco_core/boco_ecs"
import "core:log"
import "core:fmt"
import "core:os"

setup_test :: proc(engine: ^boco.Engine) {
    append(&engine.scenes, boco_renderer.Scene{})
    engine.scenes[0].name = "Test Scene"
    engine.scenes[0].camera = boco_renderer.make_camera(90, cast(f32)engine.window.width / cast(f32)engine.window.height)
}

run_test :: proc(engine: ^boco.Engine) {
    running := true

    for running {
        running &= boco.HandleInputs(engine)
        running &= boco.UpdatePhysics(engine)
        running &= boco.RenderScene(engine, engine.scenes[0], {0, 0, cast(f32)engine.window.width, cast(f32)engine.window.height})
        
        view_area := boco_window.ViewArea{0, 0, cast(f32)engine.window.width, cast(f32)engine.window.height}
        boco_renderer.begin_render(&engine.renderer, view_area)
        boco_ecs.update(cast(^any)engine, &engine.scenes[0].ecs)
        boco_renderer.end_render(&engine.renderer, view_area)
    }
}

main :: proc() {
    context.logger = boco.create_logger()
    defer log.destroy_console_logger(context.logger)

    engine : boco.Engine

    if !boco.init(&engine) {
        log.error("Failed initialising engine")
        return 
    }

    setup_test(&engine)
    run_test(&engine)

    boco.shutdown(&engine)
}