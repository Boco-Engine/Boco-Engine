package renderer

import "core:log"

import vk "vendor:vulkan"

create_ui_pipeline :: proc(using renderer: ^Renderer) -> vk.Pipeline {    
    shader_stages : [2]vk.PipelineShaderStageCreateInfo
    // defer delete(shader_stages)

    shader_modules : [2]vk.ShaderModule
    defer {
        for _, i in shader_modules {
            vk.DestroyShaderModule(logical_device, shader_modules[i], nil)
        }
        // delete(shader_modules)
    }

    vert_shader_buffer, v_ok := read_spirv("text.vert.spv")
    defer delete(vert_shader_buffer)
    if !v_ok {
        log.error("Failed reading shader at: ", "text.vert.spv");
    }

    create_shader_module(renderer, vert_shader_buffer, &shader_modules[0])

    stage_info_v: vk.PipelineShaderStageCreateInfo
    stage_info_v.sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    stage_info_v.stage = {.VERTEX}
    stage_info_v.module = shader_modules[0]
    stage_info_v.pName = "main"

    shader_stages[0] = stage_info_v

    frag_shader_buffer, f_ok := read_spirv("text.frag.spv")
    defer delete(frag_shader_buffer)
    if !f_ok {
        log.error("Failed reading shader at: ", "text.frag.spv");
    }

    create_shader_module(renderer, frag_shader_buffer, &shader_modules[1])

    stage_info_f: vk.PipelineShaderStageCreateInfo
    stage_info_f.sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
    stage_info_f.stage = {.FRAGMENT}
    stage_info_f.module = shader_modules[1]
    stage_info_f.pName = "main"

    shader_stages[1] = stage_info_f
    

    // Vertex Bindings
    vertex_bindings : vk.VertexInputBindingDescription
    vertex_bindings.binding = 0
    vertex_bindings.stride = size_of(UIVertex)
    vertex_bindings.inputRate = .VERTEX
    // TODO: Add Instance bindings

    vertex_attributes : [2]vk.VertexInputAttributeDescription
    // Position
    vertex_attributes[0].binding = 0
    vertex_attributes[0].format = .R32G32_SFLOAT
    vertex_attributes[0].location = 0
    vertex_attributes[0].offset = auto_cast offset_of(UIVertex, position)
    // Texture Coords
    vertex_attributes[1].binding = 0
    vertex_attributes[1].format = .R32G32_SFLOAT
    vertex_attributes[1].location = 1
    vertex_attributes[1].offset = auto_cast offset_of(UIVertex, texture_coord)
    

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
    rasterization_info.rasterizerDiscardEnable = false
    rasterization_info.polygonMode = .FILL
    rasterization_info.cullMode = {}
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
    depth_stencil_info.depthCompareOp = .ALWAYS
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
    colour_blend_attachments[0].blendEnable = true
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
    pipeline_info.stageCount = auto_cast len(shader_stages)
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

    pipeline : vk.Pipeline
    res := vk.CreateGraphicsPipelines(logical_device, 0, 1, &pipeline_info, nil, &pipeline)
    if res != .SUCCESS do return 0

    return pipeline
}