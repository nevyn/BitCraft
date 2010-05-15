//
//  Shader.m
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Shader.h"


@implementation Shader

-(id)initVertexShaderFromFile:(NSString *)filename_;
{
  return [self initWithShaderType:GL_VERTEX_SHADER fromFile:filename_];
}

-(id)initFragmentShaderFromFile:(NSString *)filename_;
{
  return [self initWithShaderType:GL_FRAGMENT_SHADER fromFile:filename_];
}

-(id)initWithShaderType:(GLenum)type_ fromFile:(NSString *)filename_;
{
  if(![super init]) return nil;
  
  uid = 0;
  type = type_;
  filename = [filename_ retain];

  
  [self compile];
  
  return self;
}

-(void)dealloc
{
  glDeleteShader(uid);
  
  [filename release];
  
  [super dealloc];
}


- (BOOL)compile
{
  GLint status;
  const GLchar *source;
  
  source = (GLchar *)[[NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil] UTF8String];
  if (!source)
  {
    NSLog(@"Failed to load vertex shader");
    return FALSE;
  }
  
  uid = glCreateShader(type);
  glShaderSource(uid, 1, &source, NULL);
  glCompileShader(uid);
  
#if defined(DEBUG)
  GLint logLength;
  glGetShaderiv(uid, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0)
  {
    GLchar *log = (GLchar *)malloc(logLength);
    glGetShaderInfoLog(uid, logLength, &logLength, log);
    NSLog(@"Shader compile log:\n%s", log);
    free(log);
  }
#endif
  
  glGetShaderiv(uid, GL_COMPILE_STATUS, &status);
  if (status == 0)
  {
    glDeleteShader(uid);
    return FALSE;
  }
  
  return TRUE;
}



-(void)attachToProgram:(GLuint)program;
{
  glAttachShader(program, uid);
}

@end
