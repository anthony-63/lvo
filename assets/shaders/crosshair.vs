#version 410

layout(location = 3) in vec3 position;
layout(location = 4) in vec3 tex_coord;

out vec3 tex_coord_pass;

void main() {
    gl_Position = vec4(position, 1.0);
    tex_coord_pass = tex_coord;
}