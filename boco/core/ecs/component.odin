package ecs

import "core:log"
import "core:runtime"

ComponentID :: u64

// A way to quickly check which components a entity has or what components a system needs.
ComponentSignature :: bit_set[0..<64; ComponentID]

// OPTIMIZE: Benchmark either using entity id as index or mapping for better packing
ComponentCollection :: struct($T: typeid) {
    type: typeid,
    components: [dynamic]T,
    entity_of_component_index: map[u32]Entity,
    entity_indices: map[Entity]u32,
}