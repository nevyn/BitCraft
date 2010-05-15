//
//  Shader.h
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@interface Shader : NSObject {
  GLuint uid;
  GLenum type;
  
  NSString *filename;

}

-(id)initVertexShaderFromFile:(NSString *)filename_;
-(id)initFragmentShaderFromFile:(NSString *)filename_;

-(id)initWithShaderType:(GLenum)type_ fromFile:(NSString *)filename_;
-(BOOL)compile;

-(void)attachToProgram:(GLuint)program;




@end
