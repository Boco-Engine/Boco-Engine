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

RendererInternals :: struct {
    instance: vk.Instance,
    physical_device: vk.PhysicalDevice,
    logical_device: vk.Device,

    debug_messenger: vk.DebugUtilsMessengerEXT,
    enabled_features: RendererFeatures
}

// TODO: Add Vulkan debug callback for more detailed messages.
// TODO: Allow changing GPU in use.
init_vulkan :: proc(using renderer: ^Renderer) -> (ok: bool = false) {
    log.info("Creating Vulkan resources")
    vk.load_proc_addresses(cast(rawptr)vkGetInstanceProcAddr)

    init_instance(renderer)

    when ODIN_DEBUG {
        init_debug_messenger(renderer)
    }

    query_best_device(renderer)

    init_device(renderer)

    return true
}

cleanup_vulkan :: proc(using renderer: ^Renderer) {
    log.info("Cleaning Vulkan resources")

    when ODIN_DEBUG {
        vk.DestroyDebugUtilsMessengerEXT(instance, debug_messenger, nil)
    }

    vk.DestroyInstance(instance, nil)
}

init_instance :: proc(using renderer: ^Renderer) -> (ok: bool = false) {
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
    // TODO: Need to query window/os for what extensions we need.

    layers := [dynamic]cstring{}
    extensions := [dynamic]cstring {vk.KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME}

    
    debug_messenger_info : vk.DebugUtilsMessengerCreateInfoEXT
    when ODIN_DEBUG {
        log.info("Validaion layers set")
        append(&layers, "VK_LAYER_KHRONOS_validation")
        append(&extensions, vk.EXT_DEBUG_UTILS_EXTENSION_NAME)

        fill_debug_messenger_info(&debug_messenger_info)
        instance_info.pNext = cast(^vk.DebugUtilsMessengerCreateInfoEXT)&debug_messenger_info
    }

    verify_layer_support(layers[:]) or_return
    verify_extension_support(layers[:], extensions[:])

    instance_info.enabledExtensionCount = auto_cast len(extensions)
    instance_info.ppEnabledExtensionNames = &extensions[0]

    instance_info.enabledLayerCount = auto_cast len(extensions)
    instance_info.ppEnabledLayerNames = &extensions[0] if len(extensions) > 0 else nil

    instance_info.enabledLayerCount = auto_cast len(layers)
    instance_info.ppEnabledLayerNames = &layers[0] if len(layers) > 0 else nil

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

init_device :: proc(using renderer: ^Renderer) -> (ok: bool = false) {
    query_family_queues(renderer, {.GRAPHICS, .COMPUTE})

    device_info : vk.DeviceCreateInfo
    device_info.sType = .DEVICE_CREATE_INFO

    return true
}