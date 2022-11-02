package lvo

import "core:fmt"
import "core:io"
import "core:slice"
import la "core:math/linalg"
import "models"


LVO_Block_Type :: struct {
	name:             string,
	vertex_positions: [][]f32,
	tex_coords:       [][]f32,
	colliders:        []LVO_Collider,
	shading_values:   [][]f32,
	indices:          []i32,
	transparent:      b32,
	is_cube:          b32,
}

@(private = "file")
set_block_face :: proc(block_type: ^LVO_Block_Type, face: i32, tex_idx: f32) {
	if face > auto_cast len(block_type.tex_coords) - 1 {
		return
	}

	block_type.tex_coords[face] = slice.clone(block_type.tex_coords[face])

	for vertex in 0 ..= 3 {
		block_type.tex_coords[face][vertex * 3 + 2] = tex_idx
	}
}


create_lvo_air :: proc() -> LVO_Block_Type {
	return LVO_Block_Type{name = "air"}
}

create_lvo_block_type :: proc(
	name := "unknown",
	texture_manager: ^LVO_Texture_Manager,
	block_face_textures: map[string]string,
	model: models.LVO_Model,
) -> LVO_Block_Type {
	block_type := LVO_Block_Type {
		name             = name,
		vertex_positions = make([][]f32, len(model.vertices)),
		tex_coords       = make([][]f32, len(model.tex_coords)),
		shading_values   = make([][]f32, len(model.shading)),
		colliders        = make([]LVO_Collider, len(model.colliders)),
		transparent      = model.transparent,
		is_cube          = model.is_cube,
	}
	for inner, i in model.vertices {
		block_type.vertex_positions[i] = slice.clone(inner)
	}
	for inner, i in model.tex_coords {
		block_type.tex_coords[i] = slice.clone(inner)
	}
	for inner, i in model.shading {
		block_type.shading_values[i] = slice.clone(inner)
	}
	for inner, i in model.colliders {
		block_type.colliders[i] = create_lvo_collider(inner[0], inner[1])
	}

	failed := false
	assert(len(block_type.vertex_positions) > 1)
	assert(len(block_type.tex_coords) > 1)
	assert(len(block_type.shading_values) > 1)
	if (failed) {
		panic("Block creation failed")
	}

	for face in block_face_textures {
		texture := block_face_textures[face]
		add_lvo_texture(texture_manager, texture)
		index: f32 = 0.0
		for v, i in texture_manager.textures {
			if v == texture {
				index = f32(i)
				break
			}
		}

		block_face_locations := map[string]i32 {
			"right"  = 0,
			"left"   = 1,
			"top"    = 2,
			"bottom" = 3,
			"front"  = 4,
			"back"   = 5,
		}
		if face == "all" {
			set_block_face(&block_type, 0, index)
			set_block_face(&block_type, 1, index)
			set_block_face(&block_type, 2, index)
			set_block_face(&block_type, 3, index)
			set_block_face(&block_type, 4, index)
			set_block_face(&block_type, 5, index)
		} else if face == "sides" {
			set_block_face(&block_type, 0, index)
			set_block_face(&block_type, 1, index)
			set_block_face(&block_type, 4, index)
			set_block_face(&block_type, 5, index)
		} else {
			set_block_face(&block_type, block_face_locations[face], index)
		}
	}

	return block_type
}
