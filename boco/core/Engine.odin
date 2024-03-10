package core

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:time"
import "core:math"

import sdl "vendor:sdl2"
import "vendor:microui"

import "boco:core/renderer"
import "boco:core/window"
import "boco:benchmarks"

NodeInfo :: struct {
    size: f64,
}

Engine :: struct {
    running : bool,

    main_window : window.Window,
    main_renderer : renderer.Renderer,
    scenes: [dynamic]renderer.Scene, // Need to pass the amount of max entities for each entity, need to change, dont want menu having same as the game.

    node_info: NodeInfo,
    logger: log.Logger,
}

// TODO: Find a relavant place for all local coordinate system functions
to_local :: proc(engine: ^Engine, position: [3]f64) -> [3]f32 {
    base_node_f := position / engine.node_info.size
    base_node := [3]f64{math.floor_f64(base_node_f.x), math.floor_f64(base_node_f.y), math.floor_f64(base_node_f.z)}
    val := (base_node_f - base_node) * engine.node_info.size
    return [3]f32{cast(f32)val.x, cast(f32)val.y, cast(f32)val.z}
}

init :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.main_renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
        .shaderf64,
        .anisotropy,
    }

    window.init(&main_window) or_return
    main_renderer.main_window = &main_window
    renderer.init(&main_renderer) or_return

    // TODO: Need a game loop, where we can init, update, and cleanup game resources.
    renderer.init_ui(&main_renderer)

    running = true
    return true
}

HandleInputs :: proc(using engine: ^Engine) -> (ok: bool = true) {
    ok &= window.update(&main_window)
    return
}

UpdatePhysics :: proc(using engine: ^Engine) -> (ok: bool = true) {
    return
}

RenderScene :: proc(using engine: ^Engine, scene: renderer.Scene, view_area: window.ViewArea) -> (ok: bool = true) {
    // renderer.render_scene(&renderer, scene, view_area)

    // RenderMeshAction(engine, scene.ecs, )

    return
} 

RenderFrame :: proc(using engine: ^Engine) -> (ok: bool = true) {
    ok &= renderer.update(&main_renderer)
    return
}

shutdown :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    window.cleanup(&main_window)
    renderer.cleanup_renderer(&main_renderer)
}