
uniform sampler2D sampler2d;


varying lowp vec4 v_color;
varying lowp float v_Dot;

void main()
{
	gl_FragColor = vec4(v_color.rgb * v_Dot, v_color.a);
}
