//+private
package boco_renderer

import "core:c"
import "core:log"
import "core:fmt"
import vk "vendor:vulkan"
import sdl "vendor:sdl2"

foreign import vulkan "vulkan-1.lib"

foreign vulkan {
    vkGetInstanceProcAddr :: proc(vk.Instance, cstring) -> rawptr ---
}

RendererInternals :: struct {
    instance: vk.Instance,
    available_physical_devices: []vk.PhysicalDevice,
    physical_device: vk.PhysicalDevice,
    logical_device: vk.Device,

}

init_vulkan :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
    log.info("Creating Vulkan resources")
	vk.load_proc_addresses(cast(rawptr)vkGetInstanceProcAddr)

    init_instance(renderer)
    physical_device_count : u32
    vk.EnumeratePhysicalDevices(instance, &physical_device_count, nil)
    available_physical_devices = make([]vk.PhysicalDevice, physical_device_count)
    vk.EnumeratePhysicalDevices(instance, &physical_device_count, &available_physical_devices[0])

    query_best_device(renderer)

    return
}

cleanup_vulkan :: proc(using renderer: ^Renderer) {
    log.info("Cleaning Vulkan resources")
    vk.DestroyInstance(instance, nil)
}

init_instance :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
    application_info : vk.ApplicationInfo
    application_info.sType = .APPLICATION_INFO
    // NOTE: Guess for this might be user application stuff we want to place.
    application_info.pApplicationName = "Application Name"
    application_info.applicationVersion = vk.MAKE_VERSION(0, 1, 0)
    application_info.pEngineName = "Boco Engine"
    application_info.engineVersion = vk.MAKE_VERSION(0, 1, 0)
    application_info.apiVersion = vk.API_VERSION_1_0

    instance_info : vk.InstanceCreateInfo
    instance_info.sType = .INSTANCE_CREATE_INFO
    instance_info.pApplicationInfo = &application_info
    // TODO: Need to query window/os for what extensions we need.

    extensions := [?]cstring {vk.KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME}
    
    when ODIN_DEBUG {
        layers := [?]cstring{"VK_LAYER_KHRONOS_validation"}
    } else {
        layers := [?]cstring{}
    }

    instance_info.enabledExtensionCount = len(extensions)
    instance_info.ppEnabledExtensionNames = &extensions[0]

    instance_info.enabledLayerCount = 0
    instance_info.ppEnabledLayerNames = nil

    when ODIN_DEBUG {
        instance_info.enabledLayerCount = len(layers)
        instance_info.ppEnabledLayerNames = &layers[0]
    }

    res := vk.CreateInstance(&instance_info, nil, &instance)
    if res != .SUCCESS {
        log.error("Failed initialising Vulkan Instance")
        log.error(res)
        return false
    }

    vk.load_proc_addresses(instance);

    log.info("Created Instance")

    return
}

device_supports_required_features :: proc(physical_device: vk.PhysicalDevice, enabled_features: RendererFeatures) -> (bool) {
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

PHYSICAL_DEVICE_TYPE_SCORE :: [vk.PhysicalDeviceType]u32{
    .OTHER          = 100,
	.INTEGRATED_GPU = 0,
	.DISCRETE_GPU   = 1000,
	.VIRTUAL_GPU    = 0,
	.CPU            = 100,
}

query_best_device :: proc(using renderer: ^Renderer) {
    best_device : vk.PhysicalDevice = nil
    best_score : u32
    for device in available_physical_devices {
        if !device_supports_required_features(physical_device, renderer.features) do continue
        device_score : u32 = 0

        properties : vk.PhysicalDeviceProperties
        vk.GetPhysicalDeviceProperties(device, &properties)

        device_type_score := PHYSICAL_DEVICE_TYPE_SCORE
        device_score += device_type_score[properties.deviceType]
    }
}