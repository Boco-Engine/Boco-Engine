package renderer

import "core:log"

import vk "vendor:vulkan"

pipeline_layout_create :: proc(using renderer : ^Renderer) -> bool {
    // TODO: Descriptor pools/sets want to be moved out and shouldnt be in this function what so ever.
    // Descriptor Set Pool
    pool_sizes: [2]vk.DescriptorPoolSize
    pool_sizes[0].type = .UNIFORM_BUFFER
    pool_sizes[0].descriptorCount = swapchain_settings.image_count

    pool_sizes[1].type = .COMBINED_IMAGE_SAMPLER
    pool_sizes[1].descriptorCount = swapchain_settings.image_count

    descriptor_pool_info: vk.DescriptorPoolCreateInfo
    descriptor_pool_info.sType = .DESCRIPTOR_POOL_CREATE_INFO
    descriptor_pool_info.poolSizeCount = len(pool_sizes)
    descriptor_pool_info.pPoolSizes = &pool_sizes[0]
    descriptor_pool_info.maxSets = swapchain_settings.image_count

    vk.CreateDescriptorPool(logical_device, &descriptor_pool_info, nil, &descriptor_pool)

    layout_bindings : [2]vk.DescriptorSetLayoutBinding

    layout_bindings[0].binding = 0
    layout_bindings[0].descriptorType = .UNIFORM_BUFFER
    layout_bindings[0].descriptorCount = 1
    layout_bindings[0].stageFlags = {.VERTEX}
    layout_bindings[0].pImmutableSamplers = nil

    layout_bindings[1].binding = 1
    layout_bindings[1].descriptorType = .COMBINED_IMAGE_SAMPLER
    layout_bindings[1].descriptorCount = 1
    layout_bindings[1].stageFlags = {.FRAGMENT}
    layout_bindings[1].pImmutableSamplers = nil

    // layout_bindings[2].binding = 2
    // layout_bindings[2].descriptorType = .UNIFORM_BUFFER
    // layout_bindings[2].descriptorCount = 1
    // layout_bindings[2].stageFlags = {.TESSELLATION_CONTROL}
    // layout_bindings[2].pImmutableSamplers = nil
    
    layout_info : vk.DescriptorSetLayoutCreateInfo
    layout_info.sType = .DESCRIPTOR_SET_LAYOUT_CREATE_INFO
    layout_info.bindingCount = len(layout_bindings)
    layout_info.pBindings = &layout_bindings[0]

    vk.CreateDescriptorSetLayout(logical_device, &layout_info, nil, &descriptor_set_layout)

    // Sets
    renderer.descriptor_set_layouts = make([]vk.DescriptorSetLayout, renderer.swapchain_settings.image_count)
    for _, i in descriptor_set_layouts do descriptor_set_layouts[i] = descriptor_set_layout
    set_info : vk.DescriptorSetAllocateInfo
    set_info.sType = .DESCRIPTOR_SET_ALLOCATE_INFO
    set_info.descriptorPool = descriptor_pool
    set_info.descriptorSetCount = swapchain_settings.image_count
    set_info.pSetLayouts = &descriptor_set_layouts[0]

    descriptor_sets = make([]vk.DescriptorSet, swapchain_settings.image_count)
    vk.AllocateDescriptorSets(logical_device, &set_info, &descriptor_sets[0])

    // uniform_buffers = make([]BufferResources, swapchain_settings.image_count)
    // camera_buffers = make([]BufferResources, swapchain_settings.image_count)

    push_constant_ranges: [1]vk.PushConstantRange
    push_constant_ranges[0].stageFlags = {.VERTEX}
    push_constant_ranges[0].size = size_of(PushConstant)
    push_constant_ranges[0].offset = 0

    pipeline_layout_info: vk.PipelineLayoutCreateInfo
    pipeline_layout_info.sType = .PIPELINE_LAYOUT_CREATE_INFO
    pipeline_layout_info.setLayoutCount = 1
    pipeline_layout_info.pSetLayouts = &descriptor_set_layout
    pipeline_layout_info.pushConstantRangeCount = len(push_constant_ranges)
    pipeline_layout_info.pPushConstantRanges = &push_constant_ranges[0]

    res := vk.CreatePipelineLayout(logical_device, &pipeline_layout_info, nil, &pipeline_layout)
    if res != .SUCCESS do return false

    return true
}

update_descriptor_sets ::proc(using renderer: ^Renderer, m, v, p: Mat4, pos: [3]f32, i: u32) {
    
    ubo := [1]UniformBufferObject{
        UniformBufferObject{
            m, v, p,
        },
    }

    // camera_pos := [1]CameraBufferObject {
    //     CameraBufferObject{
    //         pos,
    //     },
    // }

    // for i in 0..<swapchain_settings.image_count {
        buffer_write(renderer, &uniform_buffers[i], ubo[:], 0)

        // allocate_buffer(renderer, UniformBufferObject, size_of(UniformBufferObject), {.UNIFORM_BUFFER}, &camera_buffers[i])
        // write_to_buffer(renderer, &camera_buffers[i], camera_pos[:], 0)

        descriptor_buffer_info : vk.DescriptorBufferInfo
        descriptor_buffer_info.buffer = uniform_buffers[i].buffer
        descriptor_buffer_info.offset = 0
        descriptor_buffer_info.range = size_of(UniformBufferObject)

        descriptor_image_info : vk.DescriptorImageInfo
        descriptor_image_info.imageLayout = .SHADER_READ_ONLY_OPTIMAL
        descriptor_image_info.imageView = texture.image_view
        descriptor_image_info.sampler = texture.sampler

        // camera_buffer_info : vk.DescriptorBufferInfo
        // camera_buffer_info.buffer = uniform_buffers[i].buffer
        // camera_buffer_info.offset = 0
        // camera_buffer_info.range = size_of(UniformBufferObject)

        descriptor_writes : [2]vk.WriteDescriptorSet
        descriptor_writes[0].sType = .WRITE_DESCRIPTOR_SET
        descriptor_writes[0].dstSet = descriptor_sets[i]
        descriptor_writes[0].dstBinding = 0
        descriptor_writes[0].dstArrayElement = 0
        descriptor_writes[0].descriptorType = .UNIFORM_BUFFER
        descriptor_writes[0].descriptorCount = 1
        descriptor_writes[0].pBufferInfo = &descriptor_buffer_info
        descriptor_writes[0].pImageInfo = nil
        descriptor_writes[0].pTexelBufferView = nil

        descriptor_writes[1].sType = .WRITE_DESCRIPTOR_SET
        descriptor_writes[1].dstSet = descriptor_sets[i]
        descriptor_writes[1].dstBinding = 1
        descriptor_writes[1].dstArrayElement = 0
        descriptor_writes[1].descriptorType = .COMBINED_IMAGE_SAMPLER
        descriptor_writes[1].descriptorCount = 1
        descriptor_writes[1].pBufferInfo = nil
        descriptor_writes[1].pImageInfo = &descriptor_image_info
        descriptor_writes[1].pTexelBufferView = nil

        // descriptor_writes[2].sType = .WRITE_DESCRIPTOR_SET
        // descriptor_writes[2].dstSet = descriptor_sets[i]
        // descriptor_writes[2].dstBinding = 2
        // descriptor_writes[2].dstArrayElement = 0
        // descriptor_writes[2].descriptorType = .UNIFORM_BUFFER
        // descriptor_writes[2].descriptorCount = 1
        // descriptor_writes[2].pBufferInfo = &camera_buffer_info
        // descriptor_writes[2].pImageInfo = nil
        // descriptor_writes[2].pTexelBufferView = nil
        
        vk.UpdateDescriptorSets(logical_device, len(descriptor_writes), &descriptor_writes[0], 0, nil)
    // }
}

create_graphics_pipeline :: proc(using renderer : ^Renderer) -> bool {
    // Load Shader files
    vertex_shader_buffer, vert_ok := read_spirv("main.vert.spv")
    if !vert_ok {
        log.error("Failed reading vertex shader.");
    }
    fragment_shader_buffer, frag_ok := read_spirv("main.frag.spv")
    if !frag_ok {
        log.error("Failed reading fragment shader.");
    }
    // tess_control_shader_buffer, cont_ok := read_spirv("main.tesc.spv")
    // if !frag_ok {
    //     log.error("Failed reading fragment shader.");
    // }
    // tess_eval_shader_buffer, eval_ok := read_spirv("main.tese.spv")
    // if !frag_ok {
    //     log.error("Failed reading fragment shader.");
    // }

    defer {
        delete(vertex_shader_buffer)
        delete(fragment_shader_buffer)
        // delete(tess_control_shader_buffer)
        // delete(tess_eval_shader_buffer)
    }

    // Create Shader Modules
    vertex_shader_module : vk.ShaderModule
    create_shader_module(renderer, vertex_shader_buffer, &vertex_shader_module)

    fragment_shader_module: vk.ShaderModule
    create_shader_module(renderer, fragment_shader_buffer, &fragment_shader_module)
    
    // tess_control_shader_module: vk.ShaderModule
    // create_shader_module(renderer, tess_control_shader_buffer, &tess_control_shader_module)
    
    // tess_eval_shader_module: vk.ShaderModule
    // create_shader_module(renderer, tess_eval_shader_buffer, &tess_eval_shader_module)

    defer {
        vk.DestroyShaderModule(logical_device, vertex_shader_module, nil)
        vk.DestroyShaderModule(logical_device, fragment_shader_module, nil)
        // vk.DestroyShaderModule(logical_device, tess_control_shader_module, nil)
        // vk.DestroyShaderModule(logical_device, tess_eval_shader_module, nil)
    }

    // Shader Stages
    shader_stages: [2]vk.PipelineShaderStageCreateInfo

    shader_stages[0].sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    shader_stages[0].stage = {.VERTEX}
    shader_stages[0].module = vertex_shader_module
    shader_stages[0].pName = "main"
    
    shader_stages[1].sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    shader_stages[1].stage = {.FRAGMENT}
    shader_stages[1].module = fragment_shader_module
    shader_stages[1].pName = "main"

    // shader_stages[2].sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    // shader_stages[2].stage = {.TESSELLATION_CONTROL}
    // shader_stages[2].module = tess_control_shader_module
    // shader_stages[2].pName = "main"

    // shader_stages[3].sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    // shader_stages[3].stage = {.TESSELLATION_EVALUATION}
    // shader_stages[3].module = tess_eval_shader_module
    // shader_stages[3].pName = "main"

    // Vertex Bindings
    // TODO: Add and decide on information to pass.
    // TODO: Vertex Bindings
    // TODO: Vertex Inputs
    vertex_bindings : vk.VertexInputBindingDescription
    vertex_bindings.binding = 0
    vertex_bindings.stride = size_of(Vertex)
    vertex_bindings.inputRate = .VERTEX
    // TODO: Add Instance bindings

    // TODO: @Benas Look into making this 64 bits so we can have big planets!!!
    vertex_attributes : [3]vk.VertexInputAttributeDescription
    // Position
    vertex_attributes[0].binding = 0
    vertex_attributes[0].format = .R32G32B32_SFLOAT
    vertex_attributes[0].location = 0
    vertex_attributes[0].offset = auto_cast offset_of(Vertex, position)
    // Normal
    vertex_attributes[1].binding = 0
    vertex_attributes[1].format = .R32G32B32_SFLOAT
    vertex_attributes[1].location = 2
    vertex_attributes[1].offset = auto_cast offset_of(Vertex, normal)
    // Texture Coords
    vertex_attributes[2].binding = 0
    vertex_attributes[2].format = .R32G32_SFLOAT
    vertex_attributes[2].location = 3
    vertex_attributes[2].offset = auto_cast offset_of(Vertex, texture_coords)
    
    vertex_input_info: vk.PipelineVertexInputStateCreateInfo
    vertex_input_info.sType = .PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO
    vertex_input_info.vertexBindingDescriptionCount = 1
    vertex_input_info.pVertexBindingDescriptions = &vertex_bindings
    vertex_input_info.vertexAttributeDescriptionCount = len(vertex_attributes)
    vertex_input_info.pVertexAttributeDescriptions = &vertex_attributes[0]

    // Vertex Input Assembly
    vertex_input_assembly_info: vk.PipelineInputAssemblyStateCreateInfo
    vertex_input_assembly_info.sType = .PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO
    vertex_input_assembly_info.topology = .TRIANGLE_LIST
    vertex_input_assembly_info.primitiveRestartEnable = false

    // Tesselation
    tesselation_info: vk.PipelineTessellationStateCreateInfo
    tesselation_info.sType = .PIPELINE_TESSELLATION_STATE_CREATE_INFO
    tesselation_info.patchControlPoints = 3

    // Viewports and Scissor @Dynamic
    viewport_info: vk.PipelineViewportStateCreateInfo
    viewport_info.sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO
    viewport_info.viewportCount = 1
    viewport_info.pViewports = &viewport
    viewport_info.scissorCount = 1
    viewport_info.pScissors = &scissor

    // Rasterisation
    rasterization_info: vk.PipelineRasterizationStateCreateInfo
    rasterization_info.sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO
    rasterization_info.rasterizerDiscardEnable = false
    rasterization_info.polygonMode = .FILL
    rasterization_info.cullMode = {.BACK}
    // NOTE: Decide on mesh orientation.
    rasterization_info.frontFace = .COUNTER_CLOCKWISE
    rasterization_info.depthBiasEnable = false
    rasterization_info.depthBiasConstantFactor = 0.0
    rasterization_info.depthClampEnable = false
    rasterization_info.depthBiasClamp = 0.0
    rasterization_info.depthBiasSlopeFactor = 0.0
    rasterization_info.lineWidth = 1.0

    // MULTISAMPLE
    // TODO: Add support for Multisampling.
    multisample_info: vk.PipelineMultisampleStateCreateInfo
    multisample_info.sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO
    multisample_info.rasterizationSamples = sample_count
    multisample_info.sampleShadingEnable = false
    multisample_info.minSampleShading = 1.0
    multisample_info.pSampleMask = nil
    multisample_info.alphaToCoverageEnable = false
    multisample_info.alphaToOneEnable = false

    // DEPTH STENCIL
    depth_stencil_info: vk.PipelineDepthStencilStateCreateInfo
    depth_stencil_info.sType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO
    depth_stencil_info.depthTestEnable = true
    depth_stencil_info.depthWriteEnable = true
    depth_stencil_info.depthCompareOp = .LESS_OR_EQUAL
    depth_stencil_info.depthBoundsTestEnable = false
    depth_stencil_info.minDepthBounds = 0.0
    depth_stencil_info.maxDepthBounds = 1.0
    // TODO: Add support for stencil.
    depth_stencil_info.stencilTestEnable = false
    depth_stencil_info.front = vk.StencilOpState{}
    depth_stencil_info.back = vk.StencilOpState{}

    // COLOUR BLEND
    // TODO: These are just random default values.
    colour_blend_attachments: [1]vk.PipelineColorBlendAttachmentState
    colour_blend_attachments[0].blendEnable = false
    colour_blend_attachments[0].srcColorBlendFactor = .SRC_COLOR
    colour_blend_attachments[0].dstColorBlendFactor = .ONE_MINUS_DST_COLOR
    colour_blend_attachments[0].colorBlendOp = .ADD
    colour_blend_attachments[0].srcAlphaBlendFactor = .SRC_ALPHA
    colour_blend_attachments[0].dstAlphaBlendFactor = .ONE_MINUS_DST_COLOR
    colour_blend_attachments[0].alphaBlendOp = .ADD
    colour_blend_attachments[0].colorWriteMask = {.R, .G, .B, .A}

    colour_blend_info: vk.PipelineColorBlendStateCreateInfo
    colour_blend_info.sType = .PIPELINE_COLOR_BLEND_STATE_CREATE_INFO
    colour_blend_info.logicOpEnable = false
    colour_blend_info.logicOp = .AND
    colour_blend_info.attachmentCount = 1
    colour_blend_info.pAttachments = &colour_blend_attachments[0]
    colour_blend_info.blendConstants = {0.0, 0.0, 0.0, 0.0}

    // DYNAMIC STATES
    // TODO: Add more dynamic state support for editor and debugging.
    dynamic_states := []vk.DynamicState{.SCISSOR, .VIEWPORT}
    dynamic_info: vk.PipelineDynamicStateCreateInfo
    dynamic_info.sType = .PIPELINE_DYNAMIC_STATE_CREATE_INFO
    dynamic_info.dynamicStateCount = cast(u32)len(dynamic_states)
    dynamic_info.pDynamicStates = &dynamic_states[0]

    // PIPELINE CREATION
    pipeline_info: vk.GraphicsPipelineCreateInfo
    pipeline_info.sType = .GRAPHICS_PIPELINE_CREATE_INFO
    pipeline_info.stageCount = len(shader_stages)
    pipeline_info.pStages = &shader_stages[0]
    pipeline_info.pVertexInputState = &vertex_input_info
    pipeline_info.pInputAssemblyState = &vertex_input_assembly_info
    pipeline_info.pTessellationState = &tesselation_info
    pipeline_info.pViewportState = &viewport_info
    pipeline_info.pRasterizationState = &rasterization_info
    pipeline_info.pMultisampleState = &multisample_info
    pipeline_info.pDepthStencilState = &depth_stencil_info
    pipeline_info.pColorBlendState = &colour_blend_info
    pipeline_info.pDynamicState = &dynamic_info
    pipeline_info.layout = pipeline_layout
    pipeline_info.renderPass = render_pass
    pipeline_info.subpass = 0
    pipeline_info.basePipelineIndex = 0
    pipeline_info.basePipelineHandle = vk.Pipeline{}

    res := vk.CreateGraphicsPipelines(logical_device, 0, 1, &pipeline_info, nil, &graphics_pipeline)
    if res != .SUCCESS do return false

    return true
}

create_shader_module :: proc(using renderer: ^Renderer, shader_code: []u8, shader_module: ^vk.ShaderModule) {
    info : vk.ShaderModuleCreateInfo
    info.sType = .SHADER_MODULE_CREATE_INFO
    info.codeSize = len(shader_code)
    info.pCode = cast(^u32)raw_data(shader_code)

    vk.CreateShaderModule(logical_device, &info, nil, shader_module)
}