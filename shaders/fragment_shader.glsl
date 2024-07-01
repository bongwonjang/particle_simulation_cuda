#version 450 core

in vec4 vertexPos;

out vec4 FragColor;

uniform float time;

void main() 
{
    vec2 p = gl_PointCoord * 2.0 - vec2(1.0);
    float r = sqrt(dot(p,p));
    float theta = atan(p.y,p.x);

    if(dot(p,p) > 0.5 * (exp(cos(theta * 5 + time * 3) * 0.75)))
        discard;
    else
    {
        float colorA = sin(time * 0.5) * 0.5 + 1;
        float colorB = cos(time * 0.5) * 0.5 + 1;
        float colorC = cos(time * 0.25) * 0.3 + 1;
        FragColor = vec4(colorA, colorB, colorC, 1.0);
    }
}

// // in vec4 vertexPos;
// out vec4 FragColor;
// // uniform float time;

// void main()
// {
//     FragColor = vec4(1.0, 1.0f, 0.0f, 1.0);

//     // vec2 p = gl_PointCoord* 2.0 - vec2(1.0);
//     // float r = sqrt(dot(p,p));
//     // float theta = atan(p.y,p.x);

//     // if(dot(p,p) > 0.5 * (exp(cos(theta * 5 + time * 10) *0.75)))
//     //     discard;
//     // else
//     // {
//     //     float red = sin(time * 2) * 0.5 + vertexPos.x;
//     //     float green = cos(time * 2) * 0.5 + vertexPos.y;
//     //     FragColor = vec4(1.0, red, green, 1.0);
//     // }
// }