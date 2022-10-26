package lvo

import "vendor:glfw"
import glfwb "vendor:glfw/bindings"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:strings"
import la "core:math/linalg"
import "core:math"

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

@(private = "file")
key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
		CURSOR_CAPTURED = !CURSOR_CAPTURED
	}
	if CURSOR_CAPTURED {
		glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)
	} else {
		glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_NORMAL)
	}
	input: f32 = 0.0
	switch action {
	case glfw.PRESS:
		input = 1.0
	case glfw.RELEASE:
		input = -1.0
	}

	switch key {
	case glfw.KEY_D:
		CAMERA_TEMP_INPUT.x += input
	case glfw.KEY_A:
		CAMERA_TEMP_INPUT.x -= input
	case glfw.KEY_W:
		CAMERA_TEMP_INPUT.z += input
	case glfw.KEY_S:
		CAMERA_TEMP_INPUT.z -= input
	case glfw.KEY_SPACE:
		CAMERA_TEMP_INPUT.y += input
	case glfw.KEY_LEFT_SHIFT:
		CAMERA_TEMP_INPUT.y -= input
	}
}

@(private = "file")
update_cursor_position :: proc(window: ^LVO_Window) {
	if !CURSOR_CAPTURED {
		return
	}
	x, y := glfw.GetCursorPos(window.window)
	window.mouse_dx = auto_cast x - window.last_mouse_x
	window.mouse_dy = auto_cast y - window.last_mouse_y
	window.last_mouse_x = auto_cast x
	window.last_mouse_y = auto_cast y
}


@(private = "file")
get_mouse_bt_input :: proc(window: ^LVO_Window) {
	if (glfw.GetMouseButton(window.window, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS) && !MBL_PRESS {
		MBL_PRESS = true
		hit_ray := create_lvo_hitray(LVO_WORLD, window.camera.rotation, window.camera.position)
		for hit_ray.distance < HIT_RANGE {
			step := step_lvo_hitray(&hit_ray, proc(cblock: la.Vector3f32, nblock: la.Vector3f32) {
				lvo_log("Breaking block: ", cblock)
				set_lvo_world_block(LVO_WORLD, nblock, 0)
			})
			if step {
				break
			}
		}
	}
	if (glfw.GetMouseButton(window.window, glfw.MOUSE_BUTTON_LEFT) == glfw.RELEASE) && MBL_PRESS {
		MBL_PRESS = false
	}
	if (glfw.GetMouseButton(window.window, glfw.MOUSE_BUTTON_RIGHT) == glfw.PRESS) && !MBR_PRESS {
		MBR_PRESS = true
		hit_ray := create_lvo_hitray(LVO_WORLD, window.camera.rotation, window.camera.position)
		for hit_ray.distance < HIT_RANGE {
			step := step_lvo_hitray(&hit_ray, proc(cblock: la.Vector3f32, nblock: la.Vector3f32) {
				lvo_log("Placing block: ", cblock)
				set_lvo_world_block(LVO_WORLD, cblock, HOLDING)
			})
			if step {
				break
			}
		}
	}
	if (glfw.GetMouseButton(window.window, glfw.MOUSE_BUTTON_RIGHT) == glfw.RELEASE) && MBR_PRESS {
		MBR_PRESS = false
	}
	if (glfw.GetMouseButton(window.window, glfw.MOUSE_BUTTON_MIDDLE) == glfw.PRESS) && !MBM_PRESS {
		MBM_PRESS = true
		hit_ray := create_lvo_hitray(LVO_WORLD, window.camera.rotation, window.camera.position)
		for hit_ray.distance < HIT_RANGE {
			step := step_lvo_hitray(&hit_ray, proc(cblock: la.Vector3f32, nblock: la.Vector3f32) {
				HOLDING = get_lvo_world_block_number(LVO_WORLD, nblock)
				lvo_log("Holding block id: ", HOLDING)
			})
			if step {
				break
			}
		}
	}
	if (glfw.GetMouseButton(window.window, glfw.MOUSE_BUTTON_MIDDLE) == glfw.RELEASE) &&
	   MBM_PRESS {
		MBM_PRESS = false
	}
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
	glfw.SetWindowUserPointer(window.window, &window)
	if !glfwb.RawMouseMotionSupported() {
		fmt.panicf("Raw mouse motion is not supported!")
	} else {
		fmt.println("[LVO] Using raw mouse motion")
	}

	glfw.SetInputMode(window.window, glfw.RAW_MOUSE_MOTION, 1)
	fmt.println("[LVO] Raw mouse input enabled")
	// glfw.SetInputMode(window.window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	CURSOR_CAPTURED = false

	gl.Enable(gl.MULTISAMPLE)
	gl.Enable(gl.DEPTH_TEST)
	fmt.println("[LVO] Enabled sampling and depth testing")

	gl.Enable(gl.CULL_FACE)

	LVO_WORLD = create_lvo_world()
	lvo_log("Created world")

	window.shader = create_lvo_shader("assets/shaders/voxel.vs", "assets/shaders/voxel.fs")
	lvo_log("Loaded shaders")

	use_lvo_shader(window.shader)
	fmt.println("[LVO] Using shaders")
	window.camera = create_lvo_camera(window.shader, width, height, SENSITIVITY, SPEED)
	fmt.println("[LVO] Created camera")

	return window
}

@(private = "file")
update :: proc(win: ^LVO_Window) {
	if !CURSOR_CAPTURED {
		win.camera.input = {0.0, 0.0, 0.0}
	}

	update_cursor_position(win)
	win.camera.input = CAMERA_TEMP_INPUT
	update_lvo_camera(&win.camera, win.dt)
	update_lvo_camera_matrices(&win.camera)

	win.dt = f32(glfw.GetTime()) - win.last
	win.last = f32(glfw.GetTime())

	win.camera.rotation.x += win.mouse_dx * SENSITIVITY
	win.camera.rotation.y += win.mouse_dy * SENSITIVITY
	win.camera.rotation.y = max(-math.TAU / 4, min(math.TAU / 4, win.camera.rotation.y))

	win.mouse_dx = 0
	win.mouse_dy = 0
	get_mouse_bt_input(win)

	// set_lvo_world_block(win.world, win.camera.position, 7)
}

@(private = "file")
draw :: proc(win: ^LVO_Window) {
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D_ARRAY, LVO_WORLD.texture_manager.tex_array)
	sampler_location := gl.GetUniformLocation(
		win.shader.program,
		strings.clone_to_cstring("texture_sampler"),
	)
	gl.Uniform1i(sampler_location, 0)

	gl.ClearColor(0.1, 0.2, 0.3, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	draw_lvo_world(LVO_WORLD)
}

run_lvo_window :: proc(win: ^LVO_Window) {
	for !glfw.WindowShouldClose(win.window) {
		glfw.PollEvents()
		update(win)
		draw(win)
		glfw.SwapBuffers(win.window)
	}
}
