package BocoEngine

import "core:fmt"
import "core:log"
import "boco_core/boco_renderer"
import "boco_core/boco_window"
import "core:runtime"
import "core:time"
import "benchmarks"

Engine :: struct {
    running : bool,

    window : boco_window.Window,
    renderer : boco_renderer.Renderer,
}

init_engine :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
    }

    boco_window.init_window(&window) or_return
    renderer.main_window = &window
    boco_renderer.init_renderer(&renderer) or_return

    // TODO: Need a game loop, where we can init, update, and cleanup game resources.
    // LOAD MESH
    mesh := new(boco_renderer.IndexedMesh)
    water := new(boco_renderer.IndexedMesh)
    mesh_err : bool
    log.error("MESH HERE")
    mesh^, mesh_err = boco_renderer.read_bocom_mesh("planet.bocom")

    mesh.push_constant.mvp = matrix[4, 4]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    }

    // CREATE VERTEX BUFFER
    boco_renderer.allocate_buffer(&renderer, boco_renderer.Vertex, auto_cast len(mesh.vertex_data), {.VERTEX_BUFFER}, &mesh.vertex_buffer_resource)
    boco_renderer.write_to_buffer(&renderer, &mesh.vertex_buffer_resource, mesh.vertex_data, 0)
    // CREATE INDEX BUFFER
    boco_renderer.allocate_buffer(&renderer, u32, auto_cast len(mesh.index_data), {.INDEX_BUFFER}, &mesh.index_buffer_resource)
    boco_renderer.write_to_buffer(&renderer, &mesh.index_buffer_resource, mesh.index_data, 0)
    // ADD TO DRAW LIST
    boco_renderer.add_mesh(&renderer, mesh)
    // TODO: Add a cleanup_mesh function for deleting all mesh resources.

    // WATER
    // water^, mesh_err = boco_renderer.read_bocom_mesh("water.bocom")

    // for index in 0..<len(water.vertex_data) {
    //     water.vertex_data[index].normal = {0, 0, 1}
    // }

    // boco_renderer.allocate_buffer(&renderer, boco_renderer.Vertex, auto_cast len(water.vertex_data), {.VERTEX_BUFFER}, &water.vertex_buffer_resource)
    // boco_renderer.write_to_buffer(&renderer, &water.vertex_buffer_resource, water.vertex_data, 0)
    
    // boco_renderer.allocate_buffer(&renderer, u32, auto_cast len(water.index_data), {.INDEX_BUFFER}, &water.index_buffer_resource)
    // boco_renderer.write_to_buffer(&renderer, &water.index_buffer_resource, water.index_data, 0)

    // boco_renderer.add_mesh(&renderer, water)
    // TODO: ^

    running = true
    return true
}

run_engine :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        running &= boco_window.update_window(&window)
        running &= boco_renderer.update(&renderer)
        boco_renderer.record_to_command_buffer(&renderer)
        boco_renderer.submit_render(&renderer)
    }
}

cleanup_engine :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup_window(&window)
    boco_renderer.cleanup_renderer(&renderer)
}