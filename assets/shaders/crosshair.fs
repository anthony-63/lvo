#version 410

out vec4 color;

in vec3 tex_coord_pass;

in sampler2D corsshair_texture;

void main() {
    color = texture(corsshair_texture, tex_coord)
}