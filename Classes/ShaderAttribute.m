//
//  ShaderAttribute.m
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ShaderAttribute.h"


@implementation ShaderAttribute

-(void)bind;
{
  location = glGetAttribLocation(program, [name cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
