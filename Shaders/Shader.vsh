//
//  Shader.vsh
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-04-24.
//  Copyright Spotify 2010. All rights reserved.
//

attribute vec4 position; // vertex pos
attribute vec4 color;

varying vec4 colorVarying;

uniform mat4 mvp; // model-view-projection

void main()
{
		gl_Position = position * mvp;

    colorVarying = color;
}
