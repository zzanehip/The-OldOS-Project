precision mediump float;

uniform sampler2D s_tex;
uniform sampler2D s_gradient;
varying vec2 v_texCoord;
varying vec2 v_gradientTexCoord;

void main()
{
    vec4 color = texture2D(s_tex, v_texCoord);
    vec4 gradient = texture2D(s_gradient, v_gradientTexCoord);
    gl_FragColor = vec4(color.rgb*(1.0 - gradient.a) + gradient.rgb, color.a); // premultiplied alpha
}

//gl_FragColor = vec4((0.975 - gradient.a) + gradient.rgb, color.a); // premultiplied alpha
