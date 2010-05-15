//
//  ShaderProgram.m
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ShaderProgram.h"


@implementation ShaderProgram

@synthesize program;

-(id)init
{
  if(![super init]) return nil;
  
  program = glCreateProgram();
  shaders = [[NSMutableArray alloc] init];
  uniforms = [[NSMutableDictionary alloc] init];
  attributes = [[NSMutableDictionary alloc] init];
  
  return self;
}


-(void)dealloc
{
  [uniforms release];
  [attributes release];
  glDeleteProgram(program);
  [super dealloc];
}


-(void)addShader:(Shader *)shader
{
  [shader attachToProgram:program];
  [shaders addObject:shader];
}

-(NSInteger)defineUniform:(NSString *)name;
{

  NSInteger location = glGetUniformLocation(program, [name cStringUsingEncoding:NSUTF8StringEncoding]);
  if(location == -1)
    [[NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"No uniform named %@", name] userInfo:nil] raise];
  [uniforms setValue:[NSNumber numberWithInteger:location] forKey:name];
  return location;
}

-(NSInteger)defineAttribute:(NSString *)name;
{
  NSInteger location = glGetAttribLocation(program, [name cStringUsingEncoding:NSUTF8StringEncoding]);
  if(location == -1)
    [[NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"No attribute named %@", name] userInfo:nil] raise];
  [attributes setValue:[NSNumber numberWithInteger:location] forKey:name];
  return location;
}

-(NSInteger)uniformNamed:(NSString *)name
{
  NSInteger location = [[uniforms valueForKey:name] integerValue];
  if(!location){
    location = [self defineUniform:name];
  }
  return location;
}

-(NSInteger)attributeNamed:(NSString *)name
{
  NSInteger location = [[attributes valueForKey:name] integerValue];
  if(!location){
    location = [self defineAttribute:name];
  }
  return location;
}

-(NSInteger)bindAttribute:(NSString *)name to:(NSInteger)location;
{
  if(![attributes valueForKey:name]){
    [attributes setValue:[NSNumber numberWithInteger:location] forKey:name];
    glBindAttribLocation(program, location, [name cStringUsingEncoding:NSUTF8StringEncoding]);
  }
  return location;
}


-(BOOL)link
{
  GLint status;
  
  glLinkProgram(program);
  
#if defined(DEBUG)
  GLint logLength;
  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0)
  {
    GLchar *log = (GLchar *)malloc(logLength);
    glGetProgramInfoLog(program, logLength, &logLength, log);
    NSLog(@"Program link log:\n%s", log);
    free(log);
  }
#endif
  
  glGetProgramiv(program, GL_LINK_STATUS, &status);
  if (status == 0)
    return FALSE;
  
  return TRUE;
}

-(BOOL)validate
{
  GLint logLength, status;
  
  glValidateProgram(program);
  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0)
  {
    GLchar *log = (GLchar *)malloc(logLength);
    glGetProgramInfoLog(program, logLength, &logLength, log);
    NSLog(@"Program validate log:\n%s", log);
    free(log);
  }
  
  glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
  if (status == 0)
    return FALSE;
  
  return TRUE;
}



-(void)use;
{
  glUseProgram(program);
}

@end
