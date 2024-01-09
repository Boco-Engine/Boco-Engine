package boco_ecs

MAX_ENTITIES :: 5000

Entity :: distinct u32

Entities :: struct {
    is_available: [MAX_ENTITIES]bool,
    component_signature: [MAX_ENTITIES]ComponentSignature,
    entity_count: u32,

    last_taken: u32,
}

create_entity :: proc(using entities: ^Entities) -> (id: u32) {
    for {
        last_taken = (last_taken + 1) % MAX_ENTITIES
        if is_available[last_taken] {
            id = last_taken
            is_available[last_taken] = false
            break
        }
    }

    entity_count += 1

    return
}

remove_entity :: proc(using entities: ^Entities, id: u32) {
    is_available[id] = true
    component_signature[id] = {}
    entity_count -= 1
}

enable_components :: proc(using entites: ^Entities, id: u32, signiture: ComponentSignature) {
    component_signature[id] += signiture;
}

disable_components :: proc(using entites: ^Entities, id: u32, signature: ComponentSignature) {
    component_signature[id] -= signature;
}