//
//  ShaderVeriable.m
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ShaderVariable.h"
#import "Shader.h"

@implementation ShaderVariable

@synthesize location;

-(id)initWithName:(NSString *)name_ inProgram:(GLuint)program_;
{
  if(![super init]) return nil;
  
  program = program_;
  name = [name_ retain];
  
  [self bind];
  
  return self;
}

-(void)bind;
{
  
}

@end
