package boco_renderer

import vk "vendor:vulkan"
import "core:log"
import "core:strings"

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
        switch feature {
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
query_best_device :: proc(using renderer: ^Renderer) {
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
    assert(physical_device != nil, "Failed to find supported device.")
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
        return false;
    }
    
    return 
}

verify_extension_support :: proc(layers, extensions: []cstring) -> (supported: bool = true) {
    available_extension_count : u32
    vk.EnumerateInstanceExtensionProperties(nil, &available_extension_count, nil)

    available_extensions : [dynamic]vk.ExtensionProperties
    defer delete(available_extensions)

    resize(&available_extensions, auto_cast available_extension_count)

    vk.EnumerateInstanceExtensionProperties(nil, &available_extension_count, &available_extensions[0])

    for layer in layers {
        layer_extension_count : u32
        vk.EnumerateInstanceExtensionProperties(layer, &layer_extension_count, nil)

        resize(&available_extensions, int(available_extension_count + layer_extension_count))
        vk.EnumerateInstanceExtensionProperties(layer, &available_extension_count, &available_extensions[available_extension_count])

        available_extension_count += layer_extension_count
    }

    check_extension: for extension in extensions {
        for &available_extension in available_extensions {
            if extension == cstring(&available_extension.extensionName[0]) do continue check_extension
        }
        return false
    }

    return
}

query_family_queues :: proc(using renderer: ^Renderer, queue_flags_wanted :bit_set[vk.QueueFlag]) {
    queue_family_property_count : u32
    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_property_count, nil)

    queue_family_properties := make([]vk.QueueFamilyProperties, queue_family_property_count)
    defer delete(queue_family_properties)

    vk.GetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_property_count, &queue_family_properties[0])
    
    for family_property in queue_family_properties {
        log.debug(family_property)
    }
}