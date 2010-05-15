//
//  Heightmap.m
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-05-15.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "Heightmap.h"
#import "CATransform3DAdditions.h"

static inline float frand() {
	return (rand()%10000)/10000.;
}


@implementation Heightmap
-(id)initWithImage:(UIImage*)image resolution:(float)r;
{
	if(![super init]) return nil;

	w = image.size.width;
	h = image.size.height;
	pc = w*h;
  vc = (w-1)*(h-1)*6;
  res = r;
  
	
	verts = calloc(pc, sizeof(Vertex));
	colors = calloc(pc, sizeof(Color));
	texcoords = calloc(pc, sizeof(Texcoord));
	normals = calloc(pc, sizeof(Vertex));
  indices = calloc(vc, sizeof(GLushort));
  
  // Setup data
	for(int y = 0; y < h; y++) {
		for(int x = 0; x < w; x++) {
    	GLfloat d = frand()*0.05;
    	verts[y*w+x] = (Vertex){x*r, y*r, d};
      normals[y*w+x] = (Vertex){0,1,0};
      colors[y*w+x] = (Color){1-d, 1-d, 1-d, 1};
      texcoords[y*w+x] = (Texcoord){x/(float)w, y/(float)h};
    }
  }

	
  // Setup indices
  int c = 0;
  for(int y = 0; y < h-1; y++) {
  	for(int x = 0; x < w-1; x++) {
    	indices[c++] = y*w+x;
    	indices[c++] = y*w+x+1;
    	indices[c++] = (y+1)*w+x;
      
      indices[c++] = y*w+x+1;
      indices[c++] = (y+1)*w+x+1;
      indices[c++] = (y+1)*w+x;
    }
	}
	
	return self;
}
-(void)dealloc;
{
	free(verts);
	free(colors);
	free(texcoords);
	free(normals);
	[super dealloc];
}

-(void)renderWithOptions:(RenderOptions *)options;
{
  CATransform3D mvp = options.modelViewProjectionMatrix;
  glUniformMatrix4fv([options.shaderProgram uniformNamed:@"mvp"], 1, GL_FALSE, (float*)&mvp);
  
  CATransform3D normalMatrix = options.modelViewMatrix;
  normalMatrix = CATransform3DInvert(normalMatrix);
  normalMatrix = CATransform3DTranspose(normalMatrix);
  glUniformMatrix4fv([options.shaderProgram uniformNamed:@"normalMatrix"], 1, GL_FALSE, (float*)&normalMatrix);

  // Update attribute values
  NSInteger vertex    = [options.shaderProgram attributeNamed:@"position"];
  NSInteger color     = [options.shaderProgram attributeNamed:@"color"];
  NSInteger texcoord  = [options.shaderProgram attributeNamed:@"texCoord"];
  NSInteger normal    = [options.shaderProgram attributeNamed:@"normal"];
  NSInteger index     = normal+1;
  
  glVertexAttribPointer(vertex, 3, GL_FLOAT, 0, 0, verts);
  glEnableVertexAttribArray(vertex);
  glVertexAttribPointer(color, 4, GL_UNSIGNED_BYTE, 1, 0, colors);
  glEnableVertexAttribArray(color);
  glVertexAttribPointer(texcoord, 2, GL_FLOAT, 0, 0, texcoords);
  glEnableVertexAttribArray(texcoord);
  glVertexAttribPointer(normal, 3, GL_FLOAT, 0, 0, normals);
  glEnableVertexAttribArray(normal);
  
  glVertexAttribPointer(index, 1, GL_UNSIGNED_SHORT, 0, 0, indices);
  glEnableVertexAttribArray(index);
  
#if defined(DEBUG)
  if (![options.shaderProgram validate])
  {
    NSLog(@"Failed to validate program");
    return;
  }
#endif
  
  
  glDrawElements(GL_TRIANGLES, vc, GL_UNSIGNED_SHORT, indices);

}

-(CGSize)sizeInUnits;
{
	return CGSizeMake(w*res, h*res);
}
@end
