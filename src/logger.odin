package lvo

import "core:time"
import "core:strings"
import "core:fmt"

setup_lvo_logger :: proc(log_file: string) {
	string_builder := strings.builder_make()
	time_ := time.now()
	fmt.sbprintln(&string_builder, log_file, time_._nsec)

	LVO_LOG_FILE = strings.to_string(string_builder)
}

lvo_log :: proc(args: ..any) {
	fmt.printf("[LVO] ")
	fmt.println(..args)
}
