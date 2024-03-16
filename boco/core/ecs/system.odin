package ecs

import "core:log"
import "core:runtime"

SystemID :: u64

// Currenly preallocating all systems with enough space to hold all entities, maybe for something like this
// A dynamic array will be enough, as this will not run every frame. but maybe this way is better for systems as
// Then theyre also contiguous in memory
System :: struct {
    name: string,
    id: SystemID,
    signature: ComponentSignature,

    entities: [dynamic]Entity,
    action: proc(data: rawptr, ecs: ^ECS, system: ^System),

    update_every_frame: bool,
}


// DESIGN: ECS layout and how we want memory layout.
// TODO: Convert from using system pointers to ids, and store systems in an array.
// NOTE: This is currently just a wrapper for newing the system yourself, but can assign all register system responsibilities to this instead.
system_make :: proc(universe: ^ECS, name: string) -> ^System {
    system_ptr := new(System)
    system_ptr.name = name

    return system_ptr
}

system_destroy :: proc(universe: ^ECS, system: ^System) {
    // DESIGN: Swap and pop and swap ids? or does swapping ids matter. do we even need ids if were passing by pointer everywhere. Design this better
    delete(system.entities)
    free(system)
}

system_register :: proc(universe: ^ECS, system: ^System) {
    assert(system.action != nil, "No action provided to system.")

    system.id = universe._next_system_id
    universe._next_system_id += 1

    append(&universe.systems, system);

    log.info("Registered:", system.name, "\b, ID:", system.id, "\b, REQ:", system.signature)
}

system_unregister_by_id :: proc(universe: ^ECS, system_id: SystemID) {
    delete(universe.systems[system_id].entities)
    universe.systems[system_id].update_every_frame = false
}

system_unregister_by_name :: proc(universe: ^ECS, system_name: string) {
    for _, index in universe.systems {
        if (universe.systems[index].name == system_name) {
            delete(universe.systems[index].entities)
            universe.systems[index].update_every_frame = false
            return
        }
    }

    log.warn("Trying to delete system which could not be found:", system_name)
}

system_unregister :: proc{system_unregister_by_id, system_unregister_by_name}

system_get_by_name :: proc(universe: ^ECS, name: string) -> ^System {
    for _, index in universe.systems {
        if universe.systems[index].name == name do return universe.systems[index]
    }

    return nil
}

system_get_by_id :: proc(universe: ^ECS, system_id: SystemID) -> ^System {
    return universe.systems[system_id]
}

system_get :: proc{system_get_by_name, system_get_by_id}