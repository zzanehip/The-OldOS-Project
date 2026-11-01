precision mediump float;

uniform sampler2D s_tex;
varying vec2 v_texCoord;
varying vec3 v_normal;

void main()
{
    vec4 color = texture2D(s_tex, v_texCoord);
    vec3 n = normalize(v_normal);
    gl_FragColor = vec4(color.rgb*n.z, color.a);
}
