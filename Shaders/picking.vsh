
attribute vec4 position; // vertex pos
attribute vec4 color;
attribute vec4 texCoord;
attribute vec3 normal;


varying vec4 v_color;
varying vec2 v_texCoord;
varying float v_Dot;

uniform mat4 mvp; // model-view-projection
uniform mat4 normalMatrix;
uniform vec3 lightDir;

void main()
{
	v_color = color;
	
	gl_Position = mvp * position;
	v_texCoord = texCoord.st;

	vec4 transNormal = normalMatrix * vec4(normal, 1);
	v_Dot = max(dot(transNormal.xyz, lightDir), 0.0);
}
