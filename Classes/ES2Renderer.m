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
		
		terraintex = [[Texture2D textureNamed:@"tex.jpg"] retain];
    heightmap = [[Heightmap alloc] initWithImage:[UIImage imageNamed:@"heightmap.png"] 
                                      resolution:0.1
                                      depth:0.5];
		
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
    
    sak = [[Entity alloc] init];
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
	
	glClearColor(0.0f, 0.0f, 0.2f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
	// Use shader program
  [shaderProgram use];
	
	CATransform3D camera = CATransform3DIdentity;
	camera = CATransform3DRotate(camera, cameraRot.x, 1, 0, 0);
	camera = CATransform3DRotate(camera, cameraRot.y, 0, 0, 1);
	camera = CATransform3DTranslate(camera, pan.x, pan.y, 0);
	
	glUniform3f([shaderProgram uniformNamed:@"lightDir"], 0.2, 0.2, 1.0);

	[terraintex apply];
	
	static float foo = 0.0;
	foo += 0.025;
  
  RenderOptions *renderOptions = [[RenderOptions alloc] init];
  
  renderOptions.viewMatrix = camera;
  renderOptions.projectionMatrix = perspectiveMatrix;
  renderOptions.shaderProgram = shaderProgram;
  renderOptions.modelViewMatrix = CATransform3DRotate(CATransform3DRotate(CATransform3DMakeTranslation(
  	-heightmap.sizeInUnits.width/2., 
    -heightmap.sizeInUnits.height/2.,
    -1.
  ), debugPan.x, 0, 0, 1), debugPan.y, 0, 1, 0);
  [heightmap renderWithOptions:renderOptions];
	
	for(float something = -5; something < 5; something+= 1) {
    renderOptions.modelViewMatrix = CATransform3DIdentity;
		
    Vector4 *pos = [Vector4 vectorWithX:something y:((int)something)%2 z:0 w:1];
    sak.position = pos;
    [sak renderWithOptions:renderOptions];
	}
  
  [renderOptions release];

	// This application only creates a single color renderbuffer which is already bound at this point.
	// This call is redundant, but needed if dealing with multiple renderbuffers.
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

- (BOOL)loadShaders
{
  shaderProgram = [[[ShaderProgram alloc] initWithShaderName:@"Shader"] commonSetup];
  
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
	
	diff = CGSizeMake(diff.width/300., diff.height/200.);
  
	diff = CGSizeMake(
		diff.width*c - diff.height*s,
		diff.width*s + diff.height*c
	);

	pan.x -= diff.width;
	pan.y -= diff.height;
}
- (void)debugPan:(CGSize)diff;
{
	diff = CGSizeMake(diff.width/300., diff.height/300.);

	debugPan.x -= diff.width;
	debugPan.y -= diff.height;
}
@end
