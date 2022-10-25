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
	subchunks:               map[la.Vector3f32]^LVO_Subchunk,
}

create_lvo_chunk :: proc(world: ^LVO_World, chunk_position: la.Vector3f32) -> ^LVO_Chunk {
	chunk: ^LVO_Chunk = new(LVO_Chunk)

	chunk.chunk_position = chunk_position
	chunk.position = {
		chunk_position.x * CHUNK_WIDTH,
		chunk_position.y * CHUNK_HEIGHT,
		chunk_position.z * CHUNK_LENGTH,
	}

	chunk.world = world
	chunk.has_mesh = false

	chunk.subchunks = {}
	for x in 0 ..= (CHUNK_WIDTH / SUBCHUNK_WIDTH) - 1 {
		for y in 0 ..= (CHUNK_HEIGHT / SUBCHUNK_HEIGHT) - 1 {
			for z in 0 ..= (CHUNK_LENGTH / SUBCHUNK_LENGTH) - 1 {
				subchunk_pos: la.Vector3f32 = {f32(x), f32(y), f32(z)}
				chunk.subchunks[subchunk_pos] = create_lvo_subchunk(chunk, subchunk_pos)
			}
		}
	}

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

update_lvo_chunk_subchunk_meshes :: proc(chunk: ^LVO_Chunk) {
	for pos in chunk.subchunks {
		subchunk := chunk.subchunks[pos]
		update_lvo_subchunk_mesh(subchunk)
	}
}

@(private = "file")
try_update_subchunk_mesh :: proc(chunk: ^LVO_Chunk, position: la.Vector3f32) {
	if position in chunk.subchunks {
		update_lvo_subchunk_mesh(chunk.subchunks[position])
	}
}

update_lvo_chunk_at_position :: proc(chunk: ^LVO_Chunk, position: la.Vector3f32) {
	x, y, z := position.x, position.y, position.z

	lx, ly, lz := i32(x) %% SUBCHUNK_WIDTH, i32(y) %% SUBCHUNK_HEIGHT, i32(z) %% SUBCHUNK_LENGTH

	clxyz := get_lvo_world_local_position(chunk.world, position)
	clx, cly, clz := clxyz.x, clxyz.y, clxyz.z

	sx, sy, sz :=
		math.floor(clx / SUBCHUNK_WIDTH),
		math.floor(cly / SUBCHUNK_HEIGHT),
		math.floor(clz / SUBCHUNK_LENGTH)

	update_lvo_subchunk_mesh(chunk.subchunks[{sx, sy, sz}])

	if lx == SUBCHUNK_WIDTH - 1 {
		try_update_subchunk_mesh(chunk, {sx + 1, sy, sz})
	}
	if lx == 0 {
		try_update_subchunk_mesh(chunk, {sx - 1, sy, sz})
	}
	if ly == SUBCHUNK_HEIGHT - 1 {
		try_update_subchunk_mesh(chunk, {sx, sy + 1, sz})
	}
	if ly == 0 {
		try_update_subchunk_mesh(chunk, {sx, sy - 1, sz})
	}
	if lz == SUBCHUNK_LENGTH - 1 {
		try_update_subchunk_mesh(chunk, {sx, sy, sz + 1})
	}
	if lz == 0 {
		try_update_subchunk_mesh(chunk, {sx, sy, sz - 1})
	}
}

update_lvo_chunk_mesh :: proc(chunk: ^LVO_Chunk) {
	chunk.has_mesh = true

	chunk.mesh_vertices = {}
	chunk.mesh_tex_coords = {}
	chunk.mesh_shading_values = {}

	chunk.mesh_index_counter = 0
	chunk.mesh_indices = {}

	for pos in chunk.subchunks {
		subchunk := chunk.subchunks[pos]
		append(&chunk.mesh_vertices, ..subchunk.mesh_vertices[:])
		append(&chunk.mesh_tex_coords, ..subchunk.mesh_tex_coords[:])
		append(&chunk.mesh_shading_values, ..subchunk.mesh_shading_values[:])

		for i in subchunk.mesh_indices {
			append(&chunk.mesh_indices, i + chunk.mesh_index_counter)
		}

		chunk.mesh_index_counter += subchunk.mesh_index_counter
	}

	send_lvo_chunk_to_gpu(chunk)
}

send_lvo_chunk_to_gpu :: proc(chunk: ^LVO_Chunk) {
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
