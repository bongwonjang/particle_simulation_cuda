#version 450 core

layout(location = 0) in vec3 aPos;

out vec4 vertexPos;

uniform int simulation_box_width;
uniform int simulation_box_height;

void main()
{
    gl_PointSize = 10.0f;
    float width_resolution_correction = aPos.x / simulation_box_width * 2;
    float height_resolution_correction = aPos.y / simulation_box_height * 2;
    
    gl_Position = vec4(width_resolution_correction, height_resolution_correction, 0.0f, 1.0);
    vertexPos = gl_Position;
}