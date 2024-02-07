package boco_renderer

import "core:c"
import "core:log"
import "core:fmt"
import vk "vendor:vulkan"
import sdl "vendor:sdl2"
import "../boco_window"
import "../../benchmarks"

import "../boco_ecs"

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
    // Vulkan Objects
    instance: vk.Instance,
    physical_device: vk.PhysicalDevice,
    logical_device: vk.Device,
    old_swapchain: vk.SwapchainKHR,
    swapchain: vk.SwapchainKHR,
    render_pass: vk.RenderPass,
    framebuffers: []vk.Framebuffer,
    descriptor_pool: vk.DescriptorPool,
    ui_descriptor_pool: vk.DescriptorPool,
    pipeline_layout: vk.PipelineLayout,
    graphics_pipeline: vk.Pipeline,
    // NOTE: Only 1 queue of each type, might want to expand this later.
    queues: [QueueFamilyType]vk.Queue,
    surface: vk.SurfaceKHR,

    // Resources
    // Can pre allocate this to some max size, wont be too large and would keep data more local.
    swapchain_images: []vk.Image,
    swapchain_imageviews: []vk.ImageView,

    depth_images: []vk.Image,
    depth_memory: []vk.DeviceMemory,
    depth_imageviews: []vk.ImageView,

    // Options
    enabled_features: RendererFeatures,
    queue_family_indices: [QueueFamilyType]u32,
    swapchain_settings: SwapchainSettings,
    sample_count: vk.SampleCountFlags,

    // For Rendering
    command_pool: vk.CommandPool,
    command_buffers: []vk.CommandBuffer,
    viewport : vk.Viewport,
    scissor: vk.Rect2D,
    current_frame_index: u32,

    // Synchronization
    image_available: []vk.Semaphore,
    render_finished: []vk.Semaphore,
    in_flight: []vk.Fence,
    
    // DEBUG
    debug_messenger: vk.DebugUtilsMessengerEXT,
}

// TODO: Add Vulkan debug callback for more detailed messages.
// TODO: Allow changing GPU in use.
init_vulkan :: proc(using renderer: ^Renderer) -> (ok: bool = false) 
{  
    log.info("Creating Vulkan resources")
    vk.load_proc_addresses(cast(rawptr)vkGetInstanceProcAddr)

    sample_count = {._1}

    // TODO: Should query window for needed layers!
    layers := [dynamic]cstring{}

    instance_extensions := [dynamic]cstring{
        // vk.KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
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
        init_debug_messenger(renderer) or_return
    }

    init_surface(renderer) or_return

    query_best_device(renderer) or_return

    init_device(renderer, layers[:], device_extensions[:]) or_return

    swapchain_settings = get_swapchain_settings(renderer)
    init_swapchain(renderer)

    vk.GetSwapchainImagesKHR(logical_device, swapchain, &swapchain_settings.image_count, nil)
    swapchain_images = make([]vk.Image, swapchain_settings.image_count)
    vk.GetSwapchainImagesKHR(logical_device, swapchain, &swapchain_settings.image_count, &swapchain_images[0])

    swapchain_imageviews = make([]vk.ImageView, swapchain_settings.image_count)
    retrieve_swapchain_images(renderer)

    depth_images = make([]vk.Image, swapchain_settings.image_count)
    depth_memory = make([]vk.DeviceMemory, swapchain_settings.image_count)
    depth_imageviews = make([]vk.ImageView, swapchain_settings.image_count)
    init_depth_resources(renderer)

    init_render_pass(renderer)

    create_pipeline_layout(renderer)

    // TODO: This needs to be managed somehow to be the render areas size, not entire windows!
	scissor.extent = {main_window.width, main_window.height}
	viewport.width = cast(f32)main_window.width
	viewport.height = cast(f32)main_window.height
	viewport.minDepth = 0.0
	viewport.maxDepth = 1.0
    
    create_graphics_pipeline(renderer)

    framebuffers = make([]vk.Framebuffer, swapchain_settings.image_count)
    create_framebuffers(renderer)

    create_command_pool(renderer)

    create_command_buffers(renderer)

    image_available =   make([]vk.Semaphore,    swapchain_settings.image_count)
    render_finished =   make([]vk.Semaphore,    swapchain_settings.image_count)
    in_flight       =   make([]vk.Fence,        swapchain_settings.image_count)
    create_semaphores_and_fences(renderer)

    return true
}

on_resize :: proc(using renderer: ^Renderer) {
    vk.DeviceWaitIdle(logical_device)

    for i in 0..<swapchain_settings.image_count {
        vk.FreeMemory(logical_device, depth_memory[i], nil)
        vk.DestroyImageView(logical_device, depth_imageviews[i], nil)
        vk.DestroyImage(logical_device, depth_images[i], nil)

        vk.DestroyImageView(logical_device, swapchain_imageviews[i], nil)
        vk.DestroyFramebuffer(logical_device, framebuffers[i], nil)

        vk.DestroyFence(logical_device, in_flight[i], nil)
        vk.DestroySemaphore(logical_device, render_finished[i], nil)
        vk.DestroySemaphore(logical_device, image_available[i], nil)
    }

    boco_window.update_size(main_window);

    init_swapchain(renderer)
    vk.GetSwapchainImagesKHR(logical_device, swapchain, &swapchain_settings.image_count, &swapchain_images[0])

    retrieve_swapchain_images(renderer)
    init_depth_resources(renderer)
    create_framebuffers(renderer)

    create_semaphores_and_fences(renderer)
}

cleanup_vulkan :: proc(using renderer: ^Renderer) {
    log.info("Cleaning Vulkan resources")

    for i in 0..<swapchain_settings.image_count {
        vk.FreeMemory(logical_device, depth_memory[i], nil)
        vk.DestroyImageView(logical_device, depth_imageviews[i], nil)
        vk.DestroyImage(logical_device, depth_images[i], nil)
    }

    vk.DeviceWaitIdle(logical_device)

    for i in 0..<swapchain_settings.image_count {
        vk.DestroySemaphore(logical_device, image_available[i], nil)
        vk.DestroySemaphore(logical_device, render_finished[i], nil)
        vk.DestroyFence(logical_device, in_flight[i], nil)
    }
    delete(image_available)
    delete(render_finished)
    delete(in_flight)

    vk.DestroyCommandPool(logical_device, command_pool, nil)
    delete(command_buffers)
    for framebuffer in framebuffers {
        vk.DestroyFramebuffer(logical_device, framebuffer, nil)
    }
    delete(framebuffers)
    vk.DestroyPipeline(logical_device, graphics_pipeline, nil)
    vk.DestroyPipelineLayout(logical_device, pipeline_layout, nil)
    vk.DestroyDescriptorPool(logical_device, ui_descriptor_pool, nil)
    vk.DestroyDescriptorPool(logical_device, descriptor_pool, nil)
    vk.DestroyRenderPass(logical_device, render_pass, nil)
    for &imageview in swapchain_imageviews {
        vk.DestroyImageView(logical_device, imageview, nil)
    }
    delete(swapchain_images)
    delete(swapchain_imageviews)
    vk.DestroySwapchainKHR(logical_device, swapchain, nil)
    vk.DestroyDevice(logical_device, nil)
    vk.DestroySurfaceKHR(instance, surface, nil)
    when ODIN_DEBUG {
        vk.DestroyDebugUtilsMessengerEXT(instance, debug_messenger, nil)
    }
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
        log.error("Failed initialising Vulkan Instance: ", res)
        return false
    }

    vk.load_proc_addresses(instance);

    log.info("Created Instance")

    return true
}

init_surface :: proc(using renderer: ^Renderer) -> bool {
    log.info("Creating Surface")
    boco_window.create_window_surface(main_window, renderer.instance, &surface)
    return true
}

init_debug_messenger :: proc(using renderer: ^Renderer) -> (ok: bool = false) {
    debug_messenger_info : vk.DebugUtilsMessengerCreateInfoEXT
    fill_debug_messenger_info(&debug_messenger_info)
    res := vk.CreateDebugUtilsMessengerEXT(instance, &debug_messenger_info, nil, &debug_messenger)
    log.info(res)

    return true
}

init_device :: proc(using renderer: ^Renderer, layers, extensions: []cstring) -> (ok: bool = false) {
    log.info("Creating Device")
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
    device_info.ppEnabledLayerNames = &layers[0] if len(layers) > 0 else nil
    device_info.enabledExtensionCount = auto_cast len(extensions)
    device_info.ppEnabledExtensionNames = &extensions[0] if len(extensions) > 0 else nil
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

init_swapchain :: proc(using renderer: ^Renderer) -> (ok: bool = false) {
    caps : vk.SurfaceCapabilitiesKHR
    vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, &caps)

    extent : vk.Extent2D = caps.currentExtent

    temp := old_swapchain
    old_swapchain = swapchain
    
    info : vk.SwapchainCreateInfoKHR
    info.sType = .SWAPCHAIN_CREATE_INFO_KHR
    info.surface = surface
    info.minImageCount = swapchain_settings.image_count
    info.imageFormat = swapchain_settings.surface_format.format
    info.imageColorSpace = swapchain_settings.surface_format.colorSpace
    info.imageExtent = extent
    info.imageArrayLayers = 1
    info.imageUsage = {.COLOR_ATTACHMENT}
    info.imageSharingMode = .EXCLUSIVE
    info.preTransform = swapchain_settings.transform
    info.compositeAlpha = {.OPAQUE}
    info.presentMode = swapchain_settings.present_mode
    info.clipped = true
    info.oldSwapchain = old_swapchain

    
    res := vk.CreateSwapchainKHR(logical_device, &info, nil, &swapchain)
    if res != .SUCCESS {
        log.error("Failed creating swapchain: ", res);
        return false
    }
    log.info("Created Swapchain")
    
    // vk.DestroySwapchainKHR(logical_device, temp, nil)

    return true
}

retrieve_swapchain_images :: proc(using renderer: ^Renderer) {
    // Overwrites what we set as image count to actual used, as vulkan might use different amount.
    for image, index in swapchain_images {
        swapchain_imageviews[index] = create_imageview(renderer, swapchain_images[index], swapchain_settings.surface_format.format, {.COLOR})
    }
}

init_render_pass :: proc(using renderer: ^Renderer) -> bool {
    // TODO: Add Depth, Multisample, ...
    attachment_descriptions: [2]vk.AttachmentDescription

    // Output Attachment
    attachment_descriptions[0].format = swapchain_settings.surface_format.format
    attachment_descriptions[0].loadOp = .CLEAR
    attachment_descriptions[0].storeOp = .STORE
    attachment_descriptions[0].initialLayout = .UNDEFINED
    attachment_descriptions[0].finalLayout = .PRESENT_SRC_KHR
    attachment_descriptions[0].samples = sample_count

    // TODO: Store information in renderer so that we can change anytime
    attachment_descriptions[1].format = .D24_UNORM_S8_UINT
    attachment_descriptions[1].loadOp = .CLEAR
    attachment_descriptions[1].storeOp = .STORE
    attachment_descriptions[1].stencilLoadOp = .DONT_CARE
    attachment_descriptions[1].stencilStoreOp = .DONT_CARE
    attachment_descriptions[1].initialLayout = .UNDEFINED
    attachment_descriptions[1].finalLayout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL
    attachment_descriptions[1].samples = sample_count

    // Dependencies
    dependencies: [1]vk.SubpassDependency
    dependencies[0].srcStageMask = {.COLOR_ATTACHMENT_OUTPUT, .EARLY_FRAGMENT_TESTS}
    dependencies[0].srcAccessMask = {}
    dependencies[0].dstStageMask = {.COLOR_ATTACHMENT_OUTPUT, .EARLY_FRAGMENT_TESTS}
    dependencies[0].dstAccessMask = {.COLOR_ATTACHMENT_WRITE, .DEPTH_STENCIL_ATTACHMENT_WRITE}
    dependencies[0].srcSubpass = vk.SUBPASS_EXTERNAL
    dependencies[0].dstSubpass = 0

    // References
    references: [2]vk.AttachmentReference

    // Output Ref
    references[0].attachment = 0
    references[0].layout = .COLOR_ATTACHMENT_OPTIMAL

    references[1].attachment = 1
    references[1].layout = .DEPTH_STENCIL_ATTACHMENT_OPTIMAL

    subpass_descriptions: [1]vk.SubpassDescription
    subpass_descriptions[0].colorAttachmentCount = 1
    subpass_descriptions[0].pColorAttachments = &references[0]
    subpass_descriptions[0].inputAttachmentCount = 0
    subpass_descriptions[0].pInputAttachments = nil
    subpass_descriptions[0].pDepthStencilAttachment = &references[1]
    subpass_descriptions[0].pPreserveAttachments = nil
    subpass_descriptions[0].pResolveAttachments = nil
    subpass_descriptions[0].pipelineBindPoint = .GRAPHICS

    // Renderpass
    render_pass_info: vk.RenderPassCreateInfo
    render_pass_info.sType = .RENDER_PASS_CREATE_INFO
    render_pass_info.attachmentCount = len(attachment_descriptions)
    render_pass_info.pAttachments = &attachment_descriptions[0]
    render_pass_info.dependencyCount = len(dependencies)
    render_pass_info.pDependencies = &dependencies[0]
    render_pass_info.subpassCount = len(subpass_descriptions)
    render_pass_info.pSubpasses = &subpass_descriptions[0]

    res := vk.CreateRenderPass(logical_device, &render_pass_info, nil, &render_pass)
    if res != .SUCCESS do return false

    return true
}

create_framebuffers :: proc(using renderer: ^Renderer) -> bool {
    for &imageview, index in swapchain_imageviews {
        // TODO: Add Attachments for depth, multiview, ...
        attachments := [?]vk.ImageView{
            imageview,
            depth_imageviews[index],
        }

        // FRAMEBUFFER
        framebuffer_info: vk.FramebufferCreateInfo
        framebuffer_info.sType = .FRAMEBUFFER_CREATE_INFO
        framebuffer_info.attachmentCount = cast(u32)len(attachments)
        framebuffer_info.pAttachments = &attachments[0]
        framebuffer_info.width = main_window.width
        framebuffer_info.height = main_window.height
        framebuffer_info.layers = 1
        framebuffer_info.renderPass = render_pass

        vk.CreateFramebuffer(logical_device, &framebuffer_info, nil, &framebuffers[index])
    }

    return true
}

create_command_pool :: proc(using renderer: ^Renderer) -> bool {
    command_pool_info : vk.CommandPoolCreateInfo
	command_pool_info.sType = .COMMAND_POOL_CREATE_INFO
	command_pool_info.flags = {.RESET_COMMAND_BUFFER}
	command_pool_info.queueFamilyIndex = cast(u32)queue_family_indices[.GRAPHICS]

	vk.CreateCommandPool(logical_device, &command_pool_info, nil, &command_pool)

    return true
}

create_command_buffers :: proc(using renderer: ^Renderer) -> bool {
    command_buffers = make([]vk.CommandBuffer, swapchain_settings.image_count)

    // Making a command buffer for each swapchain image. probably need to extend this.
    allocate_info: vk.CommandBufferAllocateInfo
	allocate_info.sType = .COMMAND_BUFFER_ALLOCATE_INFO
	allocate_info.commandPool = command_pool
	allocate_info.level = .PRIMARY
	allocate_info.commandBufferCount = swapchain_settings.image_count

	vk.AllocateCommandBuffers(logical_device, &allocate_info, &command_buffers[0])

    return true
}

create_semaphores_and_fences :: proc(using renderer: ^Renderer) {
	for i in 0..<swapchain_settings.image_count {
		semaphore_info: vk.SemaphoreCreateInfo
		semaphore_info.sType = .SEMAPHORE_CREATE_INFO

		vk.CreateSemaphore(logical_device, &semaphore_info, nil, &image_available[i])
		vk.CreateSemaphore(logical_device, &semaphore_info, nil, &render_finished[i])

		fence_info: vk.FenceCreateInfo
		fence_info.sType = .FENCE_CREATE_INFO
		fence_info.flags = {.SIGNALED}
		vk.CreateFence(logical_device, &fence_info, nil, &in_flight[i])
	}
}

init_depth_resources :: proc(using renderer: ^Renderer) {
    for i in 0..<swapchain_settings.image_count {
        ret : vk.Result
        depth_images[i], ret = create_image(renderer,
            .D24_UNORM_S8_UINT,
            {main_window.width, main_window.height, 1},
            sample_count,
            {.DEPTH_STENCIL_ATTACHMENT},
        )

        requirements: vk.MemoryRequirements
        vk.GetImageMemoryRequirements(logical_device, depth_images[i], &requirements)
        
        memory_info : vk.MemoryAllocateInfo
        memory_info.sType = .MEMORY_ALLOCATE_INFO
        memory_info.memoryTypeIndex = get_memory_from_properties(renderer, {.DEVICE_LOCAL})
        memory_info.allocationSize = requirements.size

        vk.AllocateMemory(logical_device, &memory_info, nil, &depth_memory[i])
        
        vk.BindImageMemory(logical_device, 
            depth_images[i],
            depth_memory[i],
            0,
         )

        depth_imageviews[i] = create_imageview(renderer,
            depth_images[i],
            .D24_UNORM_S8_UINT,
            {vk.ImageAspectFlag.DEPTH, vk.ImageAspectFlag.STENCIL},
        )
    }
}