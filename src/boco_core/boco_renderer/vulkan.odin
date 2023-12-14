//+private
package boco_renderer

import "core:c"
import "core:log"
import "core:fmt"
import vk "vendor:vulkan"
import sdl "vendor:sdl2"

foreign import vulkan "vulkan-1.lib"

// @(default_calling_convention="c")
foreign vulkan {
    vkGetInstanceProcAddr :: proc(vk.Instance, cstring) -> rawptr ---
}

RendererInternals :: struct {
    instance: vk.Instance
}

create_instance :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
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

    log.info("Created Instance")

    return
}

init_vulkan :: proc(using renderer: ^Renderer) -> (ok: bool = true) {
    log.info("Creating Vulkan resources")
	vk.load_proc_addresses(cast(rawptr)vkGetInstanceProcAddr)

    create_instance(renderer)

    return
}

cleanup_vulkan :: proc(using renderer: ^Renderer) {
    log.info("Cleaning Vulkan resources")
    vk.DestroyInstance(instance, nil)
}