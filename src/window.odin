package lvo

import "vendor:glfw"
import glfwb "vendor:glfw/bindings"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/linalg"
import "core:math"

FOV :: 90.0

x: f32 = 0.0

TEXTURE_MANAGER: LVO_Texture_Manager

BT_GRASS: LVO_Block_Type
BT_LOG: LVO_Block_Type
BT_COBBLESTONE: LVO_Block_Type
BT_DIRT: LVO_Block_Type
BT_STONE: LVO_Block_Type
BT_SAND: LVO_Block_Type
BT_PLANKS: LVO_Block_Type

LVO_Window :: struct {
	window: glfw.WindowHandle,
	width:  f64,
	height: f64,
	dt:     f32,
	last:   f32,
	shader: LVO_Shader,
}

cursor_captured := false

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
		cursor_captured = !cursor_captured
	}
}

init_lvo_textures :: proc(texture_pack: string) {
	TEXTURE_MANAGER = create_lvo_texture_manager(16, 16, 256, texture_pack)

	BT_LOG = create_lvo_block_type(
		"log",
		&TEXTURE_MANAGER,
		map[string]string{"top" = "log_y", "bottom" = "log_y", "sides" = "log_side"},
	)
	BT_COBBLESTONE = create_lvo_block_type(
		"cobblestone",
		&TEXTURE_MANAGER,
		map[string]string{"all" = "cobblestone"},
	)
	BT_DIRT = create_lvo_block_type("dirt", &TEXTURE_MANAGER, map[string]string{"all" = "dirt"})
	BT_STONE = create_lvo_block_type("stone", &TEXTURE_MANAGER, map[string]string{"all" = "stone"})
	BT_SAND = create_lvo_block_type("sand", &TEXTURE_MANAGER, map[string]string{"all" = "sand"})
	BT_PLANKS = create_lvo_block_type(
		"planks",
		&TEXTURE_MANAGER,
		map[string]string{"all" = "planks"},
	)
	BT_GRASS = create_lvo_block_type(
		"grass",
		&TEXTURE_MANAGER,
		map[string]string{"top" = "grass", "bottom" = "dirt", "sides" = "grass_side"},
	)
	generate_lvo_texture_manager_mipmaps()
}

create_lvo_window :: proc(width, height: int, title: string) -> LVO_Window {
	if glfw.Init() != 1 {
		fmt.println("Failed to initialize glfw!")
		os.exit(1)
	}

	glfw.WindowHint(glfw.RESIZABLE, 0)

	window := glfw.CreateWindow(
		auto_cast width,
		auto_cast height,
		strings.clone_to_cstring(title),
		nil,
		nil,
	)

	glfw.SetInputMode(window, glfw.CURSOR_HIDDEN, 1)

	glfw.MakeContextCurrent(window)

	gl.load_up_to(4, 1, glfw.gl_set_proc_address)

	init_lvo_textures("default")

	gl.Viewport(0, 0, i32(width), i32(height))

	glfw.SetKeyCallback(window, key_callback)

	if !glfwb.RawMouseMotionSupported() {
		fmt.panicf("Raw mouse motion is not supported!")
	} else {
		fmt.println("[LVO] Using raw mouse motion")
	}


	cursor_captured = true

	gl.Enable(gl.MULTISAMPLE)
	gl.Enable(gl.DEPTH_TEST)

	vao: u32 = 0
	gl.GenVertexArrays(0, &vao)
	gl.BindVertexArray(vao)

	vbo: u32 = 0
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(BT_GRASS.vertex_positions) * size_of(BT_GRASS.vertex_positions[0]),
		&BT_GRASS.vertex_positions[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(0)

	tbo: u32 = 0
	gl.GenBuffers(1, &tbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, tbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(BT_LOG.tex_coords) * size_of(BT_LOG.tex_coords[0]),
		&BT_LOG.tex_coords[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(1)

	ibo: u32 = 0
	gl.GenBuffers(1, &ibo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(BT_GRASS.indices) * size_of(BT_GRASS.indices[0]),
		&BT_GRASS.indices[0],
		gl.STATIC_DRAW,
	)
	shader := create_lvo_shader("assets/shaders/voxel.vs", "assets/shaders/voxel.fs")
	use_lvo_shader(shader)

	return(
		LVO_Window{
			window = window,
			shader = shader,
			dt = 0.0,
			last = 0.0,
			width = auto_cast width,
			height = auto_cast height,
		} \
	)
}

@(private = "file")
update :: proc(win: ^LVO_Window) {
	// if cursor_captured {
	// 	glfw.SetInputMode(win.window, glfw.RAW_MOUSE_MOTION, 1)
	// } else {
	// 	glfw.SetInputMode(win.window, glfw.CURSOR_NORMAL, 1)
	// }
	win.dt = f32(glfw.GetTime()) - win.last
	win.last = f32(glfw.GetTime())
	x += win.dt


	aspect_ratio: f32 = auto_cast (win.width / win.height)
	p_matrix := linalg.matrix4_perspective_f32(FOV, aspect_ratio, 0.1, 5000.0)

	m_matrix := linalg.MATRIX4F32_IDENTITY
	m_matrix *= linalg.matrix4_translate(linalg.Vector3f32{0.0, 0.0, -2.0})
	m_matrix *= linalg.matrix4_rotate_f32(x, linalg.Vector3f32{1.0, 0.0, 0.0})
	m_matrix *= linalg.matrix4_rotate_f32(
		math.sin(x / 3 * 2) / 2,
		linalg.Vector3f32{0.0, 1.0, 0.0},
	)

	v_matrix := linalg.MATRIX4F32_IDENTITY

	mvp_matrix := (p_matrix * v_matrix) * m_matrix

	lvo_shader_set_uniform_m4(win.shader, "mvp", mvp_matrix)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D_ARRAY, TEXTURE_MANAGER.tex_array)
	sampler_location := gl.GetUniformLocation(
		win.shader.program,
		strings.clone_to_cstring("texture_sampler"),
	)
	gl.Uniform1i(sampler_location, 0)
}

@(private = "file")
draw :: proc(win: ^LVO_Window) {
	gl.ClearColor(0.1, 0.2, 0.3, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	gl.DrawElements(gl.TRIANGLES, auto_cast len(BT_GRASS.indices), gl.UNSIGNED_INT, nil)
}

run_lvo_window :: proc(win: ^LVO_Window) {
	for !glfw.WindowShouldClose(win.window) {
		glfw.PollEvents()
		update(win)
		draw(win)
		glfw.SwapBuffers(win.window)
	}
}
