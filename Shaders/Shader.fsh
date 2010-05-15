
//uniform sampler2D sampler2d;

varying lowp vec4 v_color;
varying lowp float v_Dot;
varying lowp vec2 v_texCoord;

void main()
{
	//lowp vec2 texCoord = vec2(v_texCoord.s, 1.0 - v_texCoord.t);
	//vec4 color = texture2D(sampler2d, texCoord);
	//color += vec4(0.1, 0.1, 0.1, 1);
	lowp vec4 color = vec4(1,1,0,1);
	gl_FragColor = color; //v_color * vec4(color.xyz * v_Dot, color.a);
}
