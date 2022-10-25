package lvo

import la "core:math/linalg"
import "core:math"
import "vendor:glfw"

LVO_Camera :: struct {
	width, height: f32,
	shader:        LVO_Shader,
	position:      la.Vector3f32,
	rotation:      la.Vector2f32,
	input:         la.Vector3f32,
	sensitivity:   f32,
	speed:         f32,
}

create_lvo_camera :: proc(
	shader: LVO_Shader,
	width, height: int,
	sensitivity, speed: f32,
) -> LVO_Camera {
	return(
		LVO_Camera{
			width = auto_cast width,
			height = auto_cast height,
			shader = shader,
			position = {0, 0, 0},
			rotation = {-math.TAU / 4.0, 0},
			input = {0.0, 0.0, 0.0},
			sensitivity = sensitivity,
			speed = speed,
		} \
	)
}

update_lvo_camera :: proc(camera: ^LVO_Camera, dt: f32) {
	m := camera.speed * dt
	camera.position.y += camera.input.y * m

	if camera.input.x != 0 || camera.input.z != 0 {
		angle := camera.rotation.x - math.atan2(camera.input.z, camera.input.x) + math.TAU / 4.0

		camera.position.x += math.cos(angle) * m
		camera.position.z += math.sin(angle) * m
	}
}

update_lvo_camera_matrices :: proc(camera: ^LVO_Camera) {
	aspect_ratio: f32 = camera.width / camera.height
	p_matrix := la.matrix4_perspective_f32(FOV, aspect_ratio, 0.1, 5000.0)

	m_matrix := la.MATRIX4F32_IDENTITY
	m_matrix *= la.matrix4_rotate_f32(camera.rotation.y, la.Vector3f32{1.0, 0.0, 0.0})
	m_matrix *= la.matrix4_rotate_f32(
		camera.rotation.x + math.TAU / 4.0,
		la.Vector3f32{0.0, 1.0, 0.0},
	)
	m_matrix *= la.matrix4_translate(
		la.Vector3f32{-camera.position.x, -camera.position.y, -camera.position.z},
	)

	v_matrix := la.MATRIX4F32_IDENTITY

	mvp_matrix := (p_matrix * v_matrix) * m_matrix

	lvo_shader_set_uniform_m4(camera.shader, "mvp", mvp_matrix)
}
