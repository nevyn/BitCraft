//
//  ShaderVeriable.h
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@interface ShaderVariable : NSObject {
  GLuint location;
  GLuint program;
  NSString *name;
}

@property (readonly, nonatomic) GLuint location;

-(id)initWithName:(NSString *)name inProgram:(GLuint)program;
-(void)bind;

@end
