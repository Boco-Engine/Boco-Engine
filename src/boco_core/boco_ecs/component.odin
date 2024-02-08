package boco_ecs

import "core:log"
import "core:runtime"

ComponentID :: u64

// Can extract id into some map from component name to u32 map[string]u32 -> get_component_id(Transform) Lots or repeated data otherwise
// NOTE: Dont really need this. Just keep a map of ids from typeid.
Component :: struct {
    id: u32,
    entity: Entity,
}

// A way to quickly check which components a entity has or what components a system needs.
ComponentSignature :: bit_set[0..<64; ComponentID]

// TODO: Benchmark either using entity id as index or mapping for better packing
ComponentCollection :: struct($T: typeid) {
    type: typeid,
    components: [dynamic]T,
    entity_indices: map[Entity]u32,
}