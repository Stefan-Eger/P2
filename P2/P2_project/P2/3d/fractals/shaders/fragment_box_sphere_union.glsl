#version 330 core
layout(origin_upper_left) in vec4 gl_FragCoord;
uniform vec2 u_resolution;
uniform vec2 u_inv_resolution;
uniform float u_aspect_ratio;
uniform float u_hfov;
uniform mat4 u_cam_to_world;


uniform float u_time;

in vec3 vertCol;
out vec4 fragCol;

const float RAY_DISTANCE_TOLERANCE = 0.001f;
const float RAY_TOTAL_DISTANCE_LIMIT = 100.0f;
const int MAX_MARCHING_STEPS = 80;

// https://www.youtube.com/watch?v=khblXafu7iA
// https://iquilezles.org/articles/distfunctions/
float sdSphere(vec3 p, float s){
    return (length(p) - s);
}
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}


float smin( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float map(vec3 pos){
    //vec3 spherePos = vec3(1.0f, 1.0f, 0.0f);
    vec3 s1Pos = vec3(sin(u_time) * 1.5f, sin(u_time)*1.5f, -4.0f);
    float s1 = sdSphere(pos - s1Pos, 1.0f);


    vec3 s2Pos = vec3(0.0f, 0.0f, -4.0f);
    float s2 = sdBox(pos - s2Pos, vec3(0.75f));
    //float s2 = sdSphere(pos - s2Pos, 1.0f);

    float ret = smin (s1, s2, 1.0f);


    return ret;
}

float distanceEstimator(vec3 pos){
    float ret = 0.0;

    return ret;
}

void main(){
    // gl_FragCoord are essentially pixel coordinates
    // https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html


    vec2 p;
    p.x = (((gl_FragCoord.x + 0.5) * u_inv_resolution.x) * 2 - 1) * u_aspect_ratio * u_hfov;
    p.y = (1 - 2 * ((gl_FragCoord.y + 0.5) * u_inv_resolution.y)) * u_hfov;


    //Init Raymarching
    vec4 rayOrigin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 rayP = vec4(p.x, p.y, - 1.0, 1.0); // RHS looking to -z

    vec3 rayWorldOrigin = (u_cam_to_world * rayOrigin).xyz;
    vec3 rayWorldDir = normalize(((u_cam_to_world * rayP).xyz - rayWorldOrigin));

    vec3 color = vec3(0.0f, 0.0f, 0.0f);
    float t = 0.0f; //total distance

    // raymarching
    for(int i = 0; i < MAX_MARCHING_STEPS; i++){
        // position on the ray
        vec3 p = rayWorldOrigin + rayWorldDir*t;
        //distance estimation to the scene
        float d = map(p);
        // marching further along the ray
        t += d;

        color = vec3(i) / float(MAX_MARCHING_STEPS);

        if(d < RAY_DISTANCE_TOLERANCE) break; // too close to object
        if(t > RAY_TOTAL_DISTANCE_LIMIT) break; // too far from object
    }
    color = vec3(1 - 0.1f * t);


    fragCol = vec4(p, 0.0f, 1.0f);
    fragCol = vec4(rayWorldDir.x, rayWorldDir.y, rayWorldDir.z, 1.0f);
    fragCol = vec4(color, 1.0f);
}