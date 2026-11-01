
uniform mat4 u_mvpMatrix;

attribute vec4 a_position;
attribute vec2 a_texCoord;

uniform vec2 u_cylinderPosition;
uniform vec2 u_cylinderDirection;
uniform float u_cylinderRadius;

varying vec2 v_texCoord;
varying vec3 v_normal;

#define M_PI 3.14159265358979323846264338327950288

void main()
{
    vec2 n = vec2(u_cylinderDirection.y, -u_cylinderDirection.x);
    vec2 w = a_position.xy - u_cylinderPosition;
    float d = dot(w, n);
    
    vec2 dv = n * (2.0*d - M_PI*u_cylinderRadius);
    float dr = d/u_cylinderRadius;//projection angle
    float s = sin(dr);
    float c = cos(dr);
    vec2 proj = a_position.xy - n*d;//projection of vertex on the cylinder axis projected on the xy plane
    vec3 center = vec3(proj, u_cylinderRadius);
    
    float br1 = clamp(sign(d), 0.0, 1.0); // d > 0.0
    float br2 = clamp(sign(d - M_PI*u_cylinderRadius), 0.0, 1.0); // d > M_PI*u_cylinderRadius
    
    vec3 vProj = vec3(s*n.x, s*n.y, 1.0 - c)*u_cylinderRadius;
    vProj.xy += proj;
    vec4 v = mix(a_position, vec4(vProj, a_position.w), br1);
    v = mix(v, vec4(a_position.x - dv.x, a_position.y - dv.y, 2.0*u_cylinderRadius, a_position.w), br2);
    
    v_normal = mix(vec3(0.0, 0.0, 1.0), (center - v.xyz)/u_cylinderRadius, br1);
    v_normal = mix(v_normal, vec3(0.0, 0.0, -1.0), br2);

    gl_Position = u_mvpMatrix * v;
    v_texCoord = a_texCoord;
}
