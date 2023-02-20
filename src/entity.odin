package lvo

import la "core:math/linalg"
import "core:math"
import "core:fmt"

LVO_Entity :: struct {
	position: la.Vector3f32,
	rotation: la.Vector2f32,
	velocity: la.Vector3f32,
	width:    f32,
	height:   f32,
	world:    ^LVO_World,
	collider: LVO_Collider,
}

create_lvo_entity :: proc(world: ^LVO_World) -> ^LVO_Entity {
	entity := new(LVO_Entity)
	entity.position = {0, 30, 0}
	entity.rotation = {-math.TAU / 4.0, 0.0}
	entity.velocity = {0, 0, 0}
	entity.width = 0.6
	entity.height = 1.8
	entity.world = world
	entity.collider = create_lvo_collider()
	return entity
}

update_lvo_entity :: proc(entity: ^LVO_Entity, dt: f32) {
	update_lvo_entity_collider(entity)

	for i in 0..=2 {
		avel := dt * entity.velocity

		step_x, step_y, step_z: i32 =
			1 if avel.x > 0 else -1, 1 if avel.y > 0 else -1, 1 if avel.z > 0 else -1

		steps_xz := i32(entity.width / 2)
		steps_y := i32(entity.height)

		x, y, z := i32(entity.position.x), i32(entity.position.y), i32(entity.position.z)
		cx, cy, cz :=
			i32(entity.position.x + avel.x),
			i32(entity.position.y + avel.y),
			i32(entity.position.z + avel.z)

		// potential_collision_entries: [dynamic]f32 = {}
		// potential_collision_normals: [dynamic]la.Vector3f32 = {}
		potential_collisions: [dynamic]LVO_PotentialCollision = {}
		lvo_log("step:", step_x, step_y, step_z)
		lvo_log("last:", x, y, z)
		lvo_log("current:", cx, cy, cz)
		lvo_log("steps:", steps_xz, steps_y)
		for i := x - step_x * (steps_xz + 1); i < cx + step_x * (steps_xz + 2); i += step_x {
			for j := y - step_y * (steps_y + 1); j < cy + step_y * (steps_y + 3); j += step_y {
				for k := z - step_z * (steps_xz + 1); k < cz + step_z * (steps_xz + 2); k += step_z {
					lvo_log("hihi")
					pos: la.Vector3f32 = {f32(i), f32(k), f32(k)}
					
					num := get_lvo_world_block_number(entity.world, pos)

					if num == 0 {
						continue
					}
					for _collider in entity.world.block_types[num].colliders {
						lvo_log("new collider")
						entry_time, normal := collide_lvo_collider(&entity.collider, add_lvo_collider(_collider, pos), avel)
						if normal == {} {
							continue
						}
						append(&potential_collisions, LVO_PotentialCollision{entry_time, normal})

					}
				}
			}
		}
		fmt.printf("\e[1;1H\e[2J")


		if len(potential_collisions) == 0 {
			break
		}
		entry_time: f32 = 340282346638528859811704183484516925440.0 // sorry to my future self
		normal: la.Vector3f32 = 0
		for pc, i in potential_collisions {
			lvo_log("new potential")
			if entry_time > pc.entry_time {
				lvo_log("New entry time: ", entry_time)
				lvo_log("New normal: ", pc.normal)
				entry_time, normal = pc.entry_time, pc.normal
			}
		}
		entry_time -= 0.001

		if normal.x != 2 {
			entity.velocity.x = 0
			entity.position.x += avel.x * entry_time
		}
		
		if normal.y != 2 {
			entity.velocity.y = 0
			entity.position.y += avel.y * entry_time
		}
		
		if normal.z != 2 {
			entity.velocity.z = 0
			entity.position.z += avel.z * entry_time
		}
	}
	

	entity.position.x += entity.velocity.x * dt
	entity.position.y += entity.velocity.y * dt
	entity.position.z += entity.velocity.z * dt
	entity.velocity = {0, 0, 0}
}

update_lvo_entity_collider :: proc(entity: ^LVO_Entity) {
	x, y, z := entity.position.x, entity.position.y, entity.position.z

	entity.collider.p1.x = x - entity.width / 2.0
	entity.collider.p2.x = x + entity.width / 2.0

	entity.collider.p1.y = y
	entity.collider.p2.y = y + entity.height

	entity.collider.p1.z = z - entity.width / 2.0
	entity.collider.p2.z = z + entity.width / 2.0
}
