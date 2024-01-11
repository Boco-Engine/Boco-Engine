package boco_renderer

import vk "vendor:vulkan"
import "core:log"
import "core:math"

record_to_command_buffer :: proc(using renderer: ^Renderer) {
    cmd_buffer := command_buffers[current_frame_index]

	fence_err := vk.WaitForFences(logical_device, 1, &in_flight[current_frame_index], true, 20000000)
	if fence_err != .SUCCESS do return

	image_index: u32
	err := vk.AcquireNextImageKHR(logical_device, swapchain, 100000000, image_available[current_frame_index], 0, &image_index)
	if err == .SUBOPTIMAL_KHR {
		on_resize(renderer)
		return
	}
	if err != .SUCCESS{
		return
	}
	
	vk.ResetFences(logical_device, 1, &in_flight[current_frame_index])

	begin_info: vk.CommandBufferBeginInfo
	begin_info.sType = .COMMAND_BUFFER_BEGIN_INFO

	vk.ResetCommandBuffer(cmd_buffer, {})
	vk.BeginCommandBuffer(cmd_buffer, &begin_info)
	{
		for scene in scenes {
			view_area := scene.view_area

			s := vk.Rect2D {
				vk.Offset2D {
					x = cast(i32)view_area.x,
					y = cast(i32)view_area.y,
				},
				vk.Extent2D {
					width = cast(u32)view_area.width,
					height = cast(u32)view_area.height,
				},
			}
	
			v := vk.Viewport {
				x =        view_area.x,
				y =        view_area.y,
				width =    view_area.width,
				height =   view_area.height,
				minDepth = viewport.minDepth,
				maxDepth = viewport.maxDepth,
			}
	
			// These can be constants
			clear_values : [2]vk.ClearValue
			clear_values[0].color.float32 = scene.clear_value
			clear_values[1].depthStencil.depth = 1.0
	
			render_pass_begin_info: vk.RenderPassBeginInfo
			render_pass_begin_info.sType = .RENDER_PASS_BEGIN_INFO
			render_pass_begin_info.renderPass = render_pass
			render_pass_begin_info.framebuffer = framebuffers[image_index]
			render_pass_begin_info.renderArea = s // NOTE: Dont actually need to keep scissor struct in renderer struct, can just use the window viewarea.
			render_pass_begin_info.clearValueCount = len(clear_values)
			render_pass_begin_info.pClearValues = &clear_values[0]
	
			vk.CmdBeginRenderPass(cmd_buffer, &render_pass_begin_info, .INLINE)
	
			vk.CmdSetScissor(cmd_buffer, 0, 1, &s)
			vk.CmdSetViewport(cmd_buffer, 0, 1, &v)
	
			vk.CmdBindPipeline(cmd_buffer, .GRAPHICS, graphics_pipeline)
	
			for mesh in scene.static_meshes {
	
				offsets := [?]vk.DeviceSize{0}
	
				mvp := mesh.push_constant.mvp
	
				mvp *= scene.camera.viewMatrix
				mvp *= scene.camera.projectionMatrix
	
				vk.CmdPushConstants(cmd_buffer, pipeline_layout, {.VERTEX}, 0, size_of(mvp), &mvp)
				vk.CmdBindVertexBuffers(cmd_buffer, 0, 1, &mesh.vertex_buffer_resource.buffer, &offsets[0])
				vk.CmdBindIndexBuffer(cmd_buffer, mesh.index_buffer_resource.buffer, 0, .UINT32)
	
				vk.CmdDrawIndexed(cmd_buffer, cast(u32)len(mesh.index_data), 1, 0, 0, 0)
			}
	
			vk.CmdEndRenderPass(cmd_buffer)
		}
	}
	vk.EndCommandBuffer(cmd_buffer)


	wait_mask: vk.PipelineStageFlags = {.COLOR_ATTACHMENT_OUTPUT}

	submit_info: vk.SubmitInfo
	submit_info.sType = .SUBMIT_INFO
	submit_info.pWaitDstStageMask = &wait_mask
	submit_info.waitSemaphoreCount = 1
	submit_info.pWaitSemaphores = &image_available[current_frame_index]
	submit_info.commandBufferCount = 1
	submit_info.pCommandBuffers = &cmd_buffer
	submit_info.signalSemaphoreCount = 1
	submit_info.pSignalSemaphores = &render_finished[current_frame_index]

	vk.QueueSubmit(queues[.GRAPHICS], 1, &submit_info, in_flight[current_frame_index])

	present_info: vk.PresentInfoKHR
	present_info.sType = .PRESENT_INFO_KHR
	present_info.waitSemaphoreCount = 1
	present_info.pWaitSemaphores = &render_finished[current_frame_index]
	present_info.swapchainCount = 1
	present_info.pSwapchains = &swapchain
	present_info.pImageIndices = &image_index

	present_err := vk.QueuePresentKHR(queues[.GRAPHICS], &present_info)
	if present_err != .SUCCESS {
		on_resize(renderer)
		current_frame_index = 0
		return
	}

	current_frame_index += 1
	current_frame_index %= swapchain_settings.image_count
}

submit_render :: proc(using renderer: ^Renderer) {


}

destroy_mesh :: proc(using renderer: ^Renderer, mesh: ^IndexedMesh) {
	vk.FreeMemory(logical_device, mesh.index_buffer_resource.memory, nil)
	vk.DestroyBuffer(logical_device, mesh.index_buffer_resource.buffer, nil)
	delete(mesh.index_data)
	
	vk.FreeMemory(logical_device, mesh.vertex_buffer_resource.memory, nil)
	vk.DestroyBuffer(logical_device, mesh.vertex_buffer_resource.buffer, nil)
	delete(mesh.vertex_data)
}

wait_on_api :: proc(using renderer: ^Renderer) {
	vk.DeviceWaitIdle(logical_device)
}