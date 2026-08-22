precision mediump float;

varying vec2 v_position;

uniform vec2 u_cylinderPosition;
uniform vec2 u_cylinderDirection;
uniform float u_cylinderRadius;

#define M_PI 3.14159265358979323846264338327950288

void main()
{
    vec2 dir = vec2(u_cylinderDirection.y, -u_cylinderDirection.x);
    vec2 v = v_position - u_cylinderPosition;
    float d = dot(v, dir);
    float l = 0.6 - 0.6*smoothstep(0.5, 0.8, d/(2.0*u_cylinderRadius));
    gl_FragColor = vec4(0.0, 0.0, 0.0, l);
}
