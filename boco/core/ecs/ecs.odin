package ecs

import "core:log"
import "core:runtime"

State :: enum {
    ACTIVE,
    ASLEEP,
    DEAD,
}

ECS :: struct {
    entities: [dynamic]Entity,
    // NOTE: Type is ComponentCollection(T) Where T is the components type.
    components: [dynamic]rawptr,
    systems: [dynamic]^System,

    entity_indices: map[Entity]u32,
    entity_signatures: map[Entity]ComponentSignature,
    entity_states: map[Entity]State,

    component_ids: map[typeid]ComponentID,
    component_types: map[ComponentID]typeid,

    initial_capacity: u32,

    // These are used to keep track of ids. Currently just incremented, meaning if the engine runs for a long time
    // creating new entities constantly we will eventually overflow.
    _next_entity: Entity,
    _next_component_id: ComponentID,
    _next_system_id: SystemID,
}

/*
    Initialise the ecs struct.
    
    ecs: The structure to init
    initial_capacity: An initial size for entities, should be the expected max, but as its dynamic will still grow.
*/
init :: proc(ecs: ^ECS, initial_capacity: u32) {
    ecs.initial_capacity = initial_capacity
    reserve(&ecs.components, 64) // size of components array == bit_set size of signature.
    reserve(&ecs.entities, cast(int)ecs.initial_capacity)
}

deinit :: proc(ecs: ^ECS) {
    delete(ecs.entities)

    for _, index in ecs.systems {
        free_system(ecs, ecs.systems[index])
    }
    delete(ecs.systems)

    for _, index in ecs.components {
        // TODO: Destroy all component_collection variables.
        // TODO: Add way to keep track of all the components we have as we currenly can only access if we already know the components.
    }
    delete(ecs.components)

    delete(ecs.entity_indices)
    delete(ecs.entity_signatures)
    delete(ecs.entity_states)
    delete(ecs.component_ids)
    delete(ecs.component_types)
}

update :: proc(engine: ^any, ecs: ^ECS) {
    for _, index in ecs.systems {
        if ecs.systems[index].update_every_frame do ecs.systems[index].action(engine, ecs, ecs.systems[index])
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

has_component :: proc(ecs: ^ECS, $component: typeid, entity: Entity) -> bool {
    component_collection_ptr := get_component_collection(ecs, component)
    
    _, exists := component_collection_ptr.entity_indices[entity]

    return exists
}

// OPTIMIZE:  @BENAS: reuse components which are destroyed, as currently just appending more to list every time.
create_component :: proc(ecs: ^ECS, $component: typeid, entity: Entity) -> ^component {
    component_collection_ptr := get_component_collection(ecs, component)

    append(&component_collection_ptr.components, component{})
    component_collection_ptr.entity_indices[entity] = cast(u32)(len(component_collection_ptr.components) - 1)
    component_collection_ptr.entity_of_component_index[cast(u32)(len(component_collection_ptr.components) - 1)] = entity
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
    // Get the last component
    back_component := component_collection_ptr.components[len(component_collection_ptr.components) - 1]
    
    // Get the entity which owns the last component
    back_entity := component_collection_ptr.entity_of_component_index[auto_cast (len(component_collection_ptr.components) - 1)]

    // Set Removed component to the back component
    component_collection_ptr.components[component_collection_ptr.entity_indices[entity]] = back_component

    // Update index of entity of back component to the one of removed component
    component_collection_ptr.entity_indices[back_entity] = component_collection_ptr.entity_indices[entity]

    component_collection_ptr.entity_of_component_index[component_collection_ptr.entity_indices[back_entity]] = back_entity

    // Delete the entity from the entity to component map, and remove the last component, and remob
    delete_key(&component_collection_ptr.entity_of_component_index, auto_cast (len(component_collection_ptr.components) - 1))
    delete_key(&component_collection_ptr.entity_indices, entity)
    pop(&component_collection_ptr.components)

    // Update Signature
    ecs.entity_signatures[entity] -= {auto_cast get_component_id(ecs, component)}

    // Check if entity is not invalid for any systems
    for _, index in ecs.systems {
        requirements := ecs.systems[index].requirements
        if ((old_signature & requirements) == requirements && (ecs.entity_signatures[entity] & requirements) != requirements) {
            for system_entity, entity_index in ecs.systems[index].entities {
                if system_entity == entity {
                    ecs.systems[index].entities[entity_index] = ecs.systems[index].entities[len(ecs.systems[index].entities) - 1]
                    pop(&ecs.systems[index].entities)
                    return
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

    delete_key(&ecs.entity_signatures, entity)
    delete_key(&ecs.entity_indices, entity)
    delete_key(&ecs.entity_states, entity)
}

register_component :: proc(ecs: ^ECS, $component: typeid, initial_capacity : u32) {
    ecs.component_ids[component] = ecs._next_component_id
    ecs.component_types[ecs._next_component_id] = component
    ecs._next_component_id += 1

    component_collection := new(ComponentCollection(component))
    reserve(&component_collection.components, cast(int)initial_capacity)

    append(&ecs.components, cast(rawptr)component_collection)
    
    log.info("Registered:", type_info_of(component), "\b, ID:", ecs.component_ids[component])
}

// NOTE: Currently just frees the memory
// TODO: Make this id reusable for another component.
unregister_component :: proc(ecs: ^ECS, $component: typeid) {
    delete(ecs.components[ecs.component_ids[component]])
    delete_key(&ecs.component_ids, component)
}

// DESIGN: ECS layout and how we want memory layout.
// TODO: Free all systems made this way.
// TODO: Convert from using system pointers to ids, and store systems in an array.
// NOTE: This is currently just a wrapper for newing the system yourself, but can assign all register system responsibilities to this instead.
make_system :: proc(ecs: ^ECS, name: string) -> ^System {
    system_ptr := new(System)
    system_ptr.name = name

    return system_ptr
}

free_system :: proc(ecs: ^ECS, system: ^System) {
    // DESIGN: Swap and pop and swap ids? or does swapping ids matter. do we even need ids if were passing by pointer everywhere. Design this better
    delete(system.entities)
    free(system)
}

// NOTE: This make lots of copies of the system. think about making a create_system that returns an pointer to the system
// in the sytems array to make it easier to modify without storing pointers.
register_system :: proc(ecs: ^ECS, system: ^System) {
    assert(system.action != nil, "No action provided to system.")

    system.id = ecs._next_system_id
    ecs._next_system_id += 1

    append(&ecs.systems, system);

    log.info("Registered:", system.name, "\b, ID:", system.id, "\b, REQ:", system.requirements)
}

// OPTIMIZE: Make this id reusable -> Might not be necessary especially for systems and components though. eg add to some queue to take from if available
// NOTE: This just disables the system and makes it invalid, doesnt allow a system to use the id it frees.
unregister_system_by_id :: proc(ecs: ^ECS, system_id: u32) {
    delete(ecs.systems[system_id].entities)
    ecs.systems[system_id].update_every_frame = false
}

unregister_system_by_name :: proc(ecs: ^ECS, system_name: string) {
    for _, index in ecs.systems {
        if (ecs.systems[index].name == system_name) {
            delete(ecs.systems[index].entities)
            ecs.systems[index].update_every_frame = false
            return
        }
    }

    log.warn("Trying to delete system which could not be found:", system_name)
}

unregister_system :: proc{unregister_system_by_id, unregister_system_by_name}

get_system :: proc(ecs: ^ECS, name: string) -> ^System {
    for _, index in ecs.systems {
        if ecs.systems[index].name == name do return ecs.systems[index]
    }

    return nil
}