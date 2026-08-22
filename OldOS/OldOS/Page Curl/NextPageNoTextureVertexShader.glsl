
uniform mat4 u_mvpMatrix;

attribute vec4 a_position;

varying vec2 v_position;

void main()
{
    gl_Position = u_mvpMatrix * a_position;
    v_position = a_position.xy;
}
