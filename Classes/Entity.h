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


@interface Entity : NSObject <IRenderable>{
  CATransform3D matrix;
  ShaderProgram *shader;
  
  NSObject<IRenderable> *mesh;
  
  BOOL pickable;
}
-(id)initWithRenderable:(NSObject<IRenderable> *)renderable;
@property (nonatomic, assign) Vector4 *position;
@property (nonatomic, assign) BOOL pickable;
@property (nonatomic, retain) ShaderProgram *shader;
@end
