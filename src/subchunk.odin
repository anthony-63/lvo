package lvo

import la "core:math/linalg"
import "core:slice"

LVO_Subchunk :: struct {
	parent:              ^LVO_Chunk,
	world:               ^LVO_World,
	sposition:           la.Vector3f32,
	lposition:           la.Vector3f32,
	position:            la.Vector3f32,
	mesh_tex_coords:     [dynamic]f32,
	mesh_vertices:       [dynamic]f32,
	mesh_shading_values: [dynamic]f32,
	mesh_indices:        [dynamic]i32,
	mesh_index_counter:  i32,
}

create_lvo_subchunk :: proc(
	parent: ^LVO_Chunk,
	subchunk_position: la.Vector3f32,
) -> ^LVO_Subchunk {
	subchunk := new(LVO_Subchunk)
	subchunk.parent = parent
	subchunk.world = parent.world

	subchunk.sposition = subchunk_position
	subchunk.lposition = {
		subchunk.sposition.x * SUBCHUNK_WIDTH,
		subchunk.sposition.y * SUBCHUNK_HEIGHT,
		subchunk.sposition.z * SUBCHUNK_LENGTH,
	}
	subchunk.position = {
		subchunk.parent.position.x + subchunk.lposition.x,
		subchunk.parent.position.y + subchunk.lposition.y,
		subchunk.parent.position.z + subchunk.lposition.z,
	}
	subchunk.mesh_vertices = {}
	subchunk.mesh_indices = {}
	subchunk.mesh_tex_coords = {}
	subchunk.mesh_shading_values = {}

	return subchunk
}

@(private = "file")
add_face :: proc(face: i32, subchunk: ^LVO_Subchunk, block_type: LVO_Block_Type, x, y, z: f32) {
	vp_face := block_type.vertex_positions[face]
	vertex_positions := slice.clone(vp_face)

	for i in 0 ..= 3 {
		vertex_positions[i * 3 + 0] += x
		vertex_positions[i * 3 + 1] += y
		vertex_positions[i * 3 + 2] += z
	}

	append(&subchunk.mesh_vertices, ..vertex_positions)

	indices: []i32 = {0, 1, 2, 0, 2, 3}

	for i in 0 ..= 5 {
		indices[i] += subchunk.mesh_index_counter
	}

	append(&subchunk.mesh_indices, ..indices)
	subchunk.mesh_index_counter += 4

	tex_coords := block_type.tex_coords[face]
	shading_values := block_type.shading_values[face]

	append(&subchunk.mesh_tex_coords, ..tex_coords)
	append(&subchunk.mesh_shading_values, ..shading_values)
}

update_lvo_subchunk_mesh :: proc(subchunk: ^LVO_Subchunk) {
	subchunk.mesh_vertices = {}
	subchunk.mesh_tex_coords = {}
	subchunk.mesh_shading_values = {}

	subchunk.mesh_index_counter = 0
	subchunk.mesh_indices = {}

	for lx in 0 ..= SUBCHUNK_WIDTH - 1 {
		for ly in 0 ..= SUBCHUNK_HEIGHT - 1 {
			for lz in 0 ..= SUBCHUNK_LENGTH - 1 {
				plx, ply, plz :=
					int(subchunk.lposition.x) +
					lx,
					int(subchunk.lposition.y) +
					ly,
					int(subchunk.lposition.z) +
					lz
				block_number := subchunk.parent.blocks[plx][ply][plz]
				if block_number != 0 {
					block_type := subchunk.world.block_types[block_number]
					assert(len(block_type.vertex_positions) > 1)
					assert(len(block_type.tex_coords) > 1)
					assert(len(block_type.shading_values) > 1)
					x, y, z :=
						subchunk.position.x +
						f32(lx),
						subchunk.position.y +
						f32(ly),
						subchunk.position.z +
						f32(lz)
					if block_type.is_cube {
						if !is_lvo_world_block_opaque(
							   subchunk.world,
							   {x + 1.0, y, z},
						   ) {add_face(0, subchunk, block_type, x, y, z)}
						if !is_lvo_world_block_opaque(
							   subchunk.world,
							   {x - 1.0, y, z},
						   ) {add_face(1, subchunk, block_type, x, y, z)}
						if !is_lvo_world_block_opaque(
							   subchunk.world,
							   {x, y + 1.0, z},
						   ) {add_face(2, subchunk, block_type, x, y, z)}
						if !is_lvo_world_block_opaque(
							   subchunk.world,
							   {x, y - 1.0, z},
						   ) {add_face(3, subchunk, block_type, x, y, z)}
						if !is_lvo_world_block_opaque(
							   subchunk.world,
							   {x, y, z + 1.0},
						   ) {add_face(4, subchunk, block_type, x, y, z)}
						if !is_lvo_world_block_opaque(
							   subchunk.world,
							   {x, y, z - 1.0},
						   ) {add_face(5, subchunk, block_type, x, y, z)}
					} else {
						for i in 0 ..= len(block_type.vertex_positions) - 1 {
							add_face(auto_cast i, subchunk, block_type, x, y, z)
						}
					}
				}
			}
		}
	}
}
