package lvo

import "models"

load_all_lvo_blocks :: proc(world: ^LVO_World, texture_pack: string) {
	append(&world.block_types, create_lvo_air())
	append(
		&world.block_types,
		create_lvo_block_type("cobblestone", &world.texture_manager, {"all" = "cobblestone.png"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"grass",
			&world.texture_manager,
			{"top" = "grass.png", "bottom" = "dirt.png", "sides" = "grass_side.png"},
		),
	)
	append(
		&world.block_types,
		create_lvo_block_type("grass_block", &world.texture_manager, {"all" = "grass.png"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("dirt", &world.texture_manager, {"all" = "dirt.png"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("stone", &world.texture_manager, {"all" = "stone.png"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("sand", &world.texture_manager, {"all" = "sand.png"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type("planks", &world.texture_manager, {"all" = "planks.png"}),
	)
	append(
		&world.block_types,
		create_lvo_block_type(
			"log",
			&world.texture_manager,
			{"top" = "log_y.png", "bottom" = "log_y.png", "sides" = "log_side.png"},
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
