#version 410

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 tex_coord;

out vec3 position_pass;
out vec3 tex_coord_pass;

uniform mat4 mvp;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    position_pass = position;
    tex_coord_pass = tex_coord * vec3(1.0, -1.0, 1.0);
}