package boco_renderer

import "core:fmt"
import "core:math"
import "core:math/linalg/glsl"

Camera :: struct {
    position : Vec3,
    rotation : Vec3,
    viewMatrix : Mat4,
    projectionMatrix : Mat4,

    up, forward, right : Vec3,
    fov: f32,
    aspect_ratio : f32,
    far, near : f32,

    Update : proc(this : ^Camera, delta_time : f64)
}

update_camera :: proc(this: ^Camera, delta_time: f64) {
    update_projection_matrix(this)
    update_view_matrix(this)
}

update_camera_input :: proc(using this : ^Camera, mouse_movement: [2]f32) {
    yaw := rotation.x - (mouse_movement.x * 0.1);
    if yaw > 360 {
        yaw -= 360
    } else if yaw < 0 {
        yaw += 360
    }

    pitch := rotation.y - (mouse_movement.y * 0.1)
    pitch = max(-89, pitch)
    pitch = min(89, pitch)

    rotation = {yaw, pitch, rotation.z}
    
    rad : Vec3 =  {math.to_radians(yaw), math.to_radians(pitch), math.to_radians(rotation.z)}
}

update_projection_matrix :: proc(using this : ^Camera) {
	q : f32 = 1.0 / (math.tan_f32(math.to_radians(fov) / 2))
	A : f32 = q / aspect_ratio
	B : f32 = -(far + near) / (far - near)
	C : f32 = -(2 * (far * near)) / (far - near)

	projectionMatrix = {
		A, 0, 0, 0,
		0, -q, 0, 0,
		0, 0, B, -1,
		0, 0, C, 0,
	}
}

update_view_matrix :: proc(using this : ^Camera) {
	c3 : f32 = math.cos_f32(math.to_radians(rotation.z))
	s3 : f32 = math.sin_f32(math.to_radians(rotation.z))
	c2 : f32 = math.cos_f32(math.to_radians(rotation.y))
	s2 : f32 = math.sin_f32(math.to_radians(rotation.y))
	c1 : f32 = math.cos_f32(math.to_radians(rotation.x))
	s1 : f32 = math.sin_f32(math.to_radians(rotation.x))
	right = { (c1 * c3 + s1 * s2 * s3), (c2 * s3), (c1 * s2 * s3 - c3 * s1) };
	up = { (c3 * s1 * s2 - c1 * s3), (c2 * c3), (c1 * c3 * s2 + s1 * s3) };
	forward = { (c2 * s1), (-s2), (c1 * c2) };
	viewMatrix[0, 0] = right.x;
	viewMatrix[1, 0] = right.y;
	viewMatrix[2, 0] = right.z;
    
	viewMatrix[3, 0] = -glsl.dot_vec3(cast(glsl.vec3)right, cast(glsl.vec3)position);
	viewMatrix[0, 1] = up.x;
	viewMatrix[1, 1] = up.y;
	viewMatrix[2, 1] = up.z;
	viewMatrix[3, 1] = -glsl.dot_vec3(cast(glsl.vec3)up, cast(glsl.vec3)position);
	viewMatrix[0, 2] = forward.x;
	viewMatrix[1, 2] = forward.y;
	viewMatrix[2, 2] = forward.z;
	viewMatrix[3, 2] = -glsl.dot_vec3(cast(glsl.vec3)forward, cast(glsl.vec3)position);
	viewMatrix[0, 3] = 0
	viewMatrix[1, 3] = 0
	viewMatrix[2, 3] = 0
	viewMatrix[3, 3] = 1
}

make_camera :: proc(fov, aspect_ratio : f32) -> (camera: Camera) {
    camera.fov = fov
    camera.aspect_ratio = aspect_ratio
    camera.Update = update_camera
    camera.far = 10000
    camera.near = 0.1
	camera.position = {0, 0, 10}

    update_projection_matrix(&camera)
    update_view_matrix(&camera)

    return
}