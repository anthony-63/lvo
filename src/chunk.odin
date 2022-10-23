package lvo

import gl "vendor:OpenGL"
import la "core:math/linalg"
import "core:math"
import "core:slice"

CHUNK_WIDTH :: 16
CHUNK_HEIGHT :: 16
CHUNK_LENGTH :: 16

LVO_Chunk :: struct {
	chunk_position:          la.Vector3f32,
	position:                la.Vector3f32,
	has_mesh:                b64,
	mesh_tex_coords:         [dynamic]f32,
	mesh_vertices:           [dynamic]f32,
	mesh_shading_values:     [dynamic]f32,
	mesh_indices:            [dynamic]i32,
	mesh_index_counter:      i32,
	vao, vbo, tbo, sbo, ibo: u32,
	world:                   ^LVO_World,
	blocks:                  [CHUNK_WIDTH][CHUNK_HEIGHT][CHUNK_LENGTH]i32,
}

create_lvo_chunk :: proc(world: ^LVO_World, chunk_position: la.Vector3f32) -> LVO_Chunk {
	chunk: LVO_Chunk

	chunk.chunk_position = chunk_position
	chunk.position = {
		chunk_position.x * CHUNK_WIDTH,
		chunk_position.y * CHUNK_HEIGHT,
		chunk_position.z * CHUNK_LENGTH,
	}

	chunk.world = world

	chunk.has_mesh = false

	chunk.mesh_vertices = {}
	chunk.mesh_indices = {}
	chunk.mesh_tex_coords = {}
	chunk.mesh_shading_values = {}

	chunk.vao = 0
	gl.GenVertexArrays(1, &chunk.vao)
	gl.BindVertexArray(chunk.vao)

	chunk.vbo = 0
	gl.GenBuffers(1, &chunk.vbo)

	chunk.tbo = 0
	gl.GenBuffers(1, &chunk.tbo)

	chunk.sbo = 0
	gl.GenBuffers(1, &chunk.sbo)

	chunk.ibo = 0
	gl.GenBuffers(1, &chunk.ibo)

	return chunk
}

@(private = "file")
add_face :: proc(face: i32, chunk: ^LVO_Chunk, block_type: LVO_Block_Type, x, y, z: f32) {
	vp_face := block_type.vertex_positions[face]
	vertex_positions := slice.clone(vp_face)

	for i in 0 ..= 3 {
		vertex_positions[i * 3 + 0] += x
		vertex_positions[i * 3 + 1] += y
		vertex_positions[i * 3 + 2] += z
	}

	append(&chunk.mesh_vertices, ..vertex_positions)

	indices: []i32 = {0, 1, 2, 0, 2, 3}

	for i in 0 ..= 5 {
		indices[i] += chunk.mesh_index_counter
	}

	append(&chunk.mesh_indices, ..indices)
	chunk.mesh_index_counter += 4

	tex_coords := block_type.tex_coords[face]
	shading_values := block_type.shading_values[face]

	append(&chunk.mesh_tex_coords, ..tex_coords)
	append(&chunk.mesh_shading_values, ..shading_values)
}

update_lvo_chunk_mesh :: proc(chunk: ^LVO_Chunk) {
	chunk.has_mesh = true

	chunk.mesh_vertices = {}
	chunk.mesh_tex_coords = {}
	chunk.mesh_shading_values = {}

	chunk.mesh_index_counter = 0
	chunk.mesh_indices = {}

	for lx in 0 ..= CHUNK_WIDTH - 1 {
		for ly in 0 ..= CHUNK_HEIGHT - 1 {
			for lz in 0 ..= CHUNK_LENGTH - 1 {
				block_number := chunk.blocks[lx][ly][lz]
				if block_number != 0 {
					block_type := chunk.world.block_types[block_number]
					x, y, z :=
						chunk.position.x +
						f32(lx),
						chunk.position.y +
						f32(ly),
						chunk.position.z +
						f32(lz)

					if !(get_lvo_world_block_number(chunk.world, {x + 1.0, y, z}) !=
						   0) {add_face(0, chunk, block_type, x, y, z)}
					if !(get_lvo_world_block_number(chunk.world, {x - 1.0, y, z}) !=
						   0) {add_face(1, chunk, block_type, x, y, z)}
					if !(get_lvo_world_block_number(chunk.world, {x, y + 1.0, z}) !=
						   0) {add_face(2, chunk, block_type, x, y, z)}
					if !(get_lvo_world_block_number(chunk.world, {x, y - 1.0, z}) !=
						   0) {add_face(3, chunk, block_type, x, y, z)}
					if !(get_lvo_world_block_number(chunk.world, {x, y, z + 1.0}) !=
						   0) {add_face(4, chunk, block_type, x, y, z)}
					if !(get_lvo_world_block_number(chunk.world, {x, y, z - 1.0}) !=
						   0) {add_face(5, chunk, block_type, x, y, z)}
				}
			}
		}
	}

	if chunk.mesh_index_counter == 0 {
		return
	}

	gl.BindVertexArray(chunk.vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, chunk.vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(chunk.mesh_vertices) * size_of(chunk.mesh_vertices[0]),
		&chunk.mesh_vertices[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(0)

	gl.BindBuffer(gl.ARRAY_BUFFER, chunk.tbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(chunk.mesh_tex_coords) * size_of(chunk.mesh_tex_coords[0]),
		&chunk.mesh_tex_coords[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(1)

	gl.BindBuffer(gl.ARRAY_BUFFER, chunk.sbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(chunk.mesh_shading_values) * size_of(chunk.mesh_shading_values[0]),
		&chunk.mesh_shading_values[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(2, 1, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(2)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, chunk.ibo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(chunk.mesh_indices) * size_of(chunk.mesh_indices[0]),
		&chunk.mesh_indices[0],
		gl.STATIC_DRAW,
	)
}

draw_lvo_chunk :: proc(chunk: ^LVO_Chunk) {
	if chunk.mesh_index_counter == 0 {
		return
	}

	gl.BindVertexArray(chunk.vao)
	gl.DrawElements(gl.TRIANGLES, auto_cast len(chunk.mesh_indices), gl.UNSIGNED_INT, nil)
}
