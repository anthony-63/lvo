package lvo

WIDTH :: 1280
HEIGHT :: 720
TITLE :: "LOE | Alpha v0.0.1"

main :: proc() {
	window := create_lvo_window(WIDTH, HEIGHT, TITLE)
	run_lvo_window(&window)
}
