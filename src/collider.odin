package lvo

import la "core:math/linalg"
import "core:math"

LVO_Collider :: struct {
	p1: la.Vector3f32,
	p2: la.Vector3f32,
}

LVO_PotentialCollision :: struct {
	entry_time: f32,
	normal: la.Vector3f32,
}

create_lvo_collider :: proc(pos1: la.Vector3f32 = {}, pos2: la.Vector3f32 = {}) -> LVO_Collider {
	collider: LVO_Collider = {}

	collider.p1 = pos1
	collider.p2 = pos2

	return collider
}

add_lvo_collider :: proc(collider: LVO_Collider, pos: la.Vector3f32) -> LVO_Collider {
	return LVO_Collider{collider.p1 + pos, collider.p2 + pos}
}

and_lvo_collider :: proc(collider1: LVO_Collider, collider2: LVO_Collider) -> b32 {
	x := math.min(collider1.p2.x, collider2.p2.x) - math.max(collider1.p1.x, collider2.p1.x)
	y := math.min(collider1.p2.y, collider2.p2.y) - math.max(collider1.p1.y, collider2.p1.y)
	z := math.min(collider1.p2.z, collider2.p2.z) - math.max(collider1.p1.z, collider2.p1.z)

	return x > 0 && y > 0 && z > 0
}

collide_lvo_collider :: proc(
	collider1: ^LVO_Collider,
	collider2: LVO_Collider,
	velocity: la.Vector3f32,
) -> (
	f32,
	la.Vector3f32,
) {
	vx, vy, vz := velocity.x, velocity.y, velocity.z

	time :: proc(x, y: f32) -> f32 {
		return x / y if y != 0 else math.NEG_INF_F32 if x > 0 else math.INF_F32
	}

	x_entry := time(
		collider2.p1.x - collider1.p2.x if vx > 0 else collider2.p2.x - collider1.p1.x,
		vx,
	)
	x_exit := time(
		collider2.p2.x - collider1.p1.x if vx > 0 else collider2.p1.x - collider1.p2.x,
		vx,
	)
	y_entry := time(
		collider2.p1.y - collider1.p2.y if vy > 0 else collider2.p2.y - collider1.p1.y,
		vy,
	)
	y_exit := time(
		collider2.p2.y - collider1.p1.y if vy > 0 else collider2.p1.y - collider1.p2.y,
		vy,
	)
	z_entry := time(
		collider2.p1.z - collider1.p2.z if vz > 0 else collider2.p2.z - collider1.p1.z,
		vz,
	)
	z_exit := time(
		collider2.p2.z - collider1.p1.z if vz > 0 else collider2.p1.z - collider1.p2.z,
		vz,
	)

	if x_entry < 0 && y_entry < 0 && z_entry < 0 {
		lvo_log("didnt collide")

		return 1, {2.0, 2.0, 2.0}
	}
	if x_entry > 1 || y_entry > 1 || z_entry > 1 {
		lvo_log("didnt collide")

		return 1, {2.0, 2.0, 2.0}
	}

	entry := math.max(x_entry, y_entry, z_entry)
	exit := math.min(x_exit, y_exit, z_exit)

	if entry > exit {
		lvo_log("didnt collide")

		return 1, {2.0, 2.0, 2.0}
	}

	nx := []int{0, -1 if vx > 0 else 1}[int(entry == x_entry)]
	ny := []int{0, -1 if vy > 0 else 1}[int(entry == y_entry)]
	nz := []int{0, -1 if vz > 0 else 1}[int(entry == z_entry)]
	
	lvo_log("collided")
	return entry, {f32(nx), f32(ny), f32(nz)}
}
