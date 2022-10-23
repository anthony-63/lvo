package lvo_models

LVO_Model :: struct {
	vertices:    [][]f32,
	tex_coords:  [][]f32,
	shading:     [][]f32,
	is_cube:     b32,
	transparent: b32,
}
