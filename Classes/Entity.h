//
//  Entity.h
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "Vector4.h"
#import "Matrix.h"
#import "RenderOptions.h"
#import "ShaderProgram.h"
#import "QuadMesh.h"

@interface Entity : NSObject {
  CATransform3D matrix;
  
  QuadMesh *mesh;
  
  BOOL pickable;
}

@property (nonatomic, assign) Vector4 *position;
@property (nonatomic, assign) BOOL pickable;

-(void)renderWithOptions:(RenderOptions *)options;

@end
