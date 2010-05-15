//
//  Entity.m
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Entity.h"
#import "CATransform3DAdditions.h"

@implementation Entity


-(id)init
{
  if(![super init]) return nil;
  
  matrix = CATransform3DIdentity;
  
  mesh = [[QuadMesh alloc] init];

  return self;
}

-(void)dealloc
{
  [super dealloc];
}

-(Vector4*)position
{
  return [Vector4 vectorWithX:matrix.m41 y:matrix.m42 z:matrix.m43 w:matrix.m44];
}

-(void)setPosition:(Vector4 *)p
{
  matrix.m41 = p.x;
  matrix.m42 = p.y;
  matrix.m43 = p.z;
  matrix.m44 = p.w;
}

-(void)renderWithOptions:(RenderOptions *)options;
{
  options.modelViewMatrix = matrix;
  
  CATransform3D normal = matrix;
  normal = CATransform3DInvert(normal);
  normal = CATransform3DTranspose(normal);
  glUniformMatrix4fv([options.shaderProgram uniformNamed:@"normalMatrix"], 1, GL_FALSE, (float*)&normal);
  
  CATransform3D mvp = options.modelViewProjectionMatrix;
  glUniformMatrix4fv([options.shaderProgram uniformNamed:@"mvp"], 1, GL_FALSE, (float*)&mvp);
  
  [mesh renderWithOptions:options];
}

@end
