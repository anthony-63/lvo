package lvo

import "models"

load_all_lvo_blocks :: proc(world: ^LVO_World, texture_pack: string) {
	append(&world.block_types, create_lvo_air())
	append(
		&world.block_types,
		create_lvo_block_type(
			"cobblestone",
			&world.texture_manager,
			map[string]string{"all" = "cobblestone"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"grass",
			&world.texture_manager,
			map[string]string{"top" = "grass", "bottom" = "dirt", "sides" = "grass_side"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"grass_block",
			&world.texture_manager,
			map[string]string{"all" = "grass"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type("dirt", &world.texture_manager, map[string]string{"all" = "dirt"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("stone", &world.texture_manager, map[string]string{"all" = "stone"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("sand", &world.texture_manager, map[string]string{"all" = "sand"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"planks",
			&world.texture_manager,
			map[string]string{"all" = "planks"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"log",
			&world.texture_manager,
			map[string]string{"top" = "log_y", "bottom" = "log_y", "sides" = "log_side"},
		),
	)
	// append(
	// 	&world.block_types,
	// 	create_lvo_block_type(
	// 		"daisy",
	// 		&world.texture_manager,
	// 		map[string]string{"all" = "yellow_flower"},
	// 		models.LVO_PLANT_MODEL,
	// 	),
	// )
	// append(
	// 	&world.block_types,
	// 	create_lvo_block_type(
	// 		"rose",
	// 		&world.texture_manager,
	// 		map[string]string{"all" = "red_rose"},
	// 		models.LVO_PLANT_MODEL,
	// 	),
	// )


}
