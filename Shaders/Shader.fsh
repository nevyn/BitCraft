
uniform sampler2D sampler2d;

varying lowp vec4 v_color;
varying lowp float v_Dot;
varying lowp vec2 v_texCoord;

void main()
{
	lowp vec4 color = texture2D(sampler2d, v_texCoord);
	//lowp vec4 color2 = vec4(1, 0, 1, 1);
	gl_FragColor = color; // * vec4(color.xyz * v_Dot, color.a);
}
