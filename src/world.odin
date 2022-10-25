package lvo

import la "core:math/linalg"
import "core:math"
import "core:math/rand"
import "core:fmt"

LVO_World :: struct {
	texture_manager: LVO_Texture_Manager,
	chunks:          map[la.Vector3f32]^LVO_Chunk,
	block_types:     [dynamic]LVO_Block_Type,
}

init_lvo_textures :: proc(world: ^LVO_World, texture_pack: string) {
	lvo_log("Creating texture manager")
	world.texture_manager = create_lvo_texture_manager(16, 16, 256, texture_pack)
	lvo_log("Created texture manager")
	lvo_log("Loading textures...")
	generate_lvo_texture_manager_mipmaps()
}

get_lvo_world_chunk_position :: proc(world: ^LVO_World, position: la.Vector3f32) -> la.Vector3f32 {
	x, y, z := position.x, position.y, position.z

	return(
		{math.floor(x / CHUNK_WIDTH), math.floor(y / CHUNK_HEIGHT), math.floor(z / CHUNK_LENGTH)} \
	)
}

get_lvo_world_local_position :: proc(world: ^LVO_World, position: la.Vector3f32) -> la.Vector3f32 {
	x, y, z := position.x, position.y, position.z
	nx, ny, nz :=
		f32(i32(x) %% CHUNK_WIDTH), f32(i32(y) %% CHUNK_HEIGHT), f32(i32(z) %% CHUNK_LENGTH)
	return {nx, ny, nz}
}

create_lvo_world :: proc() -> ^LVO_World {
	world := new(LVO_World)
	lvo_log("Allocated world")

	lvo_log("Initializing textures")
	init_lvo_textures(world, "default")

	lvo_log("Loading blocks.lconf...")
	parser := create_lvo_config_parser(&world.texture_manager)
	world.block_types = parse_lconf_file(&parser, "blocks.lconf")

	for x in 0 ..= 7 {
		for z in 0 ..= 7 {
			chunk_position: la.Vector3f32 = {f32(x) - 4, -1, f32(z) - 4}
			current_chunk := create_lvo_chunk(world, chunk_position)
			for i in 0 ..= CHUNK_WIDTH - 1 {
				for j in 0 ..= CHUNK_HEIGHT - 1 {
					for k in 0 ..= CHUNK_LENGTH - 1 {
						block_choice: i32 = 0
						if j == 15 {
							block_choice = rand.choice(
								[]i32{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 10},
							)
						} else if j == 14 {
							block_choice = 2
						} else if j > 12 {
							block_choice = 4
						} else {
							block_choice = 5
						}
						current_chunk.blocks[i][j][k] = block_choice
					}
				}
			}
			world.chunks[chunk_position] = current_chunk
		}
	}

	for k, _ in world.chunks {
		assert(world.chunks[k].world != nil)
		update_lvo_chunk_subchunk_meshes(world.chunks[k])
		update_lvo_chunk_mesh(world.chunks[k])
	}

	return world
}

get_lvo_world_block_number :: proc(world: ^LVO_World, position: la.Vector3f32) -> i32 {
	x, y, z := position.x, position.y, position.z
	chunk_position := get_lvo_world_chunk_position(world, position)

	if !(chunk_position in world.chunks) {
		return 0
	}

	local_pos := get_lvo_world_local_position(world, position)
	lx, ly, lz := i32(local_pos.x), i32(local_pos.y), i32(local_pos.z)
	chunk := world.chunks[chunk_position]
	return chunk.blocks[lx][ly][lz]
}

is_lvo_world_block_opaque :: proc(world: ^LVO_World, position: la.Vector3f32) -> b32 {
	bt := world.block_types[get_lvo_world_block_number(world, position)]
	if bt.name == "air" {
		return false
	}
	return !bt.transparent
}

@(private = "file")
try_update_chunk_mesh :: proc(
	world: ^LVO_World,
	chunk_position: la.Vector3f32,
	position: la.Vector3f32,
) {
	if chunk_position in world.chunks {
		update_lvo_chunk_at_position(world.chunks[chunk_position], position)
		update_lvo_chunk_mesh(world.chunks[chunk_position])
	}
}

set_lvo_world_block :: proc(world: ^LVO_World, position: la.Vector3f32, block_id: i32) {
	x, y, z := position.x, position.y, position.z
	chunk_position := get_lvo_world_chunk_position(world, position)
	if !(chunk_position in world.chunks) {
		if block_id == 0 {
			return
		}

		world.chunks[chunk_position] = create_lvo_chunk(world, chunk_position)
	}
	if get_lvo_world_block_number(world, position) == block_id {
		return
	}
	local_position := get_lvo_world_local_position(world, position)
	lx, ly, lz := i32(local_position.x), i32(local_position.y), i32(local_position.z)
	chunk := world.chunks[chunk_position]
	chunk.blocks[lx][ly][lz] = block_id
	world.chunks[chunk_position] = chunk

	update_lvo_chunk_at_position(world.chunks[chunk_position], {x, y, z})
	update_lvo_chunk_mesh(world.chunks[chunk_position])

	cx, cy, cz := chunk_position.x, chunk_position.y, chunk_position.z

	if lx == CHUNK_WIDTH - 1 {
		try_update_chunk_mesh(world, {cx + 1, cy, cz}, {x + 1, y, z})
	}
	if lx == 0 {
		try_update_chunk_mesh(world, {cx - 1, cy, cz}, {x - 1, y, z})
	}
	if ly == CHUNK_HEIGHT - 1 {
		try_update_chunk_mesh(world, {cx, cy + 1, cz}, {x, y + 1, z})
	}
	if ly == 0 {
		try_update_chunk_mesh(world, {cx, cy - 1, cz}, {x, y - 1, z})
	}
	if lz == CHUNK_LENGTH - 1 {
		try_update_chunk_mesh(world, {cx, cy, cz + 1}, {x, y, z + 1})
	}
	if lz == 0 {
		try_update_chunk_mesh(world, {cx, cy, cz - 1}, {x, y, z - 1})
	}
}

draw_lvo_world :: proc(world: ^LVO_World) {
	for k, _ in world.chunks {
		draw_lvo_chunk(world.chunks[k])
	}
}
