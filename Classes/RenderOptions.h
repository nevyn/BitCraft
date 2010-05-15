//
//  RenderOptions.h
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "Matrix.h"
#import "ShaderProgram.h"


@interface RenderOptions : NSObject {
  CATransform3D modelViewMatrix;
  CATransform3D viewMatrix;
  CATransform3D projectionMatrix;
  
  ShaderProgram *shaderProgram;
}

@property (nonatomic, assign) CATransform3D modelViewMatrix;
@property (nonatomic, assign) CATransform3D viewMatrix;
@property (nonatomic, assign) CATransform3D projectionMatrix;
@property (nonatomic, readonly) CATransform3D modelViewProjectionMatrix;

@property (nonatomic, retain) ShaderProgram *shaderProgram;

@end
