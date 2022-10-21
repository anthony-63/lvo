package lvo

import gl "vendor:OpenGL"
import "core:c"
import "core:os"
import "core:strings"
import "core:fmt"
import png "core:image/png"
import image "core:image"

LVO_Texture_Manager :: struct {
	tex_width, tex_height: i32,
	max_textures:          i32,
	textures:              [dynamic]string,
	tex_array:             u32,
	texture_pack:          string,
}

create_lvo_texture_manager :: proc(
	tex_width, tex_height, max_textures: i32,
	texture_pack: string,
) -> LVO_Texture_Manager {
	tex_manager := LVO_Texture_Manager{}
	tex_manager.tex_width = tex_width
	tex_manager.tex_height = tex_height
	tex_manager.max_textures = max_textures
	tex_manager.textures = [dynamic]string{}
	tex_manager.tex_array = 0
	tex_manager.texture_pack = texture_pack

	gl.GenTextures(1, &tex_manager.tex_array)
	gl.BindTexture(gl.TEXTURE_2D_ARRAY, tex_manager.tex_array)

	gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexImage3D(
		gl.TEXTURE_2D_ARRAY,
		0,
		gl.RGBA,
		tex_width,
		tex_height,
		max_textures,
		0,
		gl.RGBA,
		gl.UNSIGNED_BYTE,
		nil,
	)

	return tex_manager
}

generate_lvo_texture_manager_mipmaps :: proc() {
	gl.GenerateMipmap(gl.TEXTURE_2D_ARRAY)
}

add_lvo_texture :: proc(texture_manager: ^LVO_Texture_Manager, texture: string) {
	texture_exists := false
	for i in texture_manager.textures {
		if i == texture {
			texture_exists = true
		}
	}
	if !texture_exists {
		append(&texture_manager.textures, texture)
		texture_path_sb := strings.builder_make()
		fmt.sbprintf(
			&texture_path_sb,
			"assets/texturepacks/%v/%v.png",
			texture_manager.texture_pack,
			texture,
		)
		texture_path := strings.to_string(texture_path_sb)
		defer delete(texture_path)

		img, err := png.load_from_file(texture_path)
		defer image.destroy(img)
		if err != nil {
			fmt.panicf("Failed to read texture file: %s\nError: %v", texture_path, err)
		}


		index := 0
		for v, i in texture_manager.textures {
			if v == texture {
				index = i
				break
			}
		}

		fmt.println("[LVO] Loading texture: ", texture_path)

		gl.BindTexture(gl.TEXTURE_2D_ARRAY, texture_manager.tex_array)
		gl.TexSubImage3D(
			gl.TEXTURE_2D_ARRAY,
			0,
			0,
			0,
			i32(index),
			texture_manager.tex_width,
			texture_manager.tex_height,
			1,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			&img.pixels.buf[0],
		)

	}
}