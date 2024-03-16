package renderer

import "core:log"
import "core:strings"

import vk "vendor:vulkan"

initialise_pipelines :: proc(renderer: ^Renderer, materials: []Material) {
    // Unique pipeline for each combination of shaders and polygon modes.
    pipeline_count : u32 = 1
    renderer.material_to_pipeline_index[materials[0].id] = 0
    create_pipelines_from : [dynamic]u32 = {0}
    defer delete(create_pipelines_from)

    outer: for i in 1..<len(materials) {
        one := materials[i]
        inner: for j in 0..<i {
            two := materials[j]

            if (len(one.shaders) != len(two.shaders)) do continue
            if (one.polygon_mode != two.polygon_mode) do continue
            
            outer_shader: for shader in one.shaders {
                for other in two.shaders {
                    if shader.path == other.path do continue outer_shader
                }
                continue inner
            }

            // If were here we have identical pipelines therefore set to same pipeline and continue
            renderer.material_to_pipeline_index[materials[i].id] = renderer.material_to_pipeline_index[materials[j].id]
            continue outer
        }
        // If were here no identical pipelines
        append(&create_pipelines_from, cast(u32)i)
        renderer.material_to_pipeline_index[materials[i].id] = pipeline_count
        pipeline_count += 1
    }

    renderer.graphics_pipelines = make([]vk.Pipeline, pipeline_count)

    for i in create_pipelines_from {
        renderer.graphics_pipelines[renderer.material_to_pipeline_index[materials[i].id]] = create_pipeline(renderer, materials[i])
    }
}

create_pipeline :: proc(using renderer: ^Renderer, material: Material) -> vk.Pipeline {    
    shader_stages:= make([]vk.PipelineShaderStageCreateInfo, len(material.shaders))
    defer delete(shader_stages)

    shader_modules := make([]vk.ShaderModule, len(material.shaders))
    defer {
        for _, i in shader_modules {
            vk.DestroyShaderModule(logical_device, shader_modules[i], nil)
        }
        delete(shader_modules)
    }

    for shader, i in material.shaders {
        shader_buffer, ok := read_spirv(shader.path)
        defer delete(shader_buffer)
        if !ok {
            log.error("Failed reading shader at: ", shader.path);
        }

        create_shader_module(renderer, shader_buffer, &shader_modules[i])

        stage: vk.ShaderStageFlags

        switch shader.stage {
            case .VERTEX:
                stage = {.VERTEX}
            case .FRAGMENT:
                stage = {.FRAGMENT}
            case .TESSELLATION_EVALUATION:
                stage = {.TESSELLATION_EVALUATION}
            case .TESSELLATION_CONTROL:
                stage = {.TESSELLATION_CONTROL}
            case .GEOMETRY:
                stage = {.GEOMETRY}
            case .COMPUTE:
                stage = {.COMPUTE}
                log.warn("Adding compute shader to a graphics pipeline. Compute shaders should be used with compute pipelines.")
        }
    
        stage_info: vk.PipelineShaderStageCreateInfo
        stage_info.sType = .PIPELINE_SHADER_STAGE_CREATE_INFO
        stage_info.stage = stage
        stage_info.module = shader_modules[i]
        stage_info.pName = strings.clone_to_cstring(shader.entry, context.temp_allocator)
    
       shader_stages[i] = stage_info
    }

    // Vertex Bindings
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
    tesselation_info.patchControlPoints = 3

    // Viewports and Scissor @Dynamic
    viewport_info: vk.PipelineViewportStateCreateInfo
    viewport_info.sType = .PIPELINE_VIEWPORT_STATE_CREATE_INFO
    viewport_info.viewportCount = 1
    viewport_info.pViewports = &viewport
    viewport_info.scissorCount = 1
    viewport_info.pScissors = &scissor

    polygon_mode: vk.PolygonMode

    switch material.polygon_mode {
        case .FILL:
            polygon_mode = .FILL
        case .LINE:
            polygon_mode = .LINE
        case .POINT:
            polygon_mode = .POINT
    }

    culling_mode : vk.CullModeFlags

    switch material.culling_mode {
        case .BACK:
            culling_mode = {.BACK}
        case .FRONT:
            culling_mode = {.FRONT}
        case .NONE:
            culling_mode = {}
    }

    // Rasterisation
    rasterization_info: vk.PipelineRasterizationStateCreateInfo
    rasterization_info.sType = .PIPELINE_RASTERIZATION_STATE_CREATE_INFO
    rasterization_info.rasterizerDiscardEnable = false
    rasterization_info.polygonMode = polygon_mode
    rasterization_info.cullMode = culling_mode
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