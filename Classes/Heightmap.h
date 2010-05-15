//
//  Heightmap.h
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-05-15.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import "RenderOptions.h"

typedef struct {
	GLfloat x, y, z;
} Vertex;
typedef struct {
	GLfloat r, g, b, a;
} Color;
typedef struct {
	GLfloat u, v;
} Texcoord;

@interface Heightmap : NSObject {
	Vertex *verts, *normals;
  Color *colors;
  Texcoord *texcoords;
  GLushort *indices;
  int w, h, pc, vc;
}
-(id)initWithImage:(UIImage*)image resolution:(float)r;
-(void)renderWithOptions:(RenderOptions *)options;
@end
