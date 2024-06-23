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
const float EPSILON = 0.001;

// Fractal
const float ka=0.2f, kd=0.7f, ks = 0.5f, shininess = 200;
const vec3 surfaceColor = vec3(1.0f, 1.0f, 1.0f);
//SUN Parameters
const vec3 lightSunDir = normalize(vec3(1.0f, -1.0f, -0.5f));
const vec3 lightSunColor = vec3(1.0f, 1.0f, 1.0f);
const float lightSunIntensity = 1.0f;

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

float dE_Sphere_Box(vec3 pos){
    //vec3 spherePos = vec3(1.0f, 1.0f, 0.0f);
    vec3 s1Pos = vec3(sin(u_time) * 1.5f, sin(u_time)*1.5f, -4.0f);
    float s1 = sdSphere(pos - s1Pos, 1.0f);


    vec3 s2Pos = vec3(0.0f, 0.0f, -4.0f);
    float s2 = sdBox(pos - s2Pos, vec3(0.75f));
    //float s2 = sdSphere(pos - s2Pos, 1.0f);

    float ret = smin (s1, s2, 1.0f);


    return ret;
}



float dE_Spheres_Infinity(vec3 pos){

    float ret = 0.0;
    float radius = 0.3;

    pos.xz = mod((pos.xz), 1.0) - vec2(0.5); // instance on xy-plane

    ret = length(pos)-radius;                  // sphere DE
    return ret;
}

float dE_Mandelbulp(vec3 pos){
    vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;

    int Iterations = 2000;
    float Bailout = 20.0;
    int Power = 8;

	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;

		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;

		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;

		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), -cos(theta));
		z+=pos;
	}
	return 0.5*log(r)*r/dr;
}


float distanceEstimator(vec3 pos){
    //return dE_Sphere_Box(pos);
    return dE_Mandelbulp(pos);
}

// https://en.wikipedia.org/wiki/Numerical_differentiation
// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-ii-lighting-and-coloring/
// using finite difference to determine into which direction the surface normal is pointing.
// one Direction delivers either a minus or plus direction depending on the DE (moving closer or further away), thus
// using this value for each direction will yield the surface normal.
vec3 surfaceNormal(vec3 pos){
    float xDir = distanceEstimator(pos + vec3(EPSILON, 0, 0)) - distanceEstimator(pos - vec3(EPSILON, 0, 0));
    float yDir = distanceEstimator(pos + vec3(0, EPSILON, 0)) - distanceEstimator(pos - vec3(0, EPSILON, 0));
    float zDir = distanceEstimator(pos + vec3(0, 0, EPSILON)) - distanceEstimator(pos - vec3(0, 0, EPSILON));
    /*
    float dist = distanceEstimator(pos);
    float xDir = dist - distanceEstimator(pos - vec3(EPSILON, 0, 0));
    float yDir = dist - distanceEstimator(pos - vec3(0, EPSILON, 0));
    float zDir = dist - distanceEstimator(pos - vec3(0, 0, EPSILON));
    */
    vec3 n = normalize(vec3(xDir, yDir, zDir));

    return n;
}
vec3 blinnPhong(vec3 p, vec3 n){
    n = normalize(n);
    vec3 l = normalize(lightSunDir);
    vec3 L = lightSunIntensity * lightSunColor;

    float lambertian = max(dot(-l, n), 0.0); // -l because of sun
    float specular = 0.0;

    if (lambertian > 0.0) {

        vec3 v = normalize(-p); //view direction
        vec3 h = normalize(-l + v); // half dir
        float specAngle = max(dot(n, h), 0.0);
        specular = pow(specAngle, shininess);
    }
    vec3 I = ka * L * surfaceColor + surfaceColor * kd * L * lambertian +  ks * L * specular;
    return I;
}
vec3 phong(vec3 p, vec3 n){
    n = normalize(n);
    vec3 l = normalize(lightSunDir);
    vec3 L = lightSunIntensity * lightSunColor;

    float lambertian = max(dot(-l, n), 0.0); // -l because of sun
    float specular = 0.0;

    if (lambertian > 0.0) {

        vec3 v = normalize(-p); //view direction
        vec3 r = reflect(l, n); //perfect reflection vector
        float specAngle = max(dot(r, v), 0.0);
        specular = pow(specAngle, shininess/4.0);
    }
    vec3 I = ka * L * surfaceColor + surfaceColor * kd * L * lambertian +  ks * L * specular;
    return I;
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

    bool wasHit = false;
    vec3 color = vec3(0.0f, 0.0f, 0.0f);
    vec3 hitPos = vec3(0.0f, 0.0f, 0.0f);
    vec3 n = vec3(0.0f, 0.0f, 0.0f); // surface normal
    float t = 0.0f; //total distance

    // raymarching
    for(int i = 0; i < MAX_MARCHING_STEPS; i++) {
        // position on the ray
        vec3 p = rayWorldOrigin + rayWorldDir * t;

        //distance estimation to the scene
        float d = distanceEstimator(p);

        // marching further along the ray
        t += d;

        //Glow
        color = min(vec3(i) / float(MAX_MARCHING_STEPS), 0.3) ;

        // too close to object
        if (d < RAY_DISTANCE_TOLERANCE){
            n = surfaceNormal(p);
            hitPos = p;
            wasHit = true;
            break;
        }
        if(t > RAY_TOTAL_DISTANCE_LIMIT) break; // too far from object
    }
    //color = vec3(1 - 0.1f * t);
    if(wasHit) {
        color = phong(hitPos, n);
        //color = blinnPhong(hitPos, n);
    }

    fragCol = vec4(color, 1.0f);
    //fragCol = vec4(n, 1.0f);
}