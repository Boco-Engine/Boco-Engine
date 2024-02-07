package BocoEngine

import "core:fmt"
import "core:log"
import "boco_core/boco_renderer"
import "boco_core/boco_window"
import "core:runtime"
import "core:time"
import "benchmarks"
import sdl "vendor:sdl2"
import "core:math"

Engine :: struct {
    running : bool,

    window : boco_window.Window,
    renderer : boco_renderer.Renderer,
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

init_engine :: proc(using engine: ^Engine) -> (ok: bool = false) {
    log.info("Started Boco Engine")

    engine.renderer.enabled_features = {
        .geometryShader, 
        .tessellationShader,
    }

    boco_window.init(&window) or_return
    renderer.main_window = &window
    boco_renderer.init(&renderer) or_return

    renderer.scenes = make([dynamic]boco_renderer.Scene, 1)

    renderer.scenes[0].name = "Main Scene"
    renderer.scenes[0].window = window
    
    renderer.scenes[0].view_area = boco_window.ViewArea {
        x = 0,
        y = 0,
        width = cast(f32)window.width,
        height = cast(f32)window.height,
    }

    renderer.scenes[0].camera = boco_renderer.make_camera(100, cast(f32)renderer.scenes[0].view_area.width / cast(f32)renderer.scenes[0].view_area.height)

    renderer.scenes[0].clear_value = {0.1, 0.2, 0.1, 1.0}

    // TODO: Need a game loop, where we can init, update, and cleanup game resources.
    // LOAD MESH
    renderer.scenes[0].static_meshes = make([]^boco_renderer.IndexedMesh, 20)
    renderer.scenes[0].static_meshes[0] = init_mesh(&renderer, "planet/lod0-chunk-0.bocom")
    renderer.scenes[0].static_meshes[1] = init_mesh(&renderer, "planet/lod0-chunk-1.bocom")
    renderer.scenes[0].static_meshes[2] = init_mesh(&renderer, "planet/lod0-chunk-2.bocom")
    renderer.scenes[0].static_meshes[3] = init_mesh(&renderer, "planet/lod0-chunk-3.bocom")
    renderer.scenes[0].static_meshes[4] = init_mesh(&renderer, "planet/lod0-chunk-4.bocom")
    renderer.scenes[0].static_meshes[5] = init_mesh(&renderer, "planet/lod0-chunk-5.bocom")
    renderer.scenes[0].static_meshes[6] = init_mesh(&renderer, "planet/lod0-chunk-6.bocom")
    renderer.scenes[0].static_meshes[7] = init_mesh(&renderer, "planet/lod0-chunk-7.bocom")
    renderer.scenes[0].static_meshes[8] = init_mesh(&renderer, "planet/lod0-chunk-8.bocom")
    renderer.scenes[0].static_meshes[9] = init_mesh(&renderer, "planet/lod0-chunk-9.bocom")
    renderer.scenes[0].static_meshes[10] = init_mesh(&renderer, "planet/lod0-chunk-10.bocom")
    renderer.scenes[0].static_meshes[11] = init_mesh(&renderer, "planet/lod0-chunk-11.bocom")
    renderer.scenes[0].static_meshes[12] = init_mesh(&renderer, "planet/lod0-chunk-12.bocom")
    renderer.scenes[0].static_meshes[13] = init_mesh(&renderer, "planet/lod0-chunk-13.bocom")
    renderer.scenes[0].static_meshes[14] = init_mesh(&renderer, "planet/lod0-chunk-14.bocom")
    renderer.scenes[0].static_meshes[15] = init_mesh(&renderer, "planet/lod0-chunk-15.bocom")
    renderer.scenes[0].static_meshes[16] = init_mesh(&renderer, "planet/lod0-chunk-16.bocom")
    renderer.scenes[0].static_meshes[17] = init_mesh(&renderer, "planet/lod0-chunk-17.bocom")
    renderer.scenes[0].static_meshes[18] = init_mesh(&renderer, "planet/lod0-chunk-18.bocom")
    renderer.scenes[0].static_meshes[19] = init_mesh(&renderer, "planet/lod0-chunk-19.bocom")

    running = true
    return true
}

run :: proc(using engine: ^Engine) {
    log.info("Running Engine main loop")
    for running {
        key_pressed : sdl.Scancode
        running &= boco_window.update(&window)
        running &= boco_renderer.update(&renderer)
        boco_renderer.record_to_command_buffer(&renderer)
        boco_renderer.submit_render(&renderer)

        for mesh in &renderer.scenes[0].static_meshes {
            mesh.push_constant.m *= matrix[4, 4]f32 {
                math.cos_f32(0.001), 0, -math.sin_f32(0.001), 0,
                0, 1, 0, 0,
                math.sin_f32(0.001), 0, math.cos_f32(0.001), 0,
                0, 0, 0, 1
            }
        }
    }
}

cleanup :: proc(using engine: ^Engine) {
    log.info("Exiting Boco Engine")
    boco_window.cleanup(&window)
    boco_renderer.cleanup_renderer(&renderer)
}