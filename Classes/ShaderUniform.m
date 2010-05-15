//
//  ShaderUniform.m
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ShaderUniform.h"


@implementation ShaderUniform

-(void)bind;
{
  location = glGetUniformLocation(program, [name cStringUsingEncoding:NSUTF8StringEncoding]);
}

-(void)setFloatValue:(CGFloat)value;
{
  glUniform1f(location, value);
}

@end
