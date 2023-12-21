package boco_renderer

import "core:c"
import "core:log"
import "core:fmt"
import vk "vendor:vulkan"
import sdl "vendor:sdl2"

foreign import vulkan "vulkan-1.lib"

QUEUE_FLAGS_MAX_INDEX :: 10

foreign vulkan {
    vkGetInstanceProcAddr :: proc(vk.Instance, cstring) -> rawptr ---
}

DEBUG_MESSENGER_CALLBACK :: proc(
    messageSeverity: vk.DebugUtilsMessageSeverityFlagsEXT, 
    messageTypes: vk.DebugUtilsMessageTypeFlagsEXT, 
    pCallbackData: ^vk.DebugUtilsMessengerCallbackDataEXT, 
    pUserData: rawptr
) -> bool {
    fmt.println("[VULKN] --- [", messageTypes, "] [", messageSeverity, "]", pCallbackData.pMessage)
    return false
}

fill_debug_messenger_info :: proc(debug_messenger_info: ^vk.DebugUtilsMessengerCreateInfoEXT) {
    debug_messenger_info^ = {}
    debug_messenger_info.sType = .DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
    debug_messenger_info.messageSeverity = {.ERROR, .WARNING}
    debug_messenger_info.messageType = {.PERFORMANCE, .VALIDATION, .DEVICE_ADDRESS_BINDING, .GENERAL}
    debug_messenger_info.pfnUserCallback = cast(vk.ProcDebugUtilsMessengerCallbackEXT)DEBUG_MESSENGER_CALLBACK
    debug_messenger_info.pUserData = nil
}

QueueFamilyType :: enum {
	GRAPHICS,
	COMPUTE 
}

RendererInternals :: struct {
    instance: vk.Instance,
    physical_device: vk.PhysicalDevice,
    logical_device: vk.Device,

    debug_messenger: vk.DebugUtilsMessengerEXT,
    enabled_features: RendererFeatures,

    // NOTE: Only 1 queue of each type, might want to expand this later.
    queues: [QueueFamilyType]vk.Queue,

    queue_family_indices: [QueueFamilyType]u32
}

// TODO: Add Vulkan debug callback for more detailed messages.
// TODO: Allow changing GPU in use.
init_vulkan :: proc(using renderer: ^Renderer) -> (ok: bool = false) 
{
    log.info("Creating Vulkan resources")
    vk.load_proc_addresses(cast(rawptr)vkGetInstanceProcAddr)

    // TODO: Should query window for needed layers!
    layers := [dynamic]cstring{}

    instance_extensions := [dynamic]cstring{
        vk.KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
        "VK_KHR_win32_surface",
        vk.KHR_SURFACE_EXTENSION_NAME,
    }

    device_extensions := [dynamic]cstring{
        vk.KHR_SWAPCHAIN_EXTENSION_NAME,
    }

    defer {
        delete(layers)
        delete(instance_extensions)
        delete(device_extensions)
    }
    
    when ODIN_DEBUG {
        log.info("Validaion layers added")
        append(&layers, "VK_LAYER_KHRONOS_validation")
        append(&layers, "VK_LAYER_LUNARG_monitor")

        append(&instance_extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)
    }

    init_instance(renderer, layers[:], instance_extensions[:]) or_return

    when ODIN_DEBUG {
        init_debug_messenger(renderer)
    }

    query_best_device(renderer)

    init_device(renderer, layers[:], device_extensions[:]) or_return

    return true
}

cleanup_vulkan :: proc(using renderer: ^Renderer) {
    log.info("Cleaning Vulkan resources")

    when ODIN_DEBUG {
        vk.DestroyDebugUtilsMessengerEXT(instance, debug_messenger, nil)
    }

    vk.DestroyDevice(logical_device, nil)
    vk.DestroyInstance(instance, nil)
}

init_instance :: proc(using renderer: ^Renderer, layers, extensions: []cstring) -> (ok: bool = false) {
    application_info : vk.ApplicationInfo
    application_info.sType = .APPLICATION_INFO
    // NOTE: Guess for this might be user application stuff we want to place.
    application_info.pApplicationName = "Application Name"
    application_info.applicationVersion = vk.MAKE_VERSION(0, 1, 0)
    application_info.pEngineName = "Boco Engine"
    application_info.engineVersion = vk.MAKE_VERSION(0, 1, 0)
    application_info.apiVersion = vk.API_VERSION_1_3

    instance_info : vk.InstanceCreateInfo
    instance_info.sType = .INSTANCE_CREATE_INFO
    instance_info.pNext = nil
    instance_info.pApplicationInfo = &application_info

    verify_layer_support(layers[:]) or_return
    verify_instance_extension_support(layers[:], extensions[:]) or_return

    instance_info.enabledExtensionCount = auto_cast len(extensions)
    instance_info.ppEnabledExtensionNames = &extensions[0]

    instance_info.enabledLayerCount = auto_cast len(layers)
    instance_info.ppEnabledLayerNames = &layers[0] if len(layers) > 0 else nil

    instance_info.enabledExtensionCount = auto_cast len(extensions)
    instance_info.ppEnabledExtensionNames = &extensions[0] if len(extensions) > 0 else nil

    debug_messenger_info : vk.DebugUtilsMessengerCreateInfoEXT
    when ODIN_DEBUG {
        fill_debug_messenger_info(&debug_messenger_info)
        instance_info.pNext = cast(^vk.DebugUtilsMessengerCreateInfoEXT)&debug_messenger_info
    }

    res := vk.CreateInstance(&instance_info, nil, &instance)
    if res != .SUCCESS {
        log.error("Failed initialising Vulkan Instance")
        log.error(res)
        return false
    }

    vk.load_proc_addresses(instance);

    log.info("Created Instance")

    return true
}

init_debug_messenger :: proc(using renderer: ^Renderer) -> (ok: bool = false) {
    debug_messenger_info : vk.DebugUtilsMessengerCreateInfoEXT
    fill_debug_messenger_info(&debug_messenger_info)
    ret := vk.CreateDebugUtilsMessengerEXT(instance, &debug_messenger_info, nil, &debug_messenger)
    log.info(ret)

    return true
}

init_device :: proc(using renderer: ^Renderer, layers, extensions: []cstring) -> (ok: bool = false) {
    query_family_queues(renderer)
    
    priorities: [1]f32 = {1.0}

    queue_create_infos: [QueueFamilyType]vk.DeviceQueueCreateInfo
    queue_create_infos[.GRAPHICS].sType = .DEVICE_QUEUE_CREATE_INFO
    queue_create_infos[.GRAPHICS].queueFamilyIndex = u32(queue_family_indices[.GRAPHICS])
    queue_create_infos[.GRAPHICS].queueCount = 1
    queue_create_infos[.GRAPHICS].pQueuePriorities = &priorities[0]

    queue_create_infos[.COMPUTE].sType = .DEVICE_QUEUE_CREATE_INFO
    queue_create_infos[.COMPUTE].queueFamilyIndex = u32(queue_family_indices[.COMPUTE])
    queue_create_infos[.COMPUTE].queueCount = 1
    queue_create_infos[.COMPUTE].pQueuePriorities = &priorities[0]

    features: vk.PhysicalDeviceFeatures
    
    for feature in SupportedRendererFeatures {
        if feature not_in enabled_features do continue
        switch feature {
            case .geometryShader:
                features.geometryShader = true
            case .tessellationShader:
                features.tessellationShader = true
            case:
                log.error("Feature added without support being added.")
        }
    }

    device_info: vk.DeviceCreateInfo
    device_info.sType = .DEVICE_CREATE_INFO
    device_info.queueCreateInfoCount = len(queue_create_infos)
    device_info.pQueueCreateInfos = &(queue_create_infos[QueueFamilyType(0)])
    device_info.enabledLayerCount = auto_cast len(layers)
    device_info.ppEnabledLayerNames = &layers[0]
    device_info.enabledExtensionCount = auto_cast len(extensions)
    device_info.ppEnabledExtensionNames = &extensions[0]
    device_info.pEnabledFeatures = &features

    verify_device_extension_support(physical_device, layers[:], extensions[:]) or_return

    (vk.CreateDevice(physical_device, &device_info, nil, &logical_device) == .SUCCESS) or_return
    
	vk.load_proc_addresses(logical_device)

    for queue_type in QueueFamilyType {
        vk.GetDeviceQueue(logical_device, cast(u32)queue_family_indices[queue_type], 0, &queues[queue_type])
    }

    log.info("Created Device")
    return true
}