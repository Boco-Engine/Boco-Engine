package boco_physics

import "../../types"

// OPTIMIZE: Entire physics system needs to be looked at and converted to SIMD for better performance where possible.
SphereVolume :: struct {
    point: types.Vec4,
    radius: f32,
}

// Using Halfwidths and centre representation
AABBVolume :: struct {
    point: types.Vec4,
    r: types.Vec4,
}


