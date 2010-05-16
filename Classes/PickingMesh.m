//
//  PickingMesh.m
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PickingMesh.h"


@implementation PickingMesh

@synthesize index;

-(void)renderWithOptions:(RenderOptions *)options;
{
  static const GLfloat squareVertices[] = {
		-0.2f, -0.2f, 0., //bl
		0.2f, -0.2f, 0., //br
		-0.2f,  0.2f, 0., //tl
		0.2f,  0.2f, 0. //tr
	};
	
//  const GLuint c = (index<<8) | 0xff;
  const GLuint c = index;
	const GLuint squareColors[] = {
    c, c, c, c
  };
  
	static const GLfloat squareTexcoord[] = {
		0, 1,
		1, 1,
		0, 0,
		1, 0
	};
	
	static const GLfloat squareNormals[] = {
		0, 1, 0,
		0, 1, 0,
		0, 1, 0,
		0, 1, 0
	};
  
  
  // Update attribute values
  NSInteger vertex    = [options.shaderProgram attributeNamed:@"position"];
  NSInteger color     = [options.shaderProgram attributeNamed:@"color"];
  NSInteger texcoord  = [options.shaderProgram attributeNamed:@"texCoord"];
  NSInteger normal    = [options.shaderProgram attributeNamed:@"normal"];
  
  glVertexAttribPointer(vertex, 3, GL_FLOAT, 0, 0, squareVertices);
  glEnableVertexAttribArray(vertex);
  glVertexAttribPointer(color, 4, GL_UNSIGNED_BYTE, 1, 0, (GLubyte*)squareColors);
  glEnableVertexAttribArray(color);
  glVertexAttribPointer(texcoord, 2, GL_FLOAT, 0, 0, squareTexcoord);
  glEnableVertexAttribArray(texcoord);
  glVertexAttribPointer(normal, 3, GL_FLOAT, 0, 0, squareNormals);
  glEnableVertexAttribArray(normal);
  
#if defined(DEBUG)
  ;
  if (![options.shaderProgram validate])
  {
    NSLog(@"Failed to validate program");
    return;
  }
#endif
  
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end
