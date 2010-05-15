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
		
		heightmap = [Texture2D textureNamed:@"heightmap.png"];
		
		cameraRot = CGPointMake(-1.25, -0.65);
		
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffers(1, &defaultFramebuffer);
		glGenRenderbuffers(1, &colorRenderbuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    
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
	glViewport(0, 0, backingWidth, backingHeight);
	//glDepthRangef(0.1, 1000.);
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
  
  CATransform3D camera = CATransform3DIdentity;
	camera = CATransform3DRotate(camera, cameraRot.x, 1, 0, 0);
	camera = CATransform3DRotate(camera, cameraRot.y, 0, 0, 1);
	camera = CATransform3DTranslate(camera, pan.x, pan.y, zoom);
  camera.m44 = 1+zoom;
  
  RenderOptions *renderOptions = [[RenderOptions alloc] init];
  renderOptions.picking = touchPoints != nil;

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
	glUniform1i(uniforms[UNIFORM_SAMPLER], heightmap.name);
	
  CATransform3D modelview = CATransform3DIdentity;
		
  CATransform3D normal = modelview;
  normal = CATransform3DInvert(normal);
  normal = CATransform3DTranspose(normal);
  glUniformMatrix4fv(uniforms[UNIFORM_NORMALMATRIX], 1, GL_FALSE, (float*)&normal);
  
  renderOptions.modelViewMatrix = modelview;
  renderOptions.shaderProgram = shaderProgram;
  
		
  if(!renderOptions.picking)
    [heightmap apply];
		
  for(Entity *sak in saker)
    [sak renderWithOptions:renderOptions];
  
  if(renderOptions.picking){
    [touchedObjects release];
    touchedObjects = [[NSMutableArray alloc] init];
    
    for(NSValue *touch in touchPoints){
      CGPoint point = [touch CGPointValue];
      GLuint pickedPointer;
      glReadPixels(point.x, backingHeight - point.y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, &pickedPointer);
      if(pickedPointer > 0){
        Entity *obj = (id)pickedPointer;
        [touchedObjects addObject:obj];
      }
    }
    
    [touchPoints release];
    touchPoints = nil;
  }

	// This application only creates a single color renderbuffer which is already bound at this point.
	// This call is redundant, but needed if dealing with multiple renderbuffers.
  
  glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
  if(!renderOptions.picking){
    [context presentRenderbuffer:GL_RENDERBUFFER];
  }
  
  [renderOptions release];
}

-(void)touched:(CGPoint)point;
{
  if(!touchPoints)
    touchPoints = [[NSMutableArray alloc] init]; 
  [touchPoints addObject:[NSValue valueWithCGPoint:point]];
}

- (BOOL)loadShaders
{
  shaderProgram = [[ShaderProgram alloc] init];
  
  Shader *vertShader = [[Shader alloc] initVertexShaderFromFile:[[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"]];
  [shaderProgram addShader:vertShader];
  [vertShader release];
  
  Shader *fragShader = [[Shader alloc] initFragmentShaderFromFile:[[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"]];
  [shaderProgram addShader:fragShader];
  [fragShader release];
  
  [shaderProgram link];
  [shaderProgram defineAttribute:@"position"];
  [shaderProgram defineAttribute:@"color"];
  [shaderProgram defineAttribute:@"texCoord"];
  [shaderProgram defineAttribute:@"normal"];
  
  
  uniforms[UNIFORM_MVP]           = [shaderProgram defineUniform:@"mvp"];
  uniforms[UNIFORM_NORMALMATRIX]  = [shaderProgram defineUniform:@"normalMatrix"];
  uniforms[UNIFORM_LIGHTDIR]      = [shaderProgram defineUniform:@"lightDir"];
  
  [shaderProgram validate];
  
  

  pickingShader = [[ShaderProgram alloc] init];
  
  vertShader = [[Shader alloc] initVertexShaderFromFile:[[NSBundle mainBundle] pathForResource:@"picking" ofType:@"vsh"]];
  [pickingShader addShader:vertShader];
  [vertShader release];
  
  fragShader = [[Shader alloc] initFragmentShaderFromFile:[[NSBundle mainBundle] pathForResource:@"picking" ofType:@"fsh"]];
  [pickingShader addShader:fragShader];
  [fragShader release];
  
  [pickingShader link];
  [pickingShader defineAttribute:@"position"];
  [pickingShader defineAttribute:@"color"];
  [pickingShader defineAttribute:@"texCoord"];
  [pickingShader defineAttribute:@"normal"];
  
  
  uniforms[UNIFORM_MVP]           = [pickingShader defineUniform:@"mvp"];
  uniforms[UNIFORM_NORMALMATRIX]  = [pickingShader defineUniform:@"normalMatrix"];
  uniforms[UNIFORM_LIGHTDIR]      = [pickingShader defineUniform:@"lightDir"];
  
  [pickingShader validate];
  
  return TRUE;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	// Allocate color buffer backing based on the current layer size
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	
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
@end
