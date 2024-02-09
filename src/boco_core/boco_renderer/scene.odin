package boco_renderer

import "../boco_window"
import "../boco_ecs"

SceneID :: u32

Scene :: struct {
    id: SceneID,
    name: string,

    // Is the camera an entity? Yes?
    camera: Camera,
    
    ecs: boco_ecs.ECS,
}