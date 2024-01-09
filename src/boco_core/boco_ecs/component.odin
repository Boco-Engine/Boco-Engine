package boco_ecs

MAX_COMPONENTS :: 32
ComponentType :: distinct u32

// NOTE: Has a cap of 32 components right now
ComponentSignature :: bit_set[0..<MAX_COMPONENTS]

Components :: struct {
    components: [MAX_COMPONENTS]ComponentType,
}

// Default Components

Vec3 :: [3]f32

Transform :: struct {
    position: Vec3,
     // TODO: Transfer to quaternions at some point
    rotation: Vec3,
    scale: Vec3,
}

PhysicsObject :: struct {
    mass: f32,
}