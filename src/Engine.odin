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
    scenes: [dynamic]boco_renderer.Scene(5000), // Need to pass the amount of max entities for each entity, need to change, dont want menu having same as the game.
}

init_mesh :: proc(renderer: ^boco_renderer.Renderer, file: string) -> ^boco_renderer.IndexedMesh {
    mesh := new(boco_renderer.IndexedMesh)
    mesh_err : bool
    mesh^, mesh_err = boco_renderer.read_bocom_mesh(file)

    mesh.push_constant.m = matrix[4, 4]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }

    // CREATE VERTEX BUFFER
    boco_renderer.allocate_buffer(renderer, boco_renderer.Vertex, auto_cast len(mesh.vertex_data), {.VERTEX_BUFFER}, &mesh.vertex_buffer_resource)
    boco_renderer.write_to_buffer(renderer, &mesh.vertex_buffer_resource, mesh.vertex_data, 0)
    // CREATE INDEX BUFFER
    boco_renderer.allocate_buffer(renderer, u32, auto_cast len(mesh.index_data), {.INDEX_BUFFER}, &mesh.index_buffer_resource)
    boco_renderer.write_to_buffer(renderer, &mesh.index_buffer_resource, mesh.index_data, 0)
    // ADD TO DRAW LIST
    return mesh
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

Render :: proc(using engine: ^Engine) -> (ok: bool = true) {
    ok &= boco_renderer.update(&renderer)
    // TODO: Currenly just renders all scenes, i think we want render to be called per scene!
    boco_renderer.render_scene(&renderer, scenes[0], {0, 0, cast(f32)window.width, cast(f32)window.height})
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

        // Rotate planet
        // for mesh in &renderer.scenes[0].static_meshes {
        //     mesh.push_constant.mvp *= matrix[4, 4]f32 {
        //         math.cos_f32(0.001), 0, -math.sin_f32(0.001), 0,
        //         0, 1, 0, 0,
        //         math.sin_f32(0.001), 0, math.cos_f32(0.001), 0,
        //         0, 0, 0, 1,
        //     }
        // }
    }
}

shutdown :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup(&window)
    boco_renderer.cleanup_renderer(&renderer)
}