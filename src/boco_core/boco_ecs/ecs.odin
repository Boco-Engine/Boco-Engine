package boco_ecs

import "core:log"
import "core:runtime"

State :: enum {
    ACTIVE,
    ASLEEP,
    DEAD,
}

ECS :: struct {
    entities: [dynamic]Entity,
    components: [dynamic]rawptr,                        // Rawptr here to be converted to ComponentCollection type with the component type passed.
    systems: [dynamic]System,

    entity_indices: map[Entity]u32,
    entity_signatures: map[Entity]ComponentSignature,
    entity_states: map[Entity]State,                    // This can be stored in components instead allowing individual componentes to be disabled.

    component_ids: map[typeid]ComponentID,
    component_types: map[ComponentID]typeid,

    initial_capacity: u32,

    // These are used to keep track of ids. Currently just incremented, meaning if the engine runs for a long time
    // creating new entities constantly we will eventually overflow.
    _next_entity: Entity,
    _next_component_id: ComponentID,
    _next_system_id: SystemID,
}

init :: proc(ecs: ^ECS, initial_capacity: u32 = 2000) {
    ecs.initial_capacity = initial_capacity
    reserve(&ecs.components, 64) // size of components array == bit_set size of signature.
    reserve(&ecs.entities, cast(int)ecs.initial_capacity)
}

update :: proc(engine: ^any, ecs: ^ECS) {
    for _, index in ecs.systems {
        if ecs.systems[index].update_every_frame do ecs.systems[index].action(engine, ecs, &ecs.systems[index])
    }
}

get_component_id :: proc(ecs: ^ECS, $component: typeid) -> ComponentID {
    return ecs.component_ids[component]
}

get_component_collection :: proc(ecs: ^ECS, $component: typeid) -> ^ComponentCollection(component) {
    component_index := ecs.component_ids[component]
    return cast(^ComponentCollection(component))(ecs.components[component_index])
}

get_component :: proc(ecs: ^ECS, $component: typeid, entity: Entity) -> ^component {
    component_collection_ptr := get_component_collection(ecs, component)
    
    entity_component_index := component_collection_ptr.entity_indices[entity]

    return &component_collection_ptr.components[entity_component_index]
}

// OPTIMIZE:  @BENAS: reuse components which are destroyed, as currently just appending more to list every time.
create_component :: proc(ecs: ^ECS, $component: typeid, entity: Entity) -> ^component {
    component_collection_ptr := get_component_collection(ecs, component)

    append(&component_collection_ptr.components, component{})
    component_collection_ptr.entity_indices[entity] = cast(u32)(len(component_collection_ptr.components) - 1)
    ecs.entity_signatures[entity] += ComponentSignature{cast(int)get_component_id(ecs, component)}

    // OPTIMIZE:  @BENAS: currently just looping every entity every time a component is added.
    // can sort and reduce search time or store some reference to which systems a entity has.
    system_loop: for _, index in ecs.systems {
        if (ecs.entity_signatures[entity] & ecs.systems[index].requirements) == ecs.systems[index].requirements {
            for e in ecs.systems[index].entities {
                if entity == e do continue system_loop // Entity already part of system.
            }

            append(&ecs.systems[index].entities, entity)
        }
    }

    return &component_collection_ptr.components[len(component_collection_ptr.components) - 1]
}

destroy_component :: proc(ecs: ^ECS, $component: typeid, entity: Entity) {
    component_collection_ptr := get_component_collection(ecs, component)

    old_signature := ecs.entity_signatures[entity]
    
    // Swap and pop component
    back_component := component_collection_ptr.components[len(component_collection_ptr.components) - 1]
    component_collection_ptr.components[entity] = back_component
    component_collection_ptr.entity_indices[back_entity] = component_collection_ptr.entity_indices[entity]
    pop(&component_collection_ptr.components)

    delete_key(&component_collection_ptr.entity_indices, entity)

    ecs.entity_signatures[entity] -= get_component_id(component)

    // Check if entity is not invalid for any systems
    for _, index in ecs.systems {
        requirements := ecs.systems[index].requirements
        if ((old_signature & requirements) == requirements && (ecs.entity_signatures[entity] & requirements) != requirements) {
            for system_entity, index in ecs.systems[index].entities {
                if system_entity == entity {
                    ecs.systems[index].entities[index] = ecs.systems[index].entities[len(ecs.systems[index].entities) - 1]
                    pop(&ecs.systems[index].entities)
                }
            }
        }
    }    
}

create_entity :: proc(ecs: ^ECS) -> Entity {
    entity := ecs._next_entity
    append(&ecs.entities, entity)
    ecs._next_entity += 1

    return entity
}

destroy_entity :: proc(ecs: ^ECS, entity: Entity) {
    // Swap and pop
    back_entity := ecs.entities[len(ecs.entities) - 1]
    ecs.entities[ecs.entity_indices[entity]] = back_entity
    ecs.entity_indices[back_entity] = ecs.entity_indices[entity]  // set new index (after swap)
    pop(&ecs.entities)


    // NOTE: Dont really need to do all this deleting. we keep data around meaning it might be bloated, but
    // as we reuse the entity index (which we currently dont) we would just overwrite the values anyway.
    // NOTE: Maybe keep a stack of entity indicies to reuse to minimise waste.
    // NOTE: Above still has waste if new entities dont use the same components as the previous.

    // Loop all components and remove references.
    component_signature := ecs.entity_signatures[entity]

    // TODO: Need to figure out how to get the type of something from only its typeid. to delete all components.
    // for _, component_id in ecs.components {
    //     if (ComponentSignature{component_id} & component_signature) == component_signature {
    //         destroy_component(ecs, type_of(ecs.component_types[0]), entity)
    //         component_signature -= ComponentSignature{component_id}
    //         if card(component_signature) == 0 do break // break when entity signature is empty.
    //     }
    // }

    // Remove destroyed entity from all lists.
    delete_key(&ecs.entity_signatures, entity)
    delete_key(&ecs.entity_indices, entity)
    delete_key(&ecs.entity_states, entity)
}

// Arbitrary default capacity, user will know better how many comonents will exist.
register_component :: proc(ecs: ^ECS, $component: typeid, initial_capacity : u32 = 1) {
    ecs.component_ids[component] = ecs._next_component_id
    ecs.component_types[ecs._next_component_id] = component
    ecs._next_component_id += 1

    component_collection := new(ComponentCollection(component))
    reserve(&component_collection.components, cast(int)initial_capacity)

    append(&ecs.components, cast(rawptr)component_collection)
    
    log.info("Registered:", type_info_of(component), "\b, ID:", ecs.component_ids[component])
}

// Currently just frees the memory
// TODO: Make this id reusable for another component.
unregister_component :: proc(ecs: ^ECS, $component: typeid) {
    delete(ecs.components[ecs.component_ids[component]])
    delete_key(&ecs.component_ids, component)
}

// NOTE: This make lots of copies of the system. think about making a create_system that returns an pointer to the system
// in the sytems array to make it easier to modify without storing pointers.
register_system :: proc(ecs: ^ECS, system: System) {
    assert(system.action != nil)

    system := system
    system.id = ecs._next_system_id
    ecs._next_system_id += 1

    append(&ecs.systems, system);

    log.info("Registered:", system.name, "\b, ID:", system.id, "\b, REQ:", system.requirements)
}

// NOTE: This just disables the system and makes it invalid.
// TODO: Make this to do by system name as well.
unregister_system :: proc(ecs: ^ECS, system_id: u32) {
    delete(ecs.systems[system_id].entities)
    ecs.systems[system_id].update_every_frame = false
    // TODO: Make this id reusable
}

get_system :: proc(ecs: ^ECS, name: string) -> ^System {
    for _, index in ecs.systems {
        if ecs.systems[index].name == name do return &ecs.systems[index]
    }

    return nil
}