package boco_renderer

import "../boco_window"

// TODO: Not really a fan of this structure, weird for scene to have the view area
// TODO: View area needs to be updated on resize
// TODO: Extract View area and allow rendering a scene to any view area and reusing same scene for multiple view areas.
Scene :: struct {
    // Identification things
    name: string,

    // Where to render
    window: boco_window.Window,
    view_area: boco_window.ViewArea,
    camera: Camera,
    clear_value: [4]f32, // NOTE: This is just to see difference between current view areas, not neccessary

    // What to render
    static_meshes: []^IndexedMesh, // Meshes which exist the entire duration of the scene.
    meshes: [dynamic]^IndexedMesh, // Meshes which are added and removed throughout the scene. probably still want to preallocate size as this could result in some optimization issues if need to reallocate entire array.
}

change_scene :: proc(using renderer: ^Renderer) {
    current_scene_id = (current_scene_id + 1) % cast(u32)len(scenes)
}