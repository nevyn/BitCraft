//
//  RenderOptions.m
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RenderOptions.h"


@implementation RenderOptions

@synthesize modelViewMatrix, viewMatrix, projectionMatrix, shaderProgram;

-(CATransform3D)modelViewProjectionMatrix
{
  CATransform3D mvp = CATransform3DIdentity;
  mvp = CATransform3DConcat(mvp, modelViewMatrix);
  mvp = CATransform3DConcat(mvp, viewMatrix);
  mvp = CATransform3DConcat(mvp, projectionMatrix);
  return mvp;
}

@end
