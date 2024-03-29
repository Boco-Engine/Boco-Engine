package renderer

import "core:log"
import "core:strings"

import vk "vendor:vulkan"

PHYSICAL_DEVICE_TYPE_SCORE :: [vk.PhysicalDeviceType]u32{
    .OTHER          = 0,
    .INTEGRATED_GPU = 0,
    .DISCRETE_GPU   = 1000,
    .VIRTUAL_GPU    = 0,
    .CPU            = 0,
}

get_all_available_devices :: proc(using renderer: ^Renderer, out : ^[dynamic]vk.PhysicalDevice) {
    physical_device_count : u32
    vk.EnumeratePhysicalDevices(instance, &physical_device_count, nil)
    resize(out, auto_cast physical_device_count)
    vk.EnumeratePhysicalDevices(instance, &physical_device_count, &out[0])
    return
}

verify_required_feature_support :: proc(physical_device: vk.PhysicalDevice, enabled_features: RendererFeatures) -> (bool) {
    device_features : vk.PhysicalDeviceFeatures

    vk.GetPhysicalDeviceFeatures(physical_device, &device_features)
    for feature in SupportedRendererFeatures {
        if feature not_in enabled_features do continue
        #partial switch feature {
            case .geometryShader:
                if !device_features.geometryShader do return false
            case .tessellationShader:
                if !device_features.tessellationShader do return false
        }
    }

    return true
}

// Currently highly prioritises discrete gpus and just sorts by how many GBs available to the device
// Devices must support all the features specified in the renderer, otherwise will not be used
// Can consider adding required features and optional ones.
query_best_device :: proc(using renderer: ^Renderer) -> bool {
    available_physical_devices : [dynamic]vk.PhysicalDevice
    get_all_available_devices(renderer, &available_physical_devices)
    defer delete(available_physical_devices)
    log.info("Found", len(available_physical_devices), "available devices")

    best_device : vk.PhysicalDevice = nil
    best_score : u32
    for device in available_physical_devices {
        if !verify_required_feature_support(device, renderer.enabled_features) do continue
        device_score : u32 = 0

        properties : vk.PhysicalDeviceProperties
        vk.GetPhysicalDeviceProperties(device, &properties)

        device_type_score := PHYSICAL_DEVICE_TYPE_SCORE
        device_score += device_type_score[properties.deviceType]

        memory_properties : vk.PhysicalDeviceMemoryProperties
        vk.GetPhysicalDeviceMemoryProperties(device, &memory_properties)

        for i in 0..<memory_properties.memoryHeapCount {
            device_score += auto_cast memory_properties.memoryHeaps[i].size / 1_000_000_000
        }

        if device_score > best_score {
            best_device = device
            best_score = device_score
        }
    }

    physical_device = best_device

    if physical_device == nil {
        log.error("Failed to find compatible physical device on the system")
        return false
    }
    
    return true
}

verify_layer_support :: proc(layers: []cstring) -> (supported: bool = true) {
    available_layer_count : u32
    vk.EnumerateInstanceLayerProperties(&available_layer_count, nil)

    available_layers := make([]vk.LayerProperties, available_layer_count)
    defer delete(available_layers)

    vk.EnumerateInstanceLayerProperties(&available_layer_count, &available_layers[0])

    check_layer: for layer in layers {
        for &available_layer in available_layers {
            if layer == cstring(&available_layer.layerName[0]) do continue check_layer
        }
        log.error("Unsupported layer found:", layer)
        return false;
    }
    
    return 
}

verify_instance_extension_support :: proc(layers, extensions: []cstring) -> (supported: bool = true) {
    available_extension_count : u32
    vk.EnumerateInstanceExtensionProperties(nil, &available_extension_count, nil)

    available_extensions : [dynamic]vk.ExtensionProperties
    defer delete(available_extensions)

    resize(&available_extensions, auto_cast available_extension_count)

    vk.EnumerateInstanceExtensionProperties(nil, &available_extension_count, &available_extensions[0])

    for layer in layers {
        layer_extension_count : u32
        vk.EnumerateInstanceExtensionProperties(layer, &layer_extension_count, nil)

        if layer_extension_count == 0 do continue

        resize(&available_extensions, int(available_extension_count + layer_extension_count))
        
        vk.EnumerateInstanceExtensionProperties(layer, &layer_extension_count, &available_extensions[available_extension_count])

        available_extension_count += layer_extension_count
    }
    
    check_extension: for extension in extensions {
        for &available_extension in available_extensions {
            if extension == cstring(&available_extension.extensionName[0]) do continue check_extension
        }
        log.error("Unsupported layer found:", extension)
        return false
    }

    return
}

verify_device_extension_support :: proc(physical_device: vk.PhysicalDevice, layers, extensions: []cstring) -> (supported: bool = true) {
    available_extension_count : u32
    vk.EnumerateDeviceExtensionProperties(physical_device, nil, &available_extension_count, nil)

    available_extensions : [dynamic]vk.ExtensionProperties
    defer delete(available_extensions)

    resize(&available_extensions, auto_cast available_extension_count)

    vk.EnumerateDeviceExtensionProperties(physical_device, nil, &available_extension_count, &available_extensions[0])

    for layer in layers {
        layer_extension_count : u32
        vk.EnumerateDeviceExtensionProperties(physical_device, layer, &layer_extension_count, nil)

        if layer_extension_count == 0 do continue

        resize(&available_extensions, int(available_extension_count + layer_extension_count))
        
        vk.EnumerateDeviceExtensionProperties(physical_device, layer, &layer_extension_count, &available_extensions[available_extension_count])

        available_extension_count += layer_extension_count
    }

    // Prints Extensions
    // for &extension in available_extensions {
    //     log.debug(cstring(&extension.extensionName[0]))
    // }
    
    check_extension: for extension in extensions {
        for &available_extension in available_extensions {
            if extension == cstring(&available_extension.extensionName[0]) do continue check_extension
        }
        log.error("Unsupported layer found:", extension)
        return false
    }

    return
}

query_family_queues :: proc(using renderer: ^Renderer) -> bool {
    queue_family_properties_count: u32
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_properties_count, nil)
    queue_family_properties := make([]vk.QueueFamilyProperties, queue_family_properties_count)
    defer delete(queue_family_properties)
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_properties_count, raw_data(queue_family_properties))

    available_graphics_queues : [dynamic]u32
    available_compute_queues : [dynamic]u32
    taken_queue_indexes : [dynamic]u32
    defer {
        delete(available_graphics_queues)
        delete(available_compute_queues)
        delete(taken_queue_indexes)
    }

    for property, index in queue_family_properties {
        supports_present: b32
        vk.GetPhysicalDeviceSurfaceSupportKHR(physical_device, cast(u32)index, surface, &supports_present)

        if .GRAPHICS in property.queueFlags && supports_present {
            append(&available_graphics_queues, cast(u32)index)
        }
        if .COMPUTE in property.queueFlags {
            append(&available_compute_queues, cast(u32)index)
        }
    }


    if len(available_graphics_queues) == 0 do return false
    if len(available_compute_queues) == 0 do return false

    // WEAK_TODO Can be improved, but not too impactful
    contains_int :: proc(arr: [dynamic]u32, val: u32) -> (contains: bool = false) {
        for num in arr do if num == val do return true
        return
    }
    
    if len(available_graphics_queues) == 1 {
        queue_family_indices[.GRAPHICS] = available_graphics_queues[0]
    }
    else {
        for index in available_graphics_queues do if !(contains_int(taken_queue_indexes, index)) {queue_family_indices[.GRAPHICS] = index}
    }
    if len(available_compute_queues) == 1 { 
        queue_family_indices[.COMPUTE] = available_compute_queues[0]
    }
    else {
        for index in available_compute_queues do if !(contains_int(taken_queue_indexes, index)) { queue_family_indices[.COMPUTE] = index}
    }

    log.info("Queue Families Used:", queue_family_indices)

    return true
}

SwapchainSettings :: struct {
    surface_format: vk.SurfaceFormatKHR,
    present_mode: vk.PresentModeKHR,
    image_count: u32,
    transform: vk.SurfaceTransformFlagsKHR
}

get_swapchain_settings :: proc(using renderer: ^Renderer) -> (settings: SwapchainSettings) {
    capabilities: vk.SurfaceCapabilitiesKHR
    vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, &capabilities)

    num_formats: u32
    vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &num_formats, nil)
    formats := make([]vk.SurfaceFormatKHR, num_formats)
    defer delete(formats)
    vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &num_formats, &formats[0])

    num_present_modes: u32
    vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &num_present_modes, nil)
    present_modes := make([]vk.PresentModeKHR, num_present_modes)
    vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &num_present_modes, &present_modes[0])

    // Select Image Count
    settings.image_count = capabilities.minImageCount + 1
    settings.image_count = min(settings.image_count, capabilities.maxImageCount)

    // Select Transform
    settings.transform = capabilities.currentTransform

    // Select Format
    settings.surface_format = formats[0] // default to first one for now.
    for format in formats {
        if (format.format == vk.Format.R8G8B8A8_SRGB || format.format == vk.Format.B8G8R8A8_SRGB) && format.colorSpace == vk.ColorSpaceKHR.COLORSPACE_SRGB_NONLINEAR {
            settings.surface_format = format
            break
        }
    }

    // Select Present Mode
    settings.present_mode = present_modes[0] // default to first one for now
    for present_mode in present_modes {
        if present_mode == vk.PresentModeKHR.MAILBOX {
            settings.present_mode = present_mode
            break
        }
    }

    return
}

create_indexed_mesh :: proc(vertex_data: []Vec3, index_data: []u32) {
    
}

get_memory_from_properties :: proc(using renderer: ^Renderer, properties: vk.MemoryPropertyFlags) -> (u32) {
	available_properties: vk.PhysicalDeviceMemoryProperties
	vk.GetPhysicalDeviceMemoryProperties(physical_device, &available_properties)

	for i in 0..<available_properties.memoryTypeCount {
		if (available_properties.memoryTypes[i].propertyFlags & properties) == properties {
			return i
		}
	}

	log.error("Failed to find supported memory.")

	return 0
}

// ONLY USE ON TESTING
wait_on_device :: proc(using renderer: ^Renderer) {
    vk.DeviceWaitIdle(logical_device);
}

@(deferred_in_out=_SCOPED_COMMAND_END)
SCOPED_COMMAND :: proc(renderer: ^Renderer) -> ([^]vk.CommandBuffer) {
    return BeginSingleCommand(renderer)
}

_SCOPED_COMMAND_END :: proc(renderer: ^Renderer, command_buffer: [^]vk.CommandBuffer) {
    EndSingleCommand(renderer, command_buffer)
}

BeginSingleCommand :: proc(renderer: ^Renderer) -> ([^]vk.CommandBuffer) {
    cmd_alloc_info : vk.CommandBufferAllocateInfo
    cmd_alloc_info.sType = .COMMAND_BUFFER_ALLOCATE_INFO
    cmd_alloc_info.level = .PRIMARY
    cmd_alloc_info.commandPool = renderer.command_pool
    cmd_alloc_info.commandBufferCount = 1

    command_buffer : [^]vk.CommandBuffer = make([^]vk.CommandBuffer, 1)
    vk.AllocateCommandBuffers(renderer.logical_device, &cmd_alloc_info, command_buffer)

    begin_info : vk.CommandBufferBeginInfo
    begin_info.sType = .COMMAND_BUFFER_BEGIN_INFO
    begin_info.flags = {.ONE_TIME_SUBMIT}

    vk.BeginCommandBuffer(command_buffer[0], &begin_info)

    return command_buffer
}

EndSingleCommand :: proc(renderer: ^ Renderer, command_buffer: [^]vk.CommandBuffer) {
    vk.EndCommandBuffer(command_buffer[0])

    submit_info : vk.SubmitInfo
    submit_info.sType = .SUBMIT_INFO
    submit_info.commandBufferCount = 1
    submit_info.pCommandBuffers = command_buffer

    vk.QueueSubmit(renderer.queues[.GRAPHICS], 1, &submit_info, 0)
    vk.QueueWaitIdle(renderer.queues[.GRAPHICS])

    vk.FreeCommandBuffers(renderer.logical_device, renderer.command_pool, 1, command_buffer)
}

TransitionImageLayout :: proc(cmd_buffer: vk.CommandBuffer, texture: Texture, curr_layout, desired_layout: vk.ImageLayout) {
    barrier : vk.ImageMemoryBarrier

    barrier.sType = .IMAGE_MEMORY_BARRIER
    barrier.oldLayout = curr_layout
    barrier.newLayout = desired_layout
    barrier.srcQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED
    barrier.dstQueueFamilyIndex = vk.QUEUE_FAMILY_IGNORED
    barrier.image = texture.image
    barrier.subresourceRange.aspectMask = {.COLOR}
    barrier.subresourceRange.baseMipLevel = 0
    barrier.subresourceRange.levelCount = 1
    barrier.subresourceRange.baseArrayLayer = 0
    barrier.subresourceRange.layerCount = 1
    barrier.srcAccessMask = {}
    barrier.dstAccessMask = {}

    source_stage : vk.PipelineStageFlags
    dest_stage : vk.PipelineStageFlags

    if (curr_layout == .UNDEFINED && desired_layout == .TRANSFER_DST_OPTIMAL) {
        barrier.srcAccessMask = {}
        barrier.dstAccessMask = {.TRANSFER_WRITE}

        source_stage = {.TOP_OF_PIPE}
        dest_stage = {.TRANSFER}
    } else if (curr_layout == .TRANSFER_DST_OPTIMAL && desired_layout == .SHADER_READ_ONLY_OPTIMAL) {
        barrier.srcAccessMask = {.TRANSFER_WRITE}
        barrier.dstAccessMask = {.SHADER_READ}

        source_stage = {.TRANSFER}
        dest_stage = {.FRAGMENT_SHADER}
    } else {
        assert(false, "Unsupported Transtion type!")
    }

    vk.CmdPipelineBarrier(
        cmd_buffer, 
        source_stage, 
        dest_stage,
        {}, 
        0, nil, 
        0, nil, 
        1, &barrier)
}