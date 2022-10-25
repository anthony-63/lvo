package lvo

import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:fmt"
import "models"

LVO_Config_Parser :: struct {
	line_number:     i32,
	texture_manager: ^LVO_Texture_Manager,
}


LVO_Config_Parser_Error :: struct {
	code:   i32,
	reason: string,
}

create_lvo_config_parser :: proc(texture_manager: ^LVO_Texture_Manager) -> LVO_Config_Parser {
	return LVO_Config_Parser{line_number = 0, texture_manager = texture_manager}
}

@(private = "file")
parse_lconf_line :: proc(cfg_parser: ^LVO_Config_Parser, line: string) -> LVO_Block_Type {
	tokens := strings.split(line, "; ")
	name := ""
	textures: map[string]string = {}
	model: models.LVO_Model
	model_name: string
	transparent := false
	i := 0
	for i < len(tokens) {
		if i == 0 {
			name = tokens[i]
		} else if i == 1 {
			model_name = tokens[i]
			switch tokens[i] {
			case "cube":
				model = models.LVO_CUBE_MODEL
			case "plant":
				model = models.LVO_PLANT_MODEL
			case "cactus":
				model = models.LVO_CACTUS_MODEL
			}
		} else if i == 2 {
			switch tokens[i] {
			case "opaque":
				transparent = false
			case "transparent":
				transparent = true
			}
		} else {
			split := strings.split(tokens[i], " ")
			side := split[0]
			texture := split[1]
			textures[side] = texture
		}

		i += 1
	}
	lvo_log("Parsed block:", name, textures, model_name)
	return create_lvo_block_type(name, cfg_parser.texture_manager, textures)
}

parse_lconf_source :: proc(
	cfg_parser: ^LVO_Config_Parser,
	source: string,
) -> (
	[dynamic]LVO_Block_Type,
	LVO_Config_Parser_Error,
) {
	src := source
	block_types: [dynamic]LVO_Block_Type
	for line in strings.split_lines_iterator(&src) {
		append(&block_types, parse_lconf_line(cfg_parser, line))
	}

	return block_types, LVO_Config_Parser_Error{code = 0}
}


parse_lconf_file :: proc(cfg_parser: ^LVO_Config_Parser, name: string) -> [dynamic]LVO_Block_Type {
	config_path := filepath.join({"assets", "config", name})
	source, ok := os.read_entire_file_from_filename(config_path)
	defer delete(source)
	if !ok {
		fmt.panicf("Failed to read config file: %v\n", config_path)
	}
	str_src := string(source)

	parsed, err := parse_lconf_source(cfg_parser, str_src)
	if err.code != 0 {
		fmt.panicf(
			"Failed to parse lconf file, exited with code: %d\nReason: %v\n",
			err.code,
			err.reason,
		)
	}
	return parsed
}
