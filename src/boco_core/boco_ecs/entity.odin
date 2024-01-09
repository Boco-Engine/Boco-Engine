package boco_ecs

import "core:container/queue"

Entity :: distinct u32

EntityManager :: struct(max_entities: u32) {
    entities: queue.Queue(Entity),
    component_signatures: [max_entities]ComponentSignature,

    MAX_ENTITIES: u32,
    entities_in_use: u32
}

init_entity_manager :: proc(using entity_manager: ^EntityManager($N)) {
    MAX_ENTITIES = len(component_signatures)

    queue.init(&entities, auto_cast MAX_ENTITIES)

    for i in 0..<MAX_ENTITIES {
        queue.push_back(&entities, auto_cast i);
    }
}

@(require_results)
create_entity :: proc(using entity_manager: ^EntityManager($N)) -> Entity {
    assert(entities_in_use < MAX_ENTITIES, "Reached entity capacity, increase size or use less.")
    entities_in_use += 1
    return queue.pop_front(&entities)
}

destroy_entity :: proc(using entity_manager: ^EntityManager($N), entity: Entity) -> bool {
    assert(entities_in_use > 0, "No Entities used and therefore none should be getting destroyed.")
    assert(entity < MAX_ENTITIES, "Invalid entity provided, outside of possible values.")
    entities_in_use -= 1
    ok, _ := queue.push_back(&entities, entity)
    return ok
}

set_signature :: proc(using entity_manager: ^EntityManager($N), entity: Entity, signature: ComponentSignature) {
    assert(entity < MAX_ENTITIES, "Invalid entity provided, outside of possible values.")
    component_signatures[entity] = signature
}