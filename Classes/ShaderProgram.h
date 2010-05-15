//
//  ShaderProgram.h
//  SpontanStrategi
//
//  Created by Patrik Sjöberg on 2010-05-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Shader.h"
#import "ShaderUniform.h"
#import "ShaderAttribute.h"

@interface ShaderProgram : NSObject {
  GLuint program;
  
  NSMutableArray *shaders;
  
  NSDictionary *uniforms;
  NSDictionary *attributes;
}

@property (readonly) GLuint program;

-(void)addShader:(Shader *)shader;
-(NSInteger)defineUniform:(NSString *)name;
-(NSInteger)defineAttribute:(NSString *)name;
-(NSInteger)bindAttribute:(NSString *)name to:(NSInteger)location;
-(NSInteger)uniformNamed:(NSString *)name;
-(NSInteger)attributeNamed:(NSString *)name;
-(BOOL)link;
-(BOOL)validate;
-(void)use;

@end