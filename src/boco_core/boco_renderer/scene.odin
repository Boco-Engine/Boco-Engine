package boco_renderer

import "../boco_window"
import "../boco_ecs"

// TODO: Get rid of this taking max entities -> Either make ecs dynamic or set constant.
Scene :: struct {
    // Identification things, maybe add u32 ID.
    name: string,

    // Is the camera an entity? Yes?
    camera: Camera,

    // Do we want an entire entity component system struct or just entities?
    // entire system means we need to re-register all out components and systems, but we can make functions for that
    // just entities means we have to add and clear to an existing ecs, which might be slower than having entirely new ones?
    // Just entities allows keeping entities between scenes, otherwise need to create copy for new ECS.
    ecs: boco_ecs.ECS,
}