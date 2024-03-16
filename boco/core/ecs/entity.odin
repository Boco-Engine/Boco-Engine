package ecs

import "core:reflect"
import "core:log"
import "core:container/queue"

import "boco:core/types"

// HACK: TEMP DELETE THIS
Transform :: struct {
    position: types.dVec3,
    rotation: types.Vec3,
    scale: types.Vec3,
}


Entity :: distinct u32

Entities :: struct {
    data                : [dynamic]Entity,

    signatures          : map[Entity]ComponentSignature,
    states              : map[Entity]State,

    _next_entity        : Entity,
    free_ids            : [dynamic]Entity,
}

entities_init :: proc(entities: ^Entities, initial_capacity: int) {
    reserve(&entities.data, initial_capacity)
}

entities_deinit :: proc(using entities: ^Entities) {
    delete(data)
    delete(signatures)
    delete(states)
    delete(free_ids)
}

entity_make :: proc(using universe: ^ECS) -> Entity {
    id : Entity

    if len(entities.free_ids) > 0 {
        id = pop(&entities.free_ids)
    } else {
        id = entities._next_entity
        entities._next_entity += 1
    }
    append(&entities.data, id)

    return id
}

entity_destroy :: proc(using universe: ^ECS, entity: Entity) {
    // FREE IDS
    append(&entities.free_ids, entity)

    // REMOVE ALL COMPONENTS + MAKE SURE SYSTEMS NO LONGER KEEP TRACK
    for _, i in universe.component_lists {        
        if (has_component(universe, (component_types[auto_cast i]), entity)) {
            component_destroy(universe, component_types[auto_cast i], entity)
        }
    }

    // DELETE KEYS IN MAPS
    delete_key(&entities.signatures, entity)
    delete_key(&entities.states, entity)

    // REMOVE FROM ENTITIES LIST
    for e, i in entities.data {
        if e != entity do continue
        unordered_remove(&entities.data, i)
        break
    }
}