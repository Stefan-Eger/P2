#version 330 core
layout(origin_upper_left) in vec4 gl_FragCoord;
uniform vec2 u_resolution;

in vec3 vertCol;
out vec4 fragCol;


void main(){
    //fragCol =  vec4(vertCol, 1.0f);
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv.y = 1.0f - uv.y; // flipping y so center is bottom left

    uv = uv - 0.5f;

    fragCol = vec4(uv.x, uv.y, 0.0f, 1.0f);
}