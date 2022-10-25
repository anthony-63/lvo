package lvo

import "core:math"
import la "core:math/linalg"

HIT_RANGE :: 3

LVO_HitRay :: struct {
	vector:   la.Vector3f32,
	position: la.Vector3f32,
	block:    la.Vector3f32,
	world:    ^LVO_World,
	distance: f32,
}

lvo_hit_callback :: proc(cblock: la.Vector3f32, nblock: la.Vector3f32)

create_lvo_hitray :: proc(
	world: ^LVO_World,
	rotation: la.Vector2f32,
	starting_position: la.Vector3f32,
) -> LVO_HitRay {
	hitray := LVO_HitRay{}
	hitray.world = world
	hitray.position = starting_position
	hitray.distance = 0

	hitray.vector = {
		math.cos(rotation.x) * math.cos(rotation.y),
		math.sin(rotation.y),
		math.sin(rotation.x) * math.cos(rotation.y),
	}
	hitray.block = {
		math.round(hitray.position.x),
		math.round(hitray.position.y),
		math.round(hitray.position.z),
	}
	return hitray
}

step_lvo_hitray :: proc(hitray: ^LVO_HitRay, callback: lvo_hit_callback) -> b32 {
	bx, by, bz := hitray.block.x, hitray.block.y, hitray.block.z
	local_position: la.Vector3f32 = {
		hitray.position.x - bx,
		hitray.position.y - by,
		hitray.position.z - bz,
	}

	sign := []i32{1, 1, 1}
	absolute_vector := []f32{hitray.vector.x, hitray.vector.y, hitray.vector.z}

	for component in 0 ..= 2 {
		if hitray.vector[component] < 0 {
			sign[component] = -1
			absolute_vector[component] = -absolute_vector[component]
			local_position[component] = -local_position[component]
		}
	}

	lx, ly, lz := local_position.x, local_position.y, local_position.z
	vx, vy, vz := absolute_vector[0], absolute_vector[1], absolute_vector[2]

	if vx != 0 {
		x: f32 = 0.5
		y := (0.5 - lx) / vx * vy + ly
		z := (0.5 - lx) / vx * vz + lz

		if y >= -0.5 && y <= 0.5 && z >= -0.5 && z <= 0.5 {
			distance := math.sqrt(math.pow(x - lx, 2) + math.pow(y - ly, 2) + math.pow(z - lz, 2))
			return check_lvo_hitray(
				hitray,
				callback,
				distance,
				hitray.block,
				{bx + f32(sign[0]), by, bz},
			)
		}
	}
	if vy != 0 {
		x := (0.5 - ly) / vy * vx + lx
		y: f32 = 0.5
		z := (0.5 - ly) / vy * vz + lz

		if x >= -0.5 && x <= 0.5 && z >= -0.5 && z <= 0.5 {
			distance := math.sqrt(math.pow(x - lx, 2) + math.pow(y - ly, 2) + math.pow(z - lz, 2))
			return check_lvo_hitray(
				hitray,
				callback,
				distance,
				hitray.block,
				{bx, by + f32(sign[1]), bz},
			)
		}
	}
	if vz != 0 {
		x := (0.5 - lz) / vz * vx + lx
		y := (0.5 - lz) / vz * vy + ly
		z: f32 = 0.5

		if x >= -0.5 && x <= 0.5 && y >= -0.5 && y <= 0.5 {
			distance := math.sqrt(math.pow(x - lx, 2) + math.pow(y - ly, 2) + math.pow(z - lz, 2))
			return check_lvo_hitray(
				hitray,
				callback,
				distance,
				hitray.block,
				{bx, by, bz + f32(sign[2])},
			)
		}
	}
	return false
}


check_lvo_hitray :: proc(
	hitray: ^LVO_HitRay,
	callback: lvo_hit_callback,
	distance: f32,
	bpos: la.Vector3f32,
	bnewpos: la.Vector3f32,
) -> b32 {
	lvo_log(get_lvo_world_block_number(hitray.world, bnewpos), distance, bpos, bnewpos)
	if get_lvo_world_block_number(hitray.world, bnewpos) != 0 {
		callback(bpos, bnewpos)
		return true
	} else {
		hitray.position = {
			hitray.position.x + hitray.vector.x * distance,
			hitray.position.y + hitray.vector.y * distance,
			hitray.position.z + hitray.vector.z * distance,
		}
		hitray.block = bnewpos
		hitray.distance += distance
		return false
	}

}
