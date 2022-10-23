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

LVO_Window :: struct {
	window:                                         glfw.WindowHandle,
	width:                                          f64,
	height:                                         f64,
	dt:                                             f32,
	last:                                           f32,
	shader:                                         LVO_Shader,
	camera:                                         LVO_Camera,
	mouse_dx, mouse_dy, last_mouse_x, last_mouse_y: f32,
	world:                                          ^LVO_World,
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

create_lvo_window :: proc(width, height: int, title: string) -> LVO_Window {
	window: LVO_Window

	if glfw.Init() != 1 {
		fmt.println("Failed to initialize glfw!")
		os.exit(1)
	}

	glfw.WindowHint(glfw.RESIZABLE, 0)

	window.window = glfw.CreateWindow(
		auto_cast width,
		auto_cast height,
		strings.clone_to_cstring(title),
		nil,
		nil,
	)

	glfw.MakeContextCurrent(window.window)

	gl.load_up_to(4, 1, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, i32(width), i32(height))

	glfw.SetKeyCallback(window.window, key_callback)

	if !glfwb.RawMouseMotionSupported() {
		fmt.panicf("Raw mouse motion is not supported!")
	} else {
		fmt.println("[LVO] Using raw mouse motion")
	}

	glfw.SetInputMode(window.window, glfw.RAW_MOUSE_MOTION, 1)
	glfw.SetInputMode(window.window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	cursor_captured = true

	gl.Enable(gl.MULTISAMPLE)
	gl.Enable(gl.DEPTH_TEST)
	// gl.Enable(gl.CULL_FACE)

	window.world = create_lvo_world()
	window.shader = create_lvo_shader("assets/shaders/voxel.vs", "assets/shaders/voxel.fs")
	use_lvo_shader(window.shader)
	window.camera = create_lvo_camera(window.shader, width, height, SENSITIVITY, SPEED)
	return window
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
	gl.BindTexture(gl.TEXTURE_2D_ARRAY, win.world.texture_manager.tex_array)
	sampler_location := gl.GetUniformLocation(
		win.shader.program,
		strings.clone_to_cstring("texture_sampler"),
	)
	gl.Uniform1i(sampler_location, 0)

	gl.ClearColor(0.1, 0.2, 0.3, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	draw_lvo_world(win.world)
}

run_lvo_window :: proc(win: ^LVO_Window) {
	for !glfw.WindowShouldClose(win.window) {
		glfw.PollEvents()
		update(win)
		draw(win)
		glfw.SwapBuffers(win.window)
	}
}
