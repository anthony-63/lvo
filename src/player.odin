package lvo

import la "core:math/linalg"
import "core:math"
import "vendor:glfw"
import "core:fmt"

LVO_Player :: struct {
	width, height: f32,
	shader:        LVO_Shader,
	input:         la.Vector3f32,
	sensitivity:   f32,
	speed:         f32,
	target_speed:  f32,
	eye_level:     f32,
	entity:        ^LVO_Entity,
}

create_lvo_player :: proc(
	world: ^LVO_World,
	shader: LVO_Shader,
	width, height: int,
) -> LVO_Player {
	return(
		LVO_Player{
			width = auto_cast width,
			height = auto_cast height,
			shader = shader,
			input = {0.0, 0.0, 0.0},
			sensitivity = SENSITIVITY,
			speed = WALKING_SPEED,
			target_speed = WALKING_SPEED,
			entity = create_lvo_entity(world),
		} \
	)
}

update_lvo_player :: proc(player: ^LVO_Player, dt: f32) {
	player.speed += (player.target_speed - player.speed) * dt * 20

	if player.input.y != 0 {
		player.entity.velocity.y = player.input.y * player.speed
	}
	if player.input.x != 0 || player.input.z != 0 {
		angle :=
			player.entity.rotation.x - math.atan2(player.input.z, player.input.x) + math.TAU / 4.0

		player.entity.velocity.x = math.cos(angle) * player.speed
		player.entity.velocity.z = math.sin(angle) * player.speed
	}
	
	update_lvo_entity(player.entity, dt)
	// lvo_log("Player location: ", player.entity.position)
	// lvo_log("Player velocity: ", player.entity.velocity)
}

update_lvo_player_matrices :: proc(player: ^LVO_Player) {
	aspect_ratio: f32 = player.width / player.height
	increase_fov := (player.speed - WALKING_SPEED) / (SPRINTING_SPEED - WALKING_SPEED)
	p_matrix := la.matrix4_perspective_f32(FOV + (0.3 * increase_fov), aspect_ratio, 0.1, 5000.0)

	m_matrix := la.MATRIX4F32_IDENTITY
	m_matrix *= la.matrix4_rotate_f32(player.entity.rotation.y, la.Vector3f32{1.0, 0.0, 0.0})
	m_matrix *= la.matrix4_rotate_f32(
		player.entity.rotation.x + math.TAU / 4.0,
		la.Vector3f32{0.0, 1.0, 0.0},
	)
	m_matrix *= la.matrix4_translate(
		la.Vector3f32{
			-player.entity.position.x,
			-player.entity.position.y - player.eye_level,
			-player.entity.position.z,
		},
	)

	v_matrix := la.MATRIX4F32_IDENTITY

	mvp_matrix := (p_matrix * v_matrix) * m_matrix

	lvo_shader_set_uniform_m4(player.shader, "mvp", mvp_matrix)
}
