package lvo_models

import la "core:math/linalg"

LVO_Model :: struct {
	vertices:    [][]f32,
	tex_coords:  [][]f32,
	colliders:   [][]la.Vector3f32,
	shading:     [][]f32,
	is_cube:     b32,
	transparent: b32,
}
