package boco_ecs

import "core:log"
import "core:runtime"

// TODO: Benchmark either using entity id as index or mapping for better packing
Components :: struct($T: typeid) {
    members: []T
}

// I guess we need to guarantee that all systems are in place for the ecs before entities are assigned components
// Then on adding components check all systems, and if requirements are met we add the entity to the system
// Need to register components before sytems as well, so that we can get component ids for use in the system
ECS :: struct($max_entities : u32) {
    entities: EntityManager(max_entities),
    components: map[typeid]rawptr, // pointer to the array of the components // As we have map id now, we can just store in an array.
    systems: []System(max_entities),

    component_to_id_map: map[typeid]u32,
    component_count: u32,
}

init :: proc(ecs: ^ECS($N), num_components: u32) {
    ecs.components = make(map[typeid]rawptr, num_components)
    init_entity_manager(&ecs.entities)
}

// Currenly preallocating all systems with enough space to hold all entities, maybe for something like this
// A dynamic array will be enough, as this will not run every frame. but maybe this way is better for systems as
// Then theyre also contiguous in memory
System :: struct($max_entities: u32) {
    id: u32,
    requirements: ComponentSignature, // Of component ids

    entities: [max_entities]Entity,
    entity_count: u32,

    actions: proc(^ECS(max_entities)),
}

get_component :: proc(ecs: ^ECS($N), $T: typeid, entity: Entity) -> ^T {
    // info := type_info_of(T).variant.(runtime.Type_Info_Named).name
    return &(cast(^Components(T))(ecs.components[T])).members[entity]
}

// Just resets values back to 0
add_component_to_entity :: proc(ecs: ^ECS($N), $T: typeid, entity: Entity) {
    component := get_component(ecs, T, entity)
    temp := component.component
    component^ = T{}
    component.component = temp
    component.entity = entity
    ecs.entities.component_signatures[entity] += {auto_cast ecs.component_to_id_map[T]}

    for system in &ecs.systems {
        if (ecs.entities.component_signatures[entity] & system.requirements) == system.requirements {
            system.entities[system.entity_count] = entity
            system.entity_count += 1
        }
    }
}

remove_component_from_entity :: proc(esc: ^ECS($N), $T: typeid, entity: Entity) {
    old_signature := ecs.entities.component_signatures[entity]
    ecs.entities.component_signatures[entity] -= ecs.component_to_id_map[T]
    new_signature := ecs.entities.component_signatures[entity]

    for system in &ecs.systems {
        // If old signature of entity matched the sytem but new one doesnt
        if  ((system.requirements & old_signature) == system.requirements) &&
            ((system.requirements & new_signature) != system.requirements) {
                for e, i in system.entities {
                    if e == entity {
                        system.entities[i] = system.entities[system.entities_in_use - 1]
                        system.entities_in_use -= 1
                    }
                }
            }
    }
}

register_component :: proc(ecs: ^ECS($N), $T: typeid) {
    ecs.component_to_id_map[T] = ecs.component_count
    ecs.component_count += 1

    component := new(Components(T))
    component.members = make([]T, ecs.entities.MAX_ENTITIES)
    log.debug(len(component.members))
    ecs.components[T] = cast(rawptr)component
}