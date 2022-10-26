package lvo

main :: proc() {
	window := create_lvo_window(WIDTH, HEIGHT, TITLE)
	run_lvo_window(&window)
}
