package boco_renderer

import vk "vendor:vulkan"
import "core:log"

create_pipeline_layout :: proc(using renderer : ^Renderer) -> bool {
    // TODO: Descriptor pools might want to be moved out into their own thing, probably want more control.
    // TODO: But i guess im keeping the pool in the context and can be accessed anywhere anyway?
    // Descriptor Set Pool
    pool_sizes: [1]vk.DescriptorPoolSize
    pool_sizes[0].descriptorCount = 14 // TODO This is a random number, not sure what it should be.
    pool_sizes[0].type = .UNIFORM_BUFFER

    descriptor_pool_info: vk.DescriptorPoolCreateInfo
    descriptor_pool_info.sType = .DESCRIPTOR_POOL_CREATE_INFO
    descriptor_pool_info.poolSizeCount = len(pool_sizes)
    descriptor_pool_info.pPoolSizes = &pool_sizes[0]
    descriptor_pool_info.maxSets = 14 // TODO this is also random, figure out what it needs to be.

    vk.CreateDescriptorPool(logical_device, &descriptor_pool_info, nil, &descriptor_pool)

    // TODO: There are excessive and arbitrarily set, need to figure out reasonable values
    ui_pool_sizes:= [?]vk.DescriptorPoolSize{
        {vk.DescriptorType.SAMPLER, 100},
        {.COMBINED_IMAGE_SAMPLER, 100},
        {.SAMPLED_IMAGE, 100},
		{.STORAGE_IMAGE, 100},
		{.UNIFORM_TEXEL_BUFFER, 100},
		{.STORAGE_TEXEL_BUFFER, 100},
		{.UNIFORM_BUFFER, 100},
		{.STORAGE_BUFFER, 100},
		{.UNIFORM_BUFFER_DYNAMIC, 100},
		{.STORAGE_BUFFER_DYNAMIC, 100},
		{.INPUT_ATTACHMENT, 100},
    }

    ui_descriptor_pool_info: vk.DescriptorPoolCreateInfo
    ui_descriptor_pool_info.sType = .DESCRIPTOR_POOL_CREATE_INFO
    ui_descriptor_pool_info.poolSizeCount = len(ui_pool_sizes)
    ui_descriptor_pool_info.pPoolSizes = &ui_pool_sizes[0]
    ui_descriptor_pool_info.maxSets = 100
    ui_descriptor_pool_info.flags = {.FREE_DESCRIPTOR_SET}

    vk.CreateDescriptorPool(logical_device, &ui_descriptor_pool_info, nil, &ui_descriptor_pool)

    push_constant_ranges: [1]vk.PushConstantRange
    push_constant_ranges[0].stageFlags = {.VERTEX}
    push_constant_ranges[0].size = size_of(PushConstant)
    push_constant_ranges[0].offset = 0

    pipeline_layout_info: vk.PipelineLayoutCreateInfo
    pipeline_layout_info.sType = .PIPELINE_LAYOUT_CREATE_INFO
    pipeline_layout_info.setLayoutCount = 0
    pipeline_layout_info.pSetLayouts = nil
    pipeline_layout_info.pushConstantRangeCount = len(push_constant_ranges)
    pipeline_layout_info.pPushConstantRanges = &push_constant_ranges[0]

    res := vk.CreatePipelineLayout(logical_device, &pipeline_layout_info, nil, &pipeline_layout)
    if res != .SUCCESS do return false

    return true
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

    defer {
        delete(vertex_shader_buffer)
        delete(fragment_shader_buffer)
    }

    // Create Shader Modules
    vertex_shader_module : vk.ShaderModule
    create_shader_module(renderer, vertex_shader_buffer, &vertex_shader_module)

    fragment_shader_module: vk.ShaderModule
    create_shader_module(renderer, fragment_shader_buffer, &fragment_shader_module)

    defer {
        vk.DestroyShaderModule(logical_device, vertex_shader_module, nil)
        vk.DestroyShaderModule(logical_device, fragment_shader_module, nil)
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

    // Vertex Bindings
    // TODO: Add and decide on information to pass.
    // TODO: Vertex Bindings
    // TODO: Vertex Inputs
    vertex_bindings : vk.VertexInputBindingDescription
    vertex_bindings.binding = 0
    vertex_bindings.stride = size_of(Vertex)
    vertex_bindings.inputRate = .VERTEX
    // TODO: Add Instance bindings

    vertex_attributes : [3]vk.VertexInputAttributeDescription
    // Position
    vertex_attributes[0].binding = 0
    vertex_attributes[0].format = .R32G32B32_SFLOAT
    vertex_attributes[0].location = 0
    vertex_attributes[0].offset = auto_cast offset_of(Vertex, position)
    // Normal
    vertex_attributes[1].binding = 0
    vertex_attributes[1].format = .R32G32B32_SFLOAT
    vertex_attributes[1].location = 1
    vertex_attributes[1].offset = auto_cast offset_of(Vertex, normal)
    // Texture Coords
    vertex_attributes[2].binding = 0
    vertex_attributes[2].format = .R32G32_SFLOAT
    vertex_attributes[2].location = 2
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
    tesselation_info.patchControlPoints = 0

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
    rasterization_info.depthClampEnable = false
    rasterization_info.rasterizerDiscardEnable = false
    rasterization_info.polygonMode = .FILL
    rasterization_info.cullMode = {.BACK}
    // NOTE: Decide on mesh orientation.
    rasterization_info.frontFace = .COUNTER_CLOCKWISE
    rasterization_info.depthBiasEnable = false
    rasterization_info.depthBiasConstantFactor = 0.0
    rasterization_info.depthBiasClamp = 0.0
    rasterization_info.depthBiasSlopeFactor = 0.0
    rasterization_info.lineWidth = 1.0

    // MULTISAMPLE
    // TODO: Add support for Multisampling.
    multisample_info: vk.PipelineMultisampleStateCreateInfo
    multisample_info.sType = .PIPELINE_MULTISAMPLE_STATE_CREATE_INFO
    multisample_info.rasterizationSamples = {._1}
    multisample_info.sampleShadingEnable = false
    multisample_info.minSampleShading = 1.0
    multisample_info.pSampleMask = nil
    multisample_info.alphaToCoverageEnable = false
    multisample_info.alphaToOneEnable = false

    // DEPTH STENCIL
    // TODO: Add support for Depth.
    depth_stencil_info: vk.PipelineDepthStencilStateCreateInfo
    depth_stencil_info.sType = .PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO
    depth_stencil_info.depthTestEnable = true
    depth_stencil_info.depthWriteEnable = true
    depth_stencil_info.depthCompareOp = .LESS
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