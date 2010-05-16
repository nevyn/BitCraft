//
//  ES2Renderer.m
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-04-24.
//  Copyright Spotify 2010. All rights reserved.
//

#import "ES2Renderer.h"
#import "CATransform3DAdditions.h"
#import "RenderOptions.h"
#import "Finger.h"

struct rgbacolor {
  GLubyte r, g, b, a;
};

@interface ES2Renderer (PrivateMethods)
- (BOOL)loadShaders;
@end

@implementation ES2Renderer


// Create an OpenGL ES 2.0 context
- (id)init
{
	if (![super init]) return nil;
  
  context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  if (!context || ![EAGLContext setCurrentContext:context] || ![self loadShaders])
  {
    [self release];
    return nil;
  }
  
  fingers = [[NSMutableDictionary alloc] init];
  
  terraintex = [[Texture2D textureNamed:@"tex.jpg"] retain];
  
  cameraRot = CGPointMake(-1.25, -0.65);
  
  // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
  glGenFramebuffers(1, &defaultFramebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
  
  glGenRenderbuffers(1, &colorRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
  
  glGenRenderbuffers(1, &depthRenderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
  
  saker = [[NSMutableArray alloc] init];
  for(float something = -5; something < 5; something+= 1) {
    Entity *sak = [[[Entity alloc] initWithRenderable:[[QuadMesh new] autorelease]] autorelease];
    Vector4 *pos = [Vector4 vectorWithX:something y:((int)something)%2 z:0 w:1];
    sak.position = pos;
    sak.shader = standardShader;
    [saker addObject:sak];
  }
  
 	Heightmap *heightmap = [[Heightmap alloc] initWithImage:[UIImage imageNamed:@"heightmap.png"] 
                                    resolution:0.1
                                         depth:0.5];
  Entity *sak = [[[Entity alloc] initWithRenderable:heightmap] autorelease];
  sak.position = [Vector4 vectorWithX:-heightmap.sizeInUnits.width/2.
                                    y:-heightmap.sizeInUnits.height/2.
                                    z:-1
                                    w:1];
  sak.shader = standardShader;
  sak.pickable = NO;
  [saker addObject:sak];

  
	
	return self;
}

- (void)render
{

	// This application only creates a single context which is already set current at this point.
	// This call is redundant, but needed if dealing with multiple contexts.
	[EAGLContext setCurrentContext:context];
	
	// This application only creates a single default framebuffer which is already bound at this point.
	// This call is redundant, but needed if dealing with multiple framebuffers.
	glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	glViewport(0, 0, backingWidth, backingHeight);
	glEnable(GL_CULL_FACE);
  glEnable(GL_DEPTH_TEST);
	
  RenderOptions *renderOptions = [[RenderOptions alloc] init];
  renderOptions.picking = newFingers != nil;
  
  if(renderOptions.picking)
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
  else
    glClearColor(0.0f, 0.0f, 0.2f, 1.0f);
  
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
  
  CATransform3D camera = CATransform3DIdentity;
	camera = CATransform3DRotate(camera, cameraRot.x, 1, 0, 0);
	camera = CATransform3DRotate(camera, cameraRot.y, 0, 0, 1);
	camera = CATransform3DTranslate(camera, pan.x, pan.y, zoom);
  camera.m44 = 1+zoom;
	
  renderOptions.viewport = CGRectMake(0, 0, backingWidth, backingHeight);
  renderOptions.viewMatrix = camera;
  renderOptions.projectionMatrix = perspectiveMatrix;
  
  [terraintex apply];
  
  for(Entity *sak in saker) {
    if(renderOptions.picking && sak.pickable)
    	renderOptions.shaderProgram = pickingShader;
  	else
    	renderOptions.shaderProgram = sak.shader;
    
    [renderOptions.shaderProgram use];
    
		glUniform3f([standardShader uniformNamed:@"lightDir"], 0.2, 0.2, 1.0);

    [sak renderWithOptions:renderOptions];
  }
  

/*  renderOptions.modelViewMatrix = CATransform3DRotate(CATransform3DRotate(CATransform3DMakeTranslation(
  	-heightmap.sizeInUnits.width/2., 
    -heightmap.sizeInUnits.height/2.,
    -1.
  ), debugPan.x, 0, 0, 1), debugPan.y, 0, 1, 0);*/
	  
  if(renderOptions.picking){
    for(Finger *finger in newFingers){
      CGPoint point = finger.point;
      GLuint pickedPointer;
      glReadPixels(point.x, backingHeight - point.y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, &pickedPointer);
      if(pickedPointer > 0){
        Entity *obj = (id)pickedPointer;
        finger.object = obj;
      }
    }
    
    [newFingers release];
    newFingers = nil;
  }
  
  Finger *finger = [[fingers allValues] lastObject];
  if(finger){
    Entity *entity = finger.object;
    
    CGPoint point = finger.point;
    point.y = backingHeight - point.y;
    //AAAAAAAAAAARgh    
 //   CATransform3D mm = CATransform3DConcat(renderOptions.projectionMatrix, renderOptions.viewMatrix);
//    mm = renderOptions.projectionMatrix;
//    CATransform3D m = CATransform3DInvert(mm);
//    
//    
//    Vector4 *v = [Vector4 vectorWithX:(((point.x*2) / backingWidth) - 1)
//                                    y:(((point.y*2) / backingHeight) - 1)
//                                    z:0.0 w:1];
//
//    NSLog(@"pos: %.2f %.2f", v.x, v.y);
////    Vector4 *v = [Vector4 vectorWithX:point.x 
////                                    y:point.y
////                                    z:0 w:1];
//
//    
//    // Transform the screen space pick ray into 3D space
//    Vector4 *rayDir = [Vector4 vectorWithX:v.x*m.m11 + v.y*m.m21 + v.z*m.m31 
//                       y:v.x*m.m12 + v.y*m.m22 + v.z*m.m32 
//                       z:v.x*m.m13 + v.y*m.m23 + v.z*m.m33 
//                       w:1];
//    Vector4 *rayOrigin = [Vector4 vectorWithX:m.m41 y:m.m42 z:m.m43 w:1];
//    
//    
//    NSLog(@"hmm? %.2f %.2f %.2f %.2f", rayOrigin.x, rayOrigin.y, rayOrigin.z, rayOrigin.w);
//    entity.position = [Vector4 vectorWithX:rayOrigin.x y:rayOrigin.y z:rayOrigin.z w:1];
  }
  

	// This application only creates a single color renderbuffer which is already bound at this point.
	// This call is redundant, but needed if dealing with multiple renderbuffers.
  
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
  if(!renderOptions.picking){
    [context presentRenderbuffer:GL_RENDERBUFFER];
  }
  
  [renderOptions release];
}


- (BOOL)loadShaders
{
  standardShader = [[[ShaderProgram alloc] initWithShaderName:@"Shader"] commonSetup];
  terrainShader = [[[ShaderProgram alloc] initWithShaderName:@"Terrain"] commonSetup];
  pickingShader = [[[ShaderProgram alloc] initWithShaderName:@"picking"] commonSetup];
  
  return TRUE;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
  
  glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
	
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		return NO;
	}
	
	perspectiveMatrix = CATransform3DIdentity;
	perspectiveMatrix = CATransform3DLookAt(perspectiveMatrix, 0, 0, 7, 0, 0, 0, 0, 1, 0);
	perspectiveMatrix = CATransform3DPerspective(perspectiveMatrix, 30, backingWidth/(float)backingHeight, 1, 10000);
	
	return YES;
}

- (void)dealloc
{
  
  [saker release];
  
  
	// Tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffers(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffers(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
  [standardShader release];
  
	// Tear down context
	if ([EAGLContext currentContext] == context)
		[EAGLContext setCurrentContext:nil];
	
	[context release];
	context = nil;
  
	[super dealloc];
}

- (void)pan:(CGSize)diff;
{
	float s = sinf(-cameraRot.y);
	float c = cosf(-cameraRot.y);
	
	diff = CGSizeMake(diff.width/300., diff.height/200.);
  
	diff = CGSizeMake(
		diff.width*c - diff.height*s,
		diff.width*s + diff.height*c
	);

	pan.x -= diff.width;
	pan.y -= diff.height;
}

-(void)zoom:(float)diff;
{
  zoom += diff * 0.01;
  NSLog(@"zoom: %f", zoom);
}


- (void)finger:(id)touch touchedPoint:(CGPoint)point;
{
  NSValue *touchValue = [NSValue valueWithPointer:touch];
  Finger *finger = [fingers objectForKey:touchValue];
  
  if(!finger) {
    finger = [[Finger alloc] init];
    finger.point = point;
    finger.oldPoint = point;
    [fingers setObject:finger forKey:touchValue];
    
    if(!newFingers)
      newFingers = [[NSMutableArray alloc] init];
    [newFingers addObject:finger];
  }
  NSLog(@"fingers: %@", fingers);
}

- (void)finger:(id)touch releasedPoint:(CGPoint)point;
{
  NSValue *touchValue = [NSValue valueWithPointer:touch];
  Finger *finger = [fingers objectForKey:touchValue];
  
  if(finger)
    [newFingers removeObject:finger];
  
  [fingers removeObjectForKey:touchValue];
  NSLog(@"fingers: %@", fingers);
}

- (void)finger:(id)touch movedToPoint:(CGPoint)point;
{
  Finger *finger = [fingers objectForKey:[NSValue valueWithPointer:touch]];
  Entity *entity = finger.object;
  NSLog(@"fingers: %@", fingers);
}

- (void)debugPan:(CGSize)diff;
{
	diff = CGSizeMake(diff.width/300., diff.height/300.);

	debugPan.x -= diff.width;
	debugPan.y -= diff.height;
}

@end
