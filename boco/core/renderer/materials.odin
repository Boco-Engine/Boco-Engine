package renderer

PolygonMode :: enum {
    FILL,
    LINE,
    POINT,
}

CullingMode :: enum {
    BACK,
    FRONT,
    NONE,
}

MaterialID :: u32

Material :: struct {
    id: MaterialID,

    polygon_mode: PolygonMode,
    culling_mode: CullingMode,
    
    shaders: []Shader,
}

init_material  :: proc(renderer: ^Renderer, material: ^Material) {
    material.id = renderer._next_material_id
    renderer._next_material_id += 1
}