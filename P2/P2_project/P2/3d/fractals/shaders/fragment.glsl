#version 330 core
layout(origin_upper_left) in vec4 gl_FragCoord;
uniform vec2 u_resolution;
uniform vec2 u_inv_resolution;
uniform float u_aspect_ratio;
uniform float u_hfov;
uniform mat4 u_cam_to_world;

uniform float u_cam_bpm;

// #define CUT

uniform float u_time;

in vec3 vertCol;
out vec4 fragCol;

#define PI 3.1415926538

const float RAY_DISTANCE_TOLERANCE = 0.001f;
const float RAY_TOTAL_DISTANCE_LIMIT = 100.0f;
const int MAX_MARCHING_STEPS = 80;
const float EPSILON = 0.01;

//Glow effect
const vec3 GLOW_COLOR = vec3(0.0f, 1.0f, 1.0f);
const float GLOW_CUTOFF = 0.2f;
const float GLOW_NOISE = 0.76f; // 1.0f no noise, 0.0 random noise

// Fractal
const float ka=0.3f, kd=0.7f, ks = 0.0f, shininess = 4;
//SUN Parameters
const vec3 lightSunDir = normalize(vec3(1.0f, -1.0f, -0.5f));
const vec3 lightSunColor = vec3(1.0f, 1.0f, 1.0f);
const float lightSunIntensity = 1.0f;


vec3 surfaceColor(vec3 pos, vec3 normal, float fractalIterations){
    vec3 col;

    vec3 l = normalize(lightSunDir);
    vec3 v = normalize(-pos); //view direction
    vec3 r = reflect(l, normal); //perfect reflection vector


    col = 0.5+0.5*cos( log2(fractalIterations) * 0.9 + 1.5 * PI * cos(u_cam_bpm/8.0f)  + vec3(0.8, 1.0, 0.0) );
    //col = 0.5+0.5*cos( log2(fractalIterations) * 0.9 + 1.5 * PI * cos(u_cam_bpm/8.0f)  + vec3(0.0, 0.8, 1.0) );
    //col = 0.5+0.5*cos( log2(fractalIterations) * 0.9 + 1.5 * PI * cos(u_cam_bpm/8.0f)  + vec3(0.0, 1.0, 0.8) );
    //Mandelbox
    if (fractalIterations < 0)
        col = 0.4 + 0.6 * abs(mix(normal, v, abs(cos(0.5f*u_cam_bpm)))) * abs(cos(1.5 * PI * cos(0.5*u_cam_bpm/8.0f)  + vec3( 1.0, 0.0, 0.8))); //0.25 * cos(1.5 * PI * cos(u_time/8.0f)  + normal);
    //col = mix(normal, v, abs(cos(0.5f*u_time)));


    //col = cos( fractalIterations + vec3(0.0, 0.5 , 1.0));

    //if (pos.y >0.0)
        //col = mix(col,vec3(1.0),0.5);

    /*
    float inside = smoothstep(500.0, 600.0, fractalIterations);

    col *= vec3(0.45,0.42,0.40) + vec3(0.55,0.58,0.60)*inside;
    col = mix(col*col*(3.0-2.0*col),col,inside);
    //col = mix( mix(col,vec3(dot(col,vec3(0.3333))),-0.4), col, inside);
    */
    return clamp(col, 0.0, 1.0);
}

vec3 blinnPhong(vec3 p, vec3 n, vec3 surfaceColor){
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

vec3 phong(vec3 p, vec3 n, vec3 surfaceColor){
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
    vec3 I = surfaceColor * kd * L * lambertian +  ks * L * specular;
    return I;
}

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
    float dist = 0.0;
    float radius = 0.3;

    pos.xz = mod((pos.xz), 1.0) - vec2(0.5); // instance on xy-plane

    dist = length(pos)-radius;                  // sphere DE
    return dist;
}


// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-iii-folding-space/
float dE_Sierpinski(vec3 p)
{
	vec3 a1 = vec3(1,1,1);
	vec3 a2 = vec3(-1,-1,1);
	vec3 a3 = vec3(1,-1,-1);
	vec3 a4 = vec3(-1,1,-1);
	vec3 c;
	int n = 0;
	float dist, d;

    int Iterations = 16;
    float Scale = 2.0f;


	while (n < Iterations) {
		 c = a1; dist = length(p-a1);
         d = length(p-a2); if (d < dist) { c = a2; dist=d; }
		 d = length(p-a3); if (d < dist) { c = a3; dist=d; }
		 d = length(p-a4); if (d < dist) { c = a4; dist=d; }
		p = Scale * p - c * (Scale - 1.0);
		n++;
	}
	return length(p) * pow(Scale, float(-n));
}

// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-iii-folding-space/
float dE_Sierpinski_folded(vec3 p){

    int Iterations = 16;
    float Scale = 2.0f;
    float Offset= 0.5f;

    float r;
    int n = 0;
    while (n < Iterations) {
       if((p.x + p.y) < 0) p.xy = -p.yx; // fold 1
       if((p.x + p.z) < 0) p.xz = -p.zx; // fold 2
       if((p.y + p.z) < 0) p.zy = -p.yz; // fold 3
       p = p * Scale - Offset * ( Scale - 1.0);
       n++;
    }
	return length(p) * pow(Scale, float(-n));
}

////////////////////////////////////////////////////////////////////////////////
//http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox
////////////////////////////////////////////////////////////////////////////////


void sphereFold(inout vec3 z, inout float dz) {
    float r = length(z);
	float r2 = dot(z,z);

    float minRadius2 = 2.0f ;//+ cos(u_cam_bpm * 0.05f) * 1.0f;
    float fixedRadius2 = 20.0f+ sin(u_cam_bpm * 0.05f) * 10.0f;

	if (r2<minRadius2) {
		// linear inner scaling
		float temp = (fixedRadius2/minRadius2);
		z *= temp;
		dz*= temp;
	} else if (r2<fixedRadius2) {
		// this is the actual sphere inversion
		float temp =(fixedRadius2/r2);
		z *= temp;
		dz*= temp;
	}
}

void boxFold(inout vec3 z, inout float dz) {
    float foldingLimit = 3.0f;
	z = clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
}

float dE_Mandelbox(vec3 p)
{
    float Scale = 2.0f ;
    int Iterations = 32;


	vec3 offset = p;
	float dr = 1.0;
	for (int n = 0; n < Iterations; n++) {
		boxFold(p, dr);       // Reflect
		sphereFold(p, dr);    // Sphere Inversion

        p= Scale * p + offset;  // Scale & Translate
        dr = dr * abs(Scale)+1.0;
	}
	float r = length(p);
	return r/abs(dr);
}



////////////////////////////////////////////////////////////////////////////////
////////////// https://www.shadertoy.com/view/3tsyzl# //////////////////////////
////////////////////////////////////////////////////////////////////////////////
vec4 qSquare( in vec4 q )
{
    return vec4(q.x*q.x - q.y*q.y - q.z*q.z - q.w*q.w, 2.0*q.x*q.yzw);
}
vec4 qCube( in vec4 q )
{
    vec4  q2 = q*q;
    return vec4(q.x  *(    q2.x - 3.0*q2.y - 3.0*q2.z - 3.0*q2.w),
                q.yzw*(3.0*q2.x -     q2.y -     q2.z -     q2.w));
}
float qLength2( in vec4 q ) { return dot(q,q); }

float dE_Juliaset_Quaternion(vec3 pos, out int fractalIterations )
{
    fractalIterations = 0;

    vec4 z = vec4( pos, 0.0 );
    float dz2 = 1.0;
	float m2  = 0.0;
    float o   = 1e10;


    const int   kNumIte = 200;
    const vec4  kC = vec4(-2,6,15,-6)/22.0;



    for( int i=0; i<kNumIte; i++ )
	{
        // z' = 3z² -> |z'|² = 9|z²|²
		dz2 *= 9.0*qLength2(qSquare(z));

        // z = z³ + c
		z = qCube( z ) + kC;

        // stop under divergence
        m2 = qLength2(z);

        // orbit trapping : https://iquilezles.org/articles/orbittraps3d
        o = min( o, length(z.xz-vec2(0.45,0.55))-0.1 );

        // exit condition
        if( m2>256.0 ) break;
		fractalIterations += 1;
	}

	// sdf(z) = log|z|·|z|/|dz| : https://iquilezles.org/articles/distancefractals
	float d = 0.25*log(m2)*sqrt(m2/dz2);


    d = min(o,d);
    d = max(d, pos.y);

	return d;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
float dE_Mandelbulb(vec3 pos, out int fractalIterations){
    float dist = 0;

    vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;

    int Iterations = 100;
    float Bailout = 1.4;
    int Power = 8;

	for (fractalIterations = 0; fractalIterations < Iterations ; fractalIterations++) {
		r = length(z);
		if (r>Bailout) break;

		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;

		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;

		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), -cos(theta));
		z+=pos;
	}
    dist = 0.5*log(r)*r/dr;

	return dist;
}

float distanceEstimator(vec3 pos, out int fractalIterations){
    fractalIterations = -1;

    float ret;
    //ret = dE_Sphere_Box(pos);
    //ret = dE_Spheres_Infinity(pos);
    //ret = dE_Sierpinski(pos);
    //ret = dE_Sierpinski_folded(pos);

    ret = dE_Mandelbulb(pos, fractalIterations);
    //ret = dE_Juliaset_Quaternion(pos, fractalIterations);
    //ret = dE_Mandelbox(pos);


    return ret;
}

// https://en.wikipedia.org/wiki/Numerical_differentiation
// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-ii-lighting-and-coloring/
// using finite difference to determine into which direction the surface normal is pointing.
// one Direction delivers either a minus or plus direction depending on the DE (moving closer or further away), thus
// using this value for each direction will yield the surface normal.
vec3 surfaceNormal(vec3 pos){
    int fracIter;
    float xDir = distanceEstimator(pos + vec3(EPSILON, 0, 0), fracIter) - distanceEstimator(pos - vec3(EPSILON, 0, 0), fracIter);
    float yDir = distanceEstimator(pos + vec3(0, EPSILON, 0), fracIter) - distanceEstimator(pos - vec3(0, EPSILON, 0), fracIter);
    float zDir = distanceEstimator(pos + vec3(0, 0, EPSILON), fracIter) - distanceEstimator(pos - vec3(0, 0, EPSILON), fracIter);
    /*
    float dist = distanceEstimator(pos);
    float xDir = dist - distanceEstimator(pos - vec3(EPSILON, 0, 0));
    float yDir = dist - distanceEstimator(pos - vec3(0, EPSILON, 0));
    float zDir = dist - distanceEstimator(pos - vec3(0, 0, EPSILON));
    */
    vec3 n = normalize(vec3(xDir, yDir, zDir));

    return n;
}

/*
returns:
bool, if something was hit
*/
bool raymarch(vec3 rayWorldOrigin, vec3 rayWorldDir, out vec3 hitPos, out int rayMarchIterations, out float rayMinDistance, out int fractalIterations){

    bool wasHit = false;
    rayMarchIterations = 0;
    rayMinDistance = 10e20;

    float t = 0.0f; //total distance
    // raymarching algorithm
    for(rayMarchIterations = 0; rayMarchIterations < MAX_MARCHING_STEPS; rayMarchIterations++) {
        // position on the ray
        vec3 p = rayWorldOrigin + rayWorldDir * t;

        //distance estimation to the scene
        float d = distanceEstimator(p, fractalIterations);

        // marching further along the ray
        t += d;
        rayMinDistance = d < rayMinDistance ? d : rayMinDistance;

        // too close to object
        if (d < RAY_DISTANCE_TOLERANCE){
            hitPos = p;
            wasHit = true;
            break;
        }
        if(t > RAY_TOTAL_DISTANCE_LIMIT) break; // too far from object
    }

    return wasHit;

}

// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83?permalink_comment_id=2351862
float rand(float seed){
    return fract(sin(seed) * 43758.5453123);
}

void main(){
    // gl_FragCoord are essentially pixel coordinates
    // https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html


    vec2 p;
    p.x = (((gl_FragCoord.x + 0.5) * u_inv_resolution.x) * 2 - 1) * u_aspect_ratio * u_hfov;
    p.y = (1 - 2 * ((gl_FragCoord.y + 0.5) * u_inv_resolution.y)) * u_hfov;


    //Raymarching input variables
    vec4 rayOrigin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 rayP = vec4(p.x, p.y, - 1.0, 1.0); // RHS looking to -z

    vec3 rayWorldOrigin = (u_cam_to_world * rayOrigin).xyz;
    vec3 rayWorldDir = normalize(((u_cam_to_world * rayP).xyz - rayWorldOrigin));

    //output variables
    vec3 color = vec3(0.0f, 0.0f, 0.0f);
    vec3 hitPos;
    int rayMarchIterations;
    float rayMinDistance;
    int fractalIterations;

    bool wasHit = raymarch(rayWorldOrigin, rayWorldDir, hitPos, rayMarchIterations, rayMinDistance, fractalIterations );

    // Glow
    float glow = (float(rayMarchIterations) / float(MAX_MARCHING_STEPS));
    if(glow > GLOW_CUTOFF)
        color = (glow-GLOW_CUTOFF) * GLOW_COLOR * max(rand(rayMinDistance), GLOW_NOISE);

    // Surface shading
    if(wasHit) {

        //Ambient Occlussion
        float ao = 1.0f - float(rayMarchIterations) / float(MAX_MARCHING_STEPS);

        vec3 surfaceNormal = surfaceNormal(hitPos);
        vec3 surfaceColor = surfaceColor(hitPos, surfaceNormal, fractalIterations);
        color = phong(hitPos, surfaceNormal, surfaceColor);
        color += ka * surfaceColor * ao;

        //color = vec3(ao);
    }


    fragCol = vec4(color, 1.0f);
}