//
//  Heightmap.m
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-05-15.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "Heightmap.h"
#import "CATransform3DAdditions.h"
#import "UIImage+getPixels.h"

static inline float frand() {
	return (rand()%10000)/10000.;
}


@implementation Heightmap
-(id)initWithImage:(UIImage*)image resolution:(float)r depth:(float)depth texture:(Texture2D*)texture;
{
	if(![super init]) return nil;

	w = image.size.width;
	h = image.size.height;
	pc = w*h;
  vc = (w-1)*(h-1)*6;
  res = r;
  d = depth;
  
  tex = [texture retain];
  
  srand(time(NULL));
	
	verts = calloc(pc, sizeof(Vec3));
	colors = calloc(pc, sizeof(Color));
	texcoords = calloc(pc, sizeof(Texcoord));
	normals = calloc(pc, sizeof(Vec3));
  indices = calloc(vc, sizeof(GLushort));
  
  
  unsigned char *pixels = calloc(pc, sizeof(char));
  [image bc_getPixels:pixels];
  
  // Setup verts, colors and tex
	for(int y = 0; y < h; y++) {
		for(int x = 0; x < w; x++) {
    	GLfloat depth = (pixels[(y*w+x)]/255.)*d;
    	verts[y*w+x] = (Vec3){x*r, y*r, depth};
      normals[y*w+x] = (Vec3){0,0,1};
      if(!texture)
	      colors[y*w+x] = (Color){frand()*2., frand()*2., frand()*0.2, 0.8};
      else
      	colors[y*w+x] = (Color){1,1,1,1};
      texcoords[y*w+x] = (Texcoord){x/(float)w, y/(float)h};
    }
  }
  free(pixels);
  
  // Setup normals
 	for(int y = 0; y < h; y++) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
		for(int x = 0; x < w; x++) {
    	Vector3 *me = Vec3Wrap(verts[y*w+x]);
    	Vector3 *au = Vec3Wrap(verts[MAX(y-1, 0)*w+x]);
      Vector3 *ar = Vec3Wrap(verts[y*w+MIN(x,w)]);
      Vector3 *ad = Vec3Wrap(verts[MIN(y+1, h)*w+x]);
      Vector3 *al = Vec3Wrap(verts[y*w-MAX(x-1, 0)]);
      
      Vector3 *lu = [me vectorBySubtractingVector:au];
      Vector3 *lr = [me vectorBySubtractingVector:ar];
      Vector3 *ld = [me vectorBySubtractingVector:ad];
      Vector3 *ll = [me vectorBySubtractingVector:al];
      
      Vector3 *n1 = [lu crossProduct:ll];
      Vector3 *n2 = [ll crossProduct:ld];
      Vector3 *n3 = [ld crossProduct:lr];
      Vector3 *n4 = [lr crossProduct:lu];
      
      MutableVector3 *n = [[n1 mutableCopy] autorelease];
      [n addVector:n2];
      [n addVector:n3];
      [n addVector:n4];
      [n normalize];
      
      
      normals[y*w+x] = n.vec3;
		}
  	[pool release];
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
  // Update attribute values
  NSInteger vertex    = [options.shaderProgram attributeNamed:@"position"];
  NSInteger color     = [options.shaderProgram attributeNamed:@"color"];
  NSInteger texcoord  = [options.shaderProgram attributeNamed:@"texCoord"];
  NSInteger normal    = [options.shaderProgram attributeNamed:@"normal"];
  NSInteger index     = normal+1;
  
  glVertexAttribPointer(vertex, 3, GL_FLOAT, 0, 0, verts);
  glEnableVertexAttribArray(vertex);
  glVertexAttribPointer(color, 4, GL_FLOAT, 1, 0, colors);
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

  [tex apply];
  
  glDrawElements(GL_TRIANGLES, vc, GL_UNSIGNED_SHORT, indices);

	glDisableVertexAttribArray(vertex);
  glDisableVertexAttribArray(color);
  glDisableVertexAttribArray(texcoord);
  glDisableVertexAttribArray(normal);
  glDisableVertexAttribArray(index);
  
  // Normal lines
  return;
  
  Vec3 normallines[pc*2];
  int c = 0;
	for(int y = 0; y < h; y++) {
		for(int x = 0; x < w; x++) {
			memcpy(&normallines[c++], &verts[y*w+x], sizeof(Vec3));
      normallines[c++] = (Vec3){
      	verts[y*w+x].x + normals[y*w+x].x*0.1,
        verts[y*w+x].y + normals[y*w+x].y*0.1,
        verts[y*w+x].z + normals[y*w+x].z*0.1
      };
    }
  }
  glVertexAttribPointer(vertex, 3, GL_FLOAT, 0, 0, normallines);
  glEnableVertexAttribArray(vertex);
  
  glDrawArrays(GL_LINES, 0, c);
}

-(CGSize)sizeInUnits;
{
	return CGSizeMake(w*res, h*res);
}
@end
