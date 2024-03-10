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
    requirements: ComponentSignature,

    entities: [dynamic]Entity,
    action: proc(data: rawptr, ecs: ^ECS, system: ^System),

    update_every_frame: bool,
}
