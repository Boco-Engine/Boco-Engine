package boco_ecs

import "core:log"
import "core:runtime"

// Can extract id into some map from component name to u32 map[string]u32 -> get_component_id(Transform) Lots or repeated data otherwise
Component :: struct {
    id: u32,
    entity: Entity,
}

// A way to quickly check which components a entity has or what components a system needs.
ComponentSignature :: bit_set[0..<32]

// Default Components

Vec3 :: [3]f32

Transform :: struct {
    using component: Component,

    position: Vec3,
    rotation: Vec3,
    scale: Vec3,
}

Mass :: struct {
    using component: Component,
    value: f32,
}

Fluff :: struct {
    using component: Component,
    value: [10000]u32,
}