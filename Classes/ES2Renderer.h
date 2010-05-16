//
//  ES2Renderer.h
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-04-24.
//  Copyright Spotify 2010. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGL.h>
#import <QuartzCore/QuartzCore.h>
#import "Texture2D.h"

#import "Entity.h"
#import "Heightmap.h"

@interface ES2Renderer : NSObject
{
@private
  EAGLContext *context;

  // The pixel dimensions of the CAEAGLLayer
  GLint backingWidth;
  GLint backingHeight;

  // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
  GLuint defaultFramebuffer, colorRenderbuffer, depthRenderbuffer;
  
  float zoom;
  CGPoint pan;
  CGPoint cameraRot;
  CATransform3D perspectiveMatrix;
  ShaderProgram *shaderProgram;
  ShaderProgram *pickingShader;
  ShaderProgram *terrainShader;
  
  Heightmap *heightmap;
  Texture2D *terraintex;

  NSMutableArray *saker;
  
  NSMutableDictionary *fingers;
  NSMutableArray *newFingers;


  CGPoint debugPan;
}

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

- (void)pan:(CGSize)diff;
- (void)zoom:(float)diff;

- (void)finger:(id)touch touchedPoint:(CGPoint)point;
- (void)finger:(id)touch releasedPoint:(CGPoint)point;
- (void)finger:(id)touch movedToPoint:(CGPoint)point;
- (void)debugPan:(CGSize)diff;
@end

