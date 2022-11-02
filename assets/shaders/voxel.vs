#version 410

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 tex_coord;
layout(location = 2) in float shading_value;

out vec3 tex_coord_pass;
out float shading_value_pass;

uniform mat4 mvp;

void main() {
    gl_Position = mvp * vec4(position, 1.0);
    shading_value_pass = shading_value;
    tex_coord_pass = tex_coord * vec3(1.0, -1.0, 1.0);
}