package boco_renderer

import "core:log"
import vk "vendor:vulkan"
import "core:mem"

create_imageview :: proc(using renderer: ^Renderer, image: vk.Image, format: vk.Format, aspect_mask: vk.ImageAspectFlags) -> (image_view: vk.ImageView){
    info : vk.ImageViewCreateInfo
    info.sType = .IMAGE_VIEW_CREATE_INFO
    info.pNext = nil
    info.flags = {}
    info.image = image
    info.viewType = .D2
    info.format = format
    info.components = {r = .IDENTITY, g = .IDENTITY, b = .IDENTITY, a = .IDENTITY}
    info.subresourceRange = {
        aspectMask = aspect_mask,
        baseMipLevel = 0,
        levelCount = 1,
        baseArrayLayer = 0,
        layerCount = 1,
    }

    vk.CreateImageView(logical_device, &info, nil, &image_view)

    return
}

allocate_buffer :: proc(using renderer: ^Renderer, $T: typeid, data_size: u64, usage: vk.BufferUsageFlags, buffer_resource: ^BufferResources) {
    buffer_size : vk.DeviceSize = auto_cast (size_of(T) * data_size)

    info : vk.BufferCreateInfo
    info.sType = .BUFFER_CREATE_INFO
    info.usage = usage
    info.size = buffer_size
    info.sharingMode = .EXCLUSIVE

    vk.CreateBuffer(logical_device, &info, nil, &buffer_resource.buffer)
    
    memory_requirementes : vk.MemoryRequirements
    vk.GetBufferMemoryRequirements(logical_device, buffer_resource.buffer, &memory_requirementes)

    memory_info: vk.MemoryAllocateInfo
    memory_info.sType = .MEMORY_ALLOCATE_INFO
    memory_info.allocationSize = memory_requirementes.size
    // TODO: Allow passing in what type of memory we actually need.
    memory_info.memoryTypeIndex = get_memory_from_properties(renderer, {.HOST_VISIBLE, .HOST_COHERENT})

    vk.AllocateMemory(logical_device, &memory_info, nil, &buffer_resource.memory)

    vk.BindBufferMemory(logical_device, buffer_resource.buffer, buffer_resource.memory, 0)
}

// TODO: Dont always need to unmap memory, might want to provide method for mapping memory and keeping it mapped.
write_to_buffer :: proc(using renderer: ^Renderer, buffer_resource: ^BufferResources, data: []$T, write_offset: u64) {
    data_size : vk.DeviceSize = auto_cast (size_of(T) * len(data))
    
    vk.MapMemory(logical_device, buffer_resource.memory, cast(vk.DeviceSize)write_offset, data_size, {}, &buffer_resource.data_ptr)

    mem.copy(buffer_resource.data_ptr, &data[0], cast(int)data_size)

    vk.UnmapMemory(logical_device, buffer_resource.memory)
}