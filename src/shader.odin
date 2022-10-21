package lvo

import "core:fmt"
import "core:os"
import gl "vendor:OpenGL"
import "core:math/linalg"
import "core:strings"

LVO_Shader :: struct {
	program: u32,
}

create_lvo_shader :: proc(vs_path, fs_path: string) -> LVO_Shader {
	program, ok := gl.load_shaders(vs_path, fs_path)
	if !ok {
		fmt.panicf("Failed to load shader files: %s, %s\nError: %v", vs_path, fs_path, ok)
	}
	return LVO_Shader{program = program}
}

lvo_shader_set_uniform_m4 :: proc(shader: LVO_Shader, name: string, mat: linalg.Matrix4f32) {
	location := gl.GetUniformLocation(shader.program, strings.clone_to_cstring(name))
	marray := transmute([4 * 4]f32)mat
	gl.UniformMatrix4fv(location, 1, false, &marray[0])
}

use_lvo_shader :: proc(shader: LVO_Shader) {
	gl.UseProgram(shader.program)
}

delete_lvo_shader :: proc(shader: LVO_Shader) {
	gl.DeleteProgram(shader.program)
}
