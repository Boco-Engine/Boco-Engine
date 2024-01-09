package boco_renderer

import vk "vendor:vulkan"
import "core:log"
import "core:math"

record_to_command_buffer :: proc(using renderer: ^Renderer) {
    cmd_buffer := command_buffers[current_frame_index]


	image_index: u32
	err := vk.AcquireNextImageKHR(logical_device, swapchain, 0, image_available[current_frame_index], 0, &image_index)
	if err != .SUCCESS{
		return
	}

	if vk.WaitForFences(logical_device, 1, &in_flight[current_frame_index], true, 0) != .SUCCESS do return
	vk.ResetFences(logical_device, 1, &in_flight[current_frame_index])

	begin_info: vk.CommandBufferBeginInfo
	begin_info.sType = .COMMAND_BUFFER_BEGIN_INFO

	vk.ResetCommandBuffer(cmd_buffer, {})
	vk.BeginCommandBuffer(cmd_buffer, &begin_info)
	{
		// These can be constants
        clear_values : [2]vk.ClearValue
        clear_values[0].color.float32 = [4]f32{0.1, 0.1, 0.1, 1}
		clear_values[1].depthStencil.depth = 1.0

		render_pass_begin_info: vk.RenderPassBeginInfo
		render_pass_begin_info.sType = .RENDER_PASS_BEGIN_INFO
		render_pass_begin_info.renderPass = render_pass
		render_pass_begin_info.framebuffer = framebuffers[image_index]
		render_pass_begin_info.renderArea = scissor // NOTE: Dont actually need to keep scissor struct in renderer struct, can just use the window viewarea.
		render_pass_begin_info.clearValueCount = len(clear_values)
		render_pass_begin_info.pClearValues = &clear_values[0]

		vk.CmdBeginRenderPass(cmd_buffer, &render_pass_begin_info, .INLINE)

		vk.CmdSetScissor(cmd_buffer, 0, 1, &scissor)
		vk.CmdSetViewport(cmd_buffer, 0, 1, &viewport)

		vk.CmdBindPipeline(cmd_buffer, .GRAPHICS, graphics_pipeline)

		for mesh in indexed_meshes {
			offsets := [?]vk.DeviceSize{0}

			// TODO: Need camera for projection and view matrices.
			mvp := mesh.push_constant.mvp

			mvp *= Mat4{
				math.cos_f32(0.001), 0, -math.sin_f32(0.001), 0,
				0, 1, 0, 0,
				math.sin_f32(0.001), 0, math.cos_f32(0.001), 0,
				0, 0, 0, 1,
			}

			mesh.push_constant.mvp = mvp

			mvp *= camera.viewMatrix
			mvp *= camera.projectionMatrix

			vk.CmdPushConstants(cmd_buffer, pipeline_layout, {.VERTEX}, 0, size_of(mvp), &mvp)
			vk.CmdBindVertexBuffers(cmd_buffer, 0, 1, &mesh.vertex_buffer_resource.buffer, &offsets[0])
			vk.CmdBindIndexBuffer(cmd_buffer, mesh.index_buffer_resource.buffer, 0, .UINT32)

			vk.CmdDrawIndexed(cmd_buffer, cast(u32)len(mesh.index_data), 1, 0, 0, 0)
		}

		vk.CmdEndRenderPass(cmd_buffer)
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

	if vk.QueuePresentKHR(queues[.GRAPHICS], &present_info) != .SUCCESS {
		// TODO: Check if need resize and resize.
	}

	current_frame_index += 1
	current_frame_index %= swapchain_settings.image_count
}

submit_render :: proc(using rendeer: ^Renderer) {

    // current_render_index += 1
    // current_render_index %= swapchain_settings.image_count
}