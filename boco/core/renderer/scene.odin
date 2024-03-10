package renderer

import "boco:core/window"
import "boco:core/ecs"

SceneID :: u32

Scene :: struct {
    id: SceneID,
    name: string,

    // Is the camera an entity? Yes?
    camera: Camera,
    
    ecs: ecs.ECS,
}