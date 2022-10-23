package lvo

import la "core:math/linalg"
import "core:math"
import "core:math/rand"
import "core:fmt"

LVO_World :: struct {
	texture_manager: LVO_Texture_Manager,
	chunks:          map[la.Vector3f32]LVO_Chunk,
	block_types:     [dynamic]LVO_Block_Type,
}

init_lvo_textures :: proc(world: ^LVO_World, texture_pack: string) {
	world.texture_manager = create_lvo_texture_manager(16, 16, 256, texture_pack)
	append(&world.block_types, create_lvo_air())
	append(
		&world.block_types,
		create_lvo_block_type(
			"cobblestone",
			&world.texture_manager,
			map[string]string{"all" = "cobblestone"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"grass",
			&world.texture_manager,
			map[string]string{"top" = "grass", "bottom" = "dirt", "sides" = "grass_side"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"grass_block",
			&world.texture_manager,
			map[string]string{"all" = "grass"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type("dirt", &world.texture_manager, map[string]string{"all" = "dirt"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("stone", &world.texture_manager, map[string]string{"all" = "stone"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("sand", &world.texture_manager, map[string]string{"all" = "sand"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"planks",
			&world.texture_manager,
			map[string]string{"all" = "planks"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"log",
			&world.texture_manager,
			map[string]string{"top" = "log_y", "bottom" = "log_y", "sides" = "log_side"},
		),
	)
	generate_lvo_texture_manager_mipmaps()
}

create_lvo_world :: proc() -> LVO_World {
	world: LVO_World

	init_lvo_textures(&world, "default")

	for x in 0 ..= 7 {
		for z in 0 ..= 7 {
			chunk_position: la.Vector3f32 = {f32(x) - 4, -1, f32(z) - 4}
			current_chunk := create_lvo_chunk(&world, chunk_position)

			for i in 0 ..= CHUNK_WIDTH - 1 {
				for j in 0 ..= CHUNK_HEIGHT - 1 {
					for k in 0 ..= CHUNK_LENGTH - 1 {
						block_choice: i32 = 0
						if j > 13 {
							block_choice = rand.choice([]i32{0, 3})
						} else {
							block_choice = rand.choice([]i32{0, 0, 1})
						}
						chunk := world.chunks[{0, 0, 0}]
						chunk.blocks[i][j][k] = block_choice
						world.chunks[{0, 0, 0}] = chunk
					}
				}
			}
			world.chunks[chunk_position] = current_chunk
		}
	}
	for k, _ in world.chunks {
		fmt.println(k)
	}
	for k, _ in world.chunks {
		update_lvo_chunk_mesh(&world.chunks[k])
	}


	update_lvo_chunk_mesh(&world.chunks[{0, 0, 0}])

	return world
}

get_lvo_world_block_number :: proc(world: ^LVO_World, position: la.Vector3f32) -> i32 {
	x, y, z := position.x, position.y, position.z
	chunk_position: la.Vector3f32 = {
		math.floor(x / CHUNK_WIDTH),
		math.floor(y / CHUNK_HEIGHT),
		math.floor(z / CHUNK_LENGTH),
	}
	if !(chunk_position in world.chunks) {
		return 0
	}

	lx := i32(x) % CHUNK_WIDTH
	ly := i32(y) % CHUNK_HEIGHT
	lz := i32(z) % CHUNK_LENGTH

	return world.chunks[chunk_position].blocks[lx][ly][lz]
}

draw_lvo_world :: proc(world: ^LVO_World) {
	for k, _ in world.chunks {
		draw_lvo_chunk(&world.chunks[k])
	}
}
