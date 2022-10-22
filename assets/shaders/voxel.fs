#version 410

out vec4 fragment_color;

uniform sampler2DArray texture_sampler;

in vec3 position_pass;
in vec3 tex_coord_pass;
in float shading_value_pass;

void main() {
    fragment_color = texture(texture_sampler, tex_coord_pass) * shading_value_pass;
}