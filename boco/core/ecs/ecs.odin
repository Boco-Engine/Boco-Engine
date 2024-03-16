package ecs

import "core:log"
import "core:runtime"

State :: enum {
    ACTIVE,
    ASLEEP,
    DEAD,
}

ECS :: struct {
    entities: Entities,

    // NOTE: Type is Components(T) Where T is the components type.
    component_lists: [dynamic]Components,
    registered_components: [dynamic]typeid,

    systems: [dynamic]^System,

    component_ids: map[typeid]ComponentID,
    component_types: map[ComponentID]typeid,

    _next_entity: Entity,
    _next_component_id: ComponentID,
    _next_system_id: SystemID,

    free_component_ids: [dynamic]ComponentID,
}

universe_init :: proc(universe: ^ECS, initial_capacity: int) {
    reserve(&universe.component_lists, 64)
    entities_init(&universe.entities, initial_capacity)
}

universe_deinit :: proc(universe: ^ECS) {
    for _, index in universe.systems {
        system_destroy(universe, universe.systems[index])
    }
    delete(universe.systems)

    for component_type in universe.registered_components {
        component_unregister(universe, component_type)
    }
    delete(universe.component_lists)

    entities_deinit(&universe.entities)

    delete(universe.component_ids)
    delete(universe.component_types)
    delete(universe.free_component_ids)
}

universe_make :: proc(intitial_capacity: int) -> ^ECS {
    universe := new(ECS)
    universe_init(universe, intitial_capacity)
    return universe
}

universe_destroy :: proc(universe: ^ECS) {
    universe_deinit(universe)
    free(universe)
}

universe_update :: proc(engine: ^any, universe: ^ECS) {
    for _, index in universe.systems {
        if universe.systems[index].update_every_frame do universe.systems[index].action(engine, universe, universe.systems[index])
    }
}