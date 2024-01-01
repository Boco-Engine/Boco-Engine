package boco_renderer

import "core:log"
import vk "vendor:vulkan"

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
        layerCount = 1
    }

    vk.CreateImageView(logical_device, &info, nil, &image_view)

    return
}