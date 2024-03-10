package ecs_core

// TODO: Rename this package to something better.

import "core:math"

import vk "vendor:vulkan"

import boco "boco:core"
import "boco:core/ecs"
import "boco:core/renderer"
import "boco:core/types"
import "boco:core/window"

RenderMeshAction :: proc(engine_ptr: rawptr, world: ^ecs.ECS, system: ^ecs.System) {
    engine := cast(^boco.Engine)engine_ptr
    scene := engine.scenes[0]
    using engine.main_renderer
    cmd_buffer := command_buffers[current_frame_index]

    // DESIGN: Local coordinate system. How where and what?
    // HACK: This should be set somewhere sensible.
    base_node_f := scene.camera.position / engine.node_info.size
    base_node := [3]f64{math.floor_f64(base_node_f.x), math.floor_f64(base_node_f.y), math.floor_f64(base_node_f.z)}
    camera_pos := boco.to_local(engine, scene.camera.position)
    camera_pos_abs := engine.scenes[0].camera.position
    
    view_area := window.ViewArea{0, 0, cast(f32)engine.main_window.width, cast(f32)engine.main_window.height}
    
    renderer.begin_render(&engine.main_renderer, view_area)
    vk.CmdBindPipeline(cmd_buffer, .GRAPHICS, engine.main_renderer.graphics_pipeline)
    renderer.update_descriptor_sets(&engine.main_renderer, types.Mat4{}, types.Mat4{}, engine.scenes[0].camera.projectionMatrix, [3]f32{cast(f32)camera_pos_abs.x, cast(f32)camera_pos_abs.y, cast(f32)camera_pos_abs.z}, engine.main_renderer.current_frame_index)

    for entity in system.entities {
        mesh_component := ecs.get_component(world, MeshComponent, entity)
        transform := ecs.get_component(world, Transform, entity)
        pos_f64 := transform.position - (base_node * engine.node_info.size)
        pos_f32 := [3]f32{cast(f32)pos_f64.x, cast(f32)pos_f64.y, cast(f32)pos_f64.z}

        mesh_ptr := engine.main_renderer.meshes[mesh_component.id]

        mvp := mesh_ptr.push_constant

        mvp.m *= matrix[4, 4]f32 {
            math.cos_f32(transform.rotation.y), 0, -math.sin_f32(transform.rotation.y), 0,
            0, 1, 0, 0,
            math.sin_f32(transform.rotation.y), 0, math.cos_f32(transform.rotation.y), 0,
            0, 0, 0, 1,
        }

        mvp.m *= matrix[4, 4]f32 {
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            pos_f32.x, pos_f32.y, pos_f32.z, 1,
        }

        offsets := [?]vk.DeviceSize{0}

        mvp.mvp = mvp.m
        mvp.mvp *= renderer.get_view_matrix_at_position(&scene.camera, [3]f32{cast(f32)camera_pos.x, cast(f32)camera_pos.y, cast(f32)camera_pos.z})
        mvp.mvp *= scene.camera.projectionMatrix
        
        vk.CmdBindDescriptorSets(cmd_buffer, .GRAPHICS, pipeline_layout, 0, 1, &descriptor_sets[current_frame_index], 0, nil)

        vk.CmdPushConstants(cmd_buffer, pipeline_layout, {.VERTEX}, 0, size_of(renderer.PushConstant), &mvp)

        vk.CmdBindVertexBuffers(cmd_buffer, 0, 1, &mesh_ptr.vertex_buffer_resource.buffer, &offsets[0])
        vk.CmdBindIndexBuffer(cmd_buffer, mesh_ptr.index_buffer_resource.buffer, 0, .UINT32)

        vk.CmdDrawIndexed(cmd_buffer, cast(u32)len(mesh_ptr.index_data), 1, 0, 0, 0)
    }
    renderer.end_render(&engine.main_renderer, view_area)
}