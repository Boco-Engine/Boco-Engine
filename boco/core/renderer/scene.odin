package renderer

import "core:log"

import "boco:core/window"
import "boco:core/ecs"

SceneID :: u32

Scene :: struct {
    name        : string,
    id          : SceneID,
    universe    : ecs.ECS,

    // Temp -> Convert to Entity/Component.
    camera      : Camera,
}

Scenes :: distinct [dynamic]Scene

get_scene_by_name :: proc(scenes: ^Scenes, name: string) -> ^Scene {
    for _, i in scenes {
        if scenes[i].name == name do return &scenes[i]
    }

    log.warn("Requested scene not found: name-", name)
    return nil;
}

get_scene_by_id :: proc(scenes: ^Scenes, id: SceneID) -> ^Scene {
    for _, i in scenes {
        if scenes[i].id == id do return &scenes[i]
    }

    log.warn("Requested scene not found: id-", id)
    return nil;
}

get_scene :: proc{get_scene_by_name, get_scene_by_id}

scene_make :: proc(name: string) -> Scene {
    @(static) _next_id : SceneID = 0
    _next_id += 1
    return Scene{name = name, id = _next_id - 1, universe = ecs.ECS{}}
}

scene_destroy :: proc() {

}

scenes_destroy :: proc(scenes: Scenes) {
    delete(scenes)
}