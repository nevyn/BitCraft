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
#import "Vector3.h"
#import "Texture2D.h"

typedef struct {
	GLfloat r, g, b, a;
} Color;
typedef struct {
	GLfloat u, v;
} Texcoord;

@interface Heightmap : NSObject <IRenderable>{
	Vec3 *verts, *normals;
  Color *colors;
  Texcoord *texcoords;
  GLushort *indices;
  int w, h, pc, vc;
  float res, d;
  Texture2D* tex;
}
-(id)initWithImage:(UIImage*)image resolution:(float)r depth:(float)depth texture:(Texture2D*)texture;

-(CGSize)sizeInUnits;
@end
