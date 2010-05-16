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

// uniform index
enum {
	UNIFORM_MVP,
	UNIFORM_NORMALMATRIX,
	UNIFORM_LIGHTDIR,
	UNIFORM_SAMPLER,
	NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum {
	ATTRIB_VERTEX,
	ATTRIB_COLOR,
	ATTRIB_TEXCOORD,
	ATTRIB_NORMAL,
  ATTRIB_INDEX,
	NUM_ATTRIBUTES
};

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
	if ((self = [super init]))
	{
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!context || ![EAGLContext setCurrentContext:context] || ![self loadShaders])
		{
			[self release];
			return nil;
		}
    
    fingers = [[NSMutableDictionary alloc] init];
		
		terraintex = [[Texture2D textureNamed:@"heightmap.png"] retain];
    heightmap = [[Heightmap alloc] initWithImage:[UIImage imageNamed:@"heightmap.png"] 
                                      resolution:0.1];
		
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
      Entity *sak = [[Entity alloc] init];
      Vector4 *pos = [Vector4 vectorWithX:something y:((int)something)%2 z:0 w:1];
      sak.position = pos;
      [saker addObject:sak];
    }
	}
	
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
	
	glUniform3f(uniforms[UNIFORM_LIGHTDIR], 0.2, 1, -0.2);
	glUniform1i(uniforms[UNIFORM_SAMPLER], terraintex.name);
	

  renderOptions.viewport = CGRectMake(0, 0, backingWidth, backingHeight);
  renderOptions.viewMatrix = camera;
  renderOptions.projectionMatrix = perspectiveMatrix;

  if(renderOptions.picking)
    renderOptions.shaderProgram = pickingShader;
  else
    renderOptions.shaderProgram = shaderProgram;
  
	// Use shader program
  [renderOptions.shaderProgram use];
  
	
	glUniform3f(uniforms[UNIFORM_LIGHTDIR], 0.2, 1, -0.2);
	glUniform1i(uniforms[UNIFORM_SAMPLER], terraintex.name);
  
  [heightmap renderWithOptions:renderOptions];
	
  CATransform3D modelview = CATransform3DIdentity;
  
  CATransform3D normal = modelview;
  normal = CATransform3DInvert(normal);
  normal = CATransform3DTranspose(normal);
  glUniformMatrix4fv(uniforms[UNIFORM_NORMALMATRIX], 1, GL_FALSE, (float*)&normal);
  
  renderOptions.modelViewMatrix = modelview;
  renderOptions.shaderProgram = shaderProgram;
  
  [terraintex apply];
  
  for(Entity *sak in saker)
    [sak renderWithOptions:renderOptions];
  
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

-(void)setupShader:(ShaderProgram*)shader shaderName:(NSString *)name
{
  Shader *vertShader = [[Shader alloc] initVertexShaderFromFile:[[NSBundle mainBundle] pathForResource:name ofType:@"vsh"]];
  [shader addShader:vertShader];
  [vertShader release];
  
  Shader *fragShader = [[Shader alloc] initFragmentShaderFromFile:[[NSBundle mainBundle] pathForResource:name ofType:@"fsh"]];
  [shader addShader:fragShader];
  [fragShader release];
  
  
  [shader bindAttribute:@"position" to:ATTRIB_VERTEX];
  [shader bindAttribute:@"color" to:ATTRIB_COLOR];
  [shader bindAttribute:@"texCoord" to:ATTRIB_TEXCOORD];
  [shader bindAttribute:@"normal" to:ATTRIB_NORMAL];
  [shader link];
  
  
  uniforms[UNIFORM_MVP]           = [shader defineUniform:@"mvp"];
  uniforms[UNIFORM_NORMALMATRIX]  = [shader defineUniform:@"normalMatrix"];
  uniforms[UNIFORM_LIGHTDIR]      = [shader defineUniform:@"lightDir"];
  
  [shader validate];
}

- (BOOL)loadShaders
{
  shaderProgram = [[ShaderProgram alloc] init];
  
  [self setupShader:shaderProgram shaderName:@"Shader"];

  pickingShader = [[ShaderProgram alloc] init];
  [self setupShader:pickingShader shaderName:@"picking"];
  
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
	
  [shaderProgram release];
  
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
	
	diff = CGSizeMake(
		diff.width*c - diff.height*s,
		diff.width*s + diff.height*c
	);
	
	diff = CGSizeMake(diff.width/300., diff.height/300.);

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

@end
