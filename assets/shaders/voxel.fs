#version 410

out vec4 fragment_color;

uniform sampler2DArray texture_sampler;

in vec3 tex_coord_pass;
in float shading_value_pass;

void main() {
    vec4 tcolor = texture(texture_sampler, tex_coord_pass);
    fragment_color = tcolor * shading_value_pass;
    if(tcolor.a == 0.0) {
        discard;
    }
}