package boco_ecs

ECS :: struct {
    entities: Entities,
    components: Components,
    systems: []System,
}

System :: struct {
    entities: [dynamic]Entity
}

GravitySystem :: struct {
    using system: System,

    gravity: f32,
}

get_component :: proc(ecs: ECS, $T: typeid, entity: Entity) -> ^T {

    return ecs.entities.component_signature[entity]
}

update_gravity :: proc(ecs: ECS, using gravity_system: GravitySystem) {
    for entity in entities {
        physics_object : ^PhysicsObject = get_component(ecs, PhysicsObject, entity)
        transform : ^Transform = get_component(ecs, Transform, entity)

        
    }
}