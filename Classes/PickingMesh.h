//
//  PickingMesh.h
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QuadMesh.h"

@interface PickingMesh : QuadMesh {
  GLuint index;
}

@property (nonatomic, assign) GLuint index;

@end
