
attribute vec4 position; // vertex pos
attribute vec4 color;
attribute vec4 texCoord;
attribute vec3 normal;


varying vec4 v_color;
varying float v_Dot;

uniform mat4 mvp; // model-view-projection
uniform mat4 normalMatrix;
uniform vec3 lightDir;
uniform highp float time;

void main()
{
	lowp float gphase = color.r;
  lowp float bphase = color.g;
  lowp float intensity = color.b;
  v_color = vec4(
  	0,
    0.4+sin(time*gphase+bphase)*intensity,
    0.4+sin(time)*0.1,
    color.a
  );
	
	gl_Position = mvp * position;

	vec4 transNormal = normalMatrix * vec4(normal, 1);
	v_Dot = max(dot(transNormal.xyz, lightDir), 0.0);
}
