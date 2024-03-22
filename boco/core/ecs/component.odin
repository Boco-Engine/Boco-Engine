package ecs

import "core:log"
import "core:runtime"
import "core:mem"

ComponentID :: u64

// A way to quickly check which components a entity has or what components a system needs.
ComponentSignature :: bit_set[0..<64; ComponentID]

// NOTE: Not a fan of the double map, but need a way to keep track of both for deletion.
Components :: struct {
    data            : [dynamic]byte,
    entity_indices  : map[Entity]u32,
    index_owners    : map[u32]Entity,
}

components_get :: proc(ecs: ^ECS, component_type: typeid) -> ^Components {
    component_index := ecs.component_ids[component_type]
    return &ecs.component_lists[component_index]
}

component_make :: proc(using universe: ^ECS, $component_type: typeid, entity: Entity) -> ^component_type {
    components := components_get(universe, component_type)

    resize(&components.data, len(components.data) + size_of(component_type))

    components.entity_indices[entity] = cast(u32)(len(components.data) / size_of(component_type)) - 1
    components.index_owners[components.entity_indices[entity]] = entity

    old_signature := entities.signatures[entity]
    entities.signatures[entity] += ComponentSignature{auto_cast get_component_id(universe, component_type)}

    system_loop: for _, index in universe.systems {
        // If the old signature matches, the entity should already be part of the system.
        if (old_signature & systems[index].signature) == systems[index].signature do continue 

        if (entities.signatures[entity] & systems[index].signature) == systems[index].signature {
            append(&systems[index].entities, entity)
        }
    }

    component := cast(^component_type)&components.data[len(components.data) - size_of(component_type)]
    return component
}

component_destroy :: proc(using universe: ^ECS, component_type: typeid, entity: Entity) {
    components := components_get(universe, component_type)

    type_size := type_info_of(component_type).size

    end_entity := components.index_owners[auto_cast ((len(components.data) - type_size) / type_size)]
    a, ok := components.entity_indices[end_entity]

    // Swap and resize.
    entity_component := &components.data[components.entity_indices[entity] * u32(type_size)]
    back_component := &components.data[components.entity_indices[end_entity] * u32(type_size)]

    mem.copy(entity_component, back_component, type_size)

    resize(&components.data, len(components.data) - type_size)

    components.entity_indices[end_entity] = components.entity_indices[entity]
    components.index_owners[components.entity_indices[end_entity]] = end_entity

    old_signature := entities.signatures[entity]
    entities.signatures[entity] -= ComponentSignature{auto_cast get_component_id(universe, component_type)}

    system_loop: for _, index in universe.systems {
        // If the old signature doesnt match, the entity should already not be part of the system.
        if (old_signature & systems[index].signature) != systems[index].signature do continue 

        if (entities.signatures[entity] & systems[index].signature) != systems[index].signature {
            // DESIGN: Have to loop all entities in system, is there a way to avoid this?
            for system_entity, system_entity_index in systems[index].entities {
                if entity == system_entity {
                    unordered_remove(&systems[index].entities, system_entity_index)
                    break
                }
            }
        }
    }

    delete_key(&components.entity_indices, entity)
    delete_key(&components.index_owners, auto_cast ((len(components.data)) / type_size))
}

component_register :: proc(universe: ^ECS, $component_type: typeid, initial_capacity : u32) {
    id : ComponentID
    
    if len(universe.free_component_ids) > 0 {
        id = pop(&universe.free_component_ids)
        universe.component_lists[id].data = make([dynamic]byte)
        universe.component_lists[id].entity_indices = make(map[Entity]u32)
        universe.component_lists[id].index_owners = make(map[u32]Entity)
    } else {
        id = universe._next_component_id
        universe._next_component_id += 1
        append(&universe.component_lists, Components{})
    }

    components := universe.component_lists[id]
    reserve(&components.data, cast(int)initial_capacity * size_of(component_type))

    universe.component_ids[component_type] = id
    universe.component_types[id] = component_type
    
    log.info("Registered:", type_info_of(component_type), "\b, ID:", universe.component_ids[component_type])
}

component_unregister :: proc(universe: ^ECS, component_type: typeid) {
    components := components_get(universe, component_type)

    delete(components.data)
    delete(components.entity_indices)
    delete(components.index_owners)
    
    append(&universe.free_component_ids, get_component_id(universe, component_type))

    delete_key(&universe.component_ids, component_type)
}

get_component_id :: proc(universe: ^ECS, component_type: typeid) -> ComponentID {
    return universe.component_ids[component_type]
}

get_component :: proc(universe: ^ECS, $component_type: typeid, entity: Entity) -> ^component_type {
    components := components_get(universe, component_type)
    
    entity_component_index, exists := components.entity_indices[entity]
    if !exists do return nil


    component := transmute(^component_type)&components.data[entity_component_index * size_of(component_type)]

    return component
}

has_component :: proc(universe: ^ECS, component_type: typeid, entity: Entity) -> bool {
    components := components_get(universe, component_type)
    
    _, exists := components.entity_indices[entity]

    return exists
}
