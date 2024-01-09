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

add_mesh :: proc(renderer: ^boco_renderer.Renderer, file: string) {
    mesh := new(boco_renderer.IndexedMesh)
    mesh_err : bool
    mesh^, mesh_err = boco_renderer.read_bocom_mesh(file)

    mesh.push_constant.mvp = matrix[4, 4]f32{
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
    boco_renderer.add_mesh(renderer, mesh)
}

init_engine :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
    }

    boco_window.init(&window) or_return
    renderer.main_window = &window
    boco_renderer.init_renderer(&renderer) or_return

    // TODO: Need a game loop, where we can init, update, and cleanup game resources.
    // LOAD MESH
    add_mesh(&renderer, "planet/lod0-chunk-0.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-1.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-2.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-3.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-4.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-5.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-6.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-7.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-8.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-9.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-10.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-11.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-12.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-13.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-14.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-15.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-16.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-17.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-18.bocom")
    add_mesh(&renderer, "planet/lod0-chunk-19.bocom")
    // TODO: Add a cleanup_mesh function for deleting all mesh resources.

    running = true
    return true
}

run :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        running &= boco_window.update(&window)
        running &= boco_renderer.update(&renderer)
        boco_renderer.record_to_command_buffer(&renderer)
        boco_renderer.submit_render(&renderer)
    }
}

cleanup :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup(&window)
    boco_renderer.cleanup_renderer(&renderer)
}