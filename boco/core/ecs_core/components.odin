package ecs_core

import "boco:core/renderer"
import "boco:core/types"

Transform :: struct {
    position: types.dVec3,
    rotation: types.Vec3,
    scale: types.Vec3,
}

MeshComponent :: struct {
    id: renderer.MeshID,
    visible: bool,
}

Chunk :: struct {
    path: string,
    loaded: bool,
    offset: types.dVec3,
}

ChunkLoadDistance :: struct {
    min: f64,
    max: f64,
}