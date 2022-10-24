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
	fmt.println("[LVO] Creating texture manager")
	world.texture_manager = create_lvo_texture_manager(16, 16, 256, texture_pack)
	fmt.println("[LVO] Created texture manager")
	fmt.println("[LVO] Loading textures...")
	load_all_lvo_blocks(world, texture_pack)
	generate_lvo_texture_manager_mipmaps()
}

@(private = "file")
random_get :: proc(array: $T/[]$E, r: ^rand.Rand = nil) -> (res: E) {
	n := i64(len(array))
	if n < 1 {
		return E{}
	}
	return array[rand.int63_max(n, r)]
}

create_lvo_world :: proc() -> ^LVO_World {
	world := new(LVO_World)
	fmt.println("[LVO] Allocated world\n[LVO] Initializing textures")

	init_lvo_textures(world, "default")

	for x in 0 ..= 7 {
		for z in 0 ..= 7 {
			chunk_position: la.Vector3f32 = {f32(x) - 4, -1, f32(z) - 4}
			current_chunk := create_lvo_chunk(world, chunk_position)
			for i in 0 ..= CHUNK_WIDTH - 1 {
				for j in 0 ..= CHUNK_HEIGHT - 1 {
					for k in 0 ..= CHUNK_LENGTH - 1 {
						block_choice: i32 = 0
						if j == 14 {
							block_choice = rand.choice([]i32{0, 4})
						} else if j == 15 {
							block_choice = rand.choice([]i32{0, 2})
						} else {
							block_choice = rand.choice([]i32{0, 0, 5})
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

		update_lvo_chunk_mesh(world.chunks[k])
	}

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

	lx := u32(x) % CHUNK_WIDTH
	ly := u32(y) % CHUNK_HEIGHT
	lz := u32(z) % CHUNK_LENGTH

	return world.chunks[chunk_position].blocks[lx][ly][lz]
}

draw_lvo_world :: proc(world: ^LVO_World) {
	for k, _ in world.chunks {
		draw_lvo_chunk(world.chunks[k])
	}
}
