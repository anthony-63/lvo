package lvo

import "vendor:glfw"
import glfwb "vendor:glfw/bindings"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:strings"
import la "core:math/linalg"
import "core:math"

FOV :: 90.0
SENSITIVITY :: 0.002
SPEED :: 5.0

TEXTURE_MANAGER: LVO_Texture_Manager

BT_GRASS: LVO_Block_Type
BT_LOG: LVO_Block_Type
BT_COBBLESTONE: LVO_Block_Type
BT_DIRT: LVO_Block_Type
BT_STONE: LVO_Block_Type
BT_SAND: LVO_Block_Type
BT_PLANKS: LVO_Block_Type

LVO_Window :: struct {
	window:                                         glfw.WindowHandle,
	width:                                          f64,
	height:                                         f64,
	dt:                                             f32,
	last:                                           f32,
	shader:                                         LVO_Shader,
	camera:                                         LVO_Camera,
	mouse_dx, mouse_dy, last_mouse_x, last_mouse_y: f32,
}

cursor_captured := false
camera_temp_input: la.Vector3f32 = {0.0, 0.0, 0.0}

@(private = "file")
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
		cursor_captured = !cursor_captured
	}
	if cursor_captured {
		glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
	} else {
		glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_NORMAL)
	}
	input: f32 = 0.0
	switch action {
	case glfw.PRESS:
		input = -1.0
	case glfw.RELEASE:
		input = 1.0
	}

	switch key {
	case glfw.KEY_D:
		camera_temp_input.x += input
	case glfw.KEY_A:
		camera_temp_input.x -= input
	case glfw.KEY_W:
		camera_temp_input.z += input
	case glfw.KEY_S:
		camera_temp_input.z -= input
	case glfw.KEY_SPACE:
		camera_temp_input.y -= input
	case glfw.KEY_LEFT_SHIFT:
		camera_temp_input.y += input
	}
}

@(private = "file")
update_cursor_position :: proc(window: ^LVO_Window) {
	if !cursor_captured {
		return
	}
	x, y := glfw.GetCursorPos(window.window)
	window.mouse_dx = auto_cast x - window.last_mouse_x
	window.mouse_dy = auto_cast y - window.last_mouse_y
	window.last_mouse_x = auto_cast x
	window.last_mouse_y = auto_cast y
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

	glfw.SetInputMode(window, glfw.RAW_MOUSE_MOTION, 1)
	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

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


	ibo: u32 = 0
	gl.GenBuffers(1, &ibo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(BT_GRASS.indices) * size_of(BT_GRASS.indices[0]),
		&BT_GRASS.indices[0],
		gl.STATIC_DRAW,
	)

	tbo: u32 = 0
	gl.GenBuffers(1, &tbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, tbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(BT_GRASS.tex_coords) * size_of(BT_GRASS.tex_coords[0]),
		&BT_GRASS.tex_coords[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(1)

	sbo: u32 = 0
	gl.GenBuffers(1, &sbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, sbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(BT_GRASS.shading_values) * size_of(BT_GRASS.shading_values[0]),
		&BT_GRASS.shading_values[0],
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(2, 1, gl.FLOAT, false, 0, 0)
	gl.EnableVertexAttribArray(2)

	shader := create_lvo_shader("assets/shaders/voxel.vs", "assets/shaders/voxel.fs")
	use_lvo_shader(shader)
	camera := create_lvo_camera(shader, width, height, SENSITIVITY, SPEED)
	return(
		LVO_Window{
			window = window,
			shader = shader,
			dt = 0.0,
			last = 0.0,
			width = auto_cast width,
			height = auto_cast height,
			camera = camera,
		} \
	)
}

@(private = "file")
update :: proc(win: ^LVO_Window) {
	if !cursor_captured {
		win.camera.input = {0.0, 0.0, 0.0}
	}

	update_cursor_position(win)
	win.camera.input = camera_temp_input
	update_lvo_camera(&win.camera, win.dt)
	update_lvo_camera_matrices(&win.camera)

	win.dt = f32(glfw.GetTime()) - win.last
	win.last = f32(glfw.GetTime())

	win.camera.rotation.x -= win.mouse_dx * SENSITIVITY
	win.camera.rotation.y += win.mouse_dy * SENSITIVITY
	win.camera.rotation.y = max(-math.TAU / 4, min(math.TAU / 4, win.camera.rotation.y))

	win.mouse_dx = 0
	win.mouse_dy = 0
}

@(private = "file")
draw :: proc(win: ^LVO_Window) {
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D_ARRAY, TEXTURE_MANAGER.tex_array)
	sampler_location := gl.GetUniformLocation(
		win.shader.program,
		strings.clone_to_cstring("texture_sampler"),
	)
	gl.Uniform1i(sampler_location, 0)

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
