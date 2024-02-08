package BocoEngine

import "core:fmt"
import "core:log"
import "boco_core/boco_renderer"
import "boco_core/boco_window"
import "boco_core"
import "core:runtime"
import "core:time"
import "benchmarks"
import sdl "vendor:sdl2"
import "core:math"
import "vendor:microui"

Engine :: struct {
    running : bool,

    window : boco_window.Window,
    renderer : boco_renderer.Renderer,
    scenes: [dynamic]boco_renderer.Scene, // Need to pass the amount of max entities for each entity, need to change, dont want menu having same as the game.
}

init :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
    }

    boco_window.init(&window) or_return
    renderer.main_window = &window
    boco_renderer.init(&renderer) or_return

    // TODO: Need a game loop, where we can init, update, and cleanup game resources.
    boco_renderer.init_ui(&renderer)

    running = true
    return true
}

HandleInputs :: proc(using engine: ^Engine) -> (ok: bool = true) {
    ok &= boco_window.update(&window)
    return
}

UpdatePhysics :: proc(using engine: ^Engine) -> (ok: bool = true) {
    return
}

RenderScene :: proc(using engine: ^Engine, scene: boco_renderer.Scene, view_area: boco_window.ViewArea) -> (ok: bool = true) {
    // boco_renderer.render_scene(&renderer, scene, view_area)

    // RenderMeshAction(engine, scene.ecs, )

    return
} 

RenderFrame :: proc(using engine: ^Engine) -> (ok: bool = true) {
    ok &= boco_renderer.update(&renderer)
    boco_renderer.submit_render(&renderer)
    return
}

// This is no longer needed move to using Individual procedures above in own loop.
@(deprecated="No longer used. Use the individual render, update, and input procedures to call from the games loop.")
run :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        key_pressed : sdl.Scancode
        running &= boco_window.update(&window)
        running &= boco_renderer.update(&renderer)

        // TODO: Move this to its own thing, and implement it all.
        microui.begin(&renderer.ui_context)

        if microui.window(&renderer.ui_context, "Test", {10, 10, 400, 400}) {
            // microui.button(&renderer.ui_context, "Button")

            // microui.end_window(&renderer.ui_context)
        }

        microui.end(&renderer.ui_context)

        cmd: ^microui.Command
        for (microui.next_command(&renderer.ui_context, &cmd)) {
            switch _ in cmd.variant {
                case ^microui.Command_Text:
                    // TODO: Add text rendering
                    
                case ^microui.Command_Rect:
                    // TODO: Add rext rendering
                    
                case ^microui.Command_Icon:
                    // TODO: Add icon rendering
                    
                case ^microui.Command_Clip:
                    // TODO: Add clipping
                    
                case ^microui.Command_Jump:
                    // TODO: Find out what this is
                    
            }
        }
    }
}

shutdown :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup(&window)
    boco_renderer.cleanup_renderer(&renderer)
}