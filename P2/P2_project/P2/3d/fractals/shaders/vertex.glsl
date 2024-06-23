#version 330 core

layout (location=0) in vec3 vPos;

out vec3 vertCol;

void main(){
    gl_Position = vec4(vPos, 1.0f);
    vertCol = vec3(1.0f, 0.0f, 0.0f);
}