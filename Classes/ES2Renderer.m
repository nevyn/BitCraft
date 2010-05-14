//
//  ES2Renderer.m
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-04-24.
//  Copyright Spotify 2010. All rights reserved.
//

#import "ES2Renderer.h"
#import "CATransform3DAdditions.h"

// uniform index
enum {
	UNIFORM_MVP,
	NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum {
	ATTRIB_VERTEX,
	ATTRIB_COLOR,
	NUM_ATTRIBUTES
};


@interface ES2Renderer (PrivateMethods)
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
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
		
		cameraRot = CGPointMake(-1.25, -0.65);
		
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffers(1, &defaultFramebuffer);
		glGenRenderbuffers(1, &colorRenderbuffer);
		glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
		glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
	}
	
	return self;
}

- (void)render
{
	// Replace the implementation of this method to do your own custom drawing
	
	static const GLfloat squareVertices[] = {
		-0.2f, -0.2f, 0., //bl
		0.2f, -0.2f, 0., //br
		-0.2f,  0.2f, 0., //tl
		0.2f,  0.2f, 0. //tr
	};
	
	static const GLubyte squareColors[] = {
		255, 0,   0, 255,
		255, 0,   0, 255,
		255, 0,   0, 255,
		255, 0,   0, 255,
	};
	
	float something = 0;
	
	// This application only creates a single context which is already set current at this point.
	// This call is redundant, but needed if dealing with multiple contexts.
	[EAGLContext setCurrentContext:context];
	
	// This application only creates a single default framebuffer which is already bound at this point.
	// This call is redundant, but needed if dealing with multiple framebuffers.
	glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
	glViewport(0, 0, backingWidth, backingHeight);
	//glDepthRangef(0.1, 1000.);
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
	// Use shader program
	glUseProgram(program);
	
	CATransform3D camera = CATransform3DIdentity;
	camera = CATransform3DRotate(camera, cameraRot.x, 1, 0, 0);
	camera = CATransform3DRotate(camera, cameraRot.y, 0, 0, 1);
	camera = CATransform3DTranslate(camera, pan.x, pan.y, 0);
	
	for(something = -5; something < 5; something+= 1) {
		CATransform3D modelview = CATransform3DMakeTranslation(something, ((int)something)%2, 0);
		
		CATransform3D mvp = CATransform3DIdentity;
		mvp = CATransform3DConcat(mvp, modelview);
		mvp = CATransform3DConcat(mvp, camera);
		mvp = CATransform3DConcat(mvp, perspectiveMatrix);
	
		mvp = CATransform3DTranspose(mvp);
		// Update uniform value
		glUniformMatrix4fv(uniforms[UNIFORM_MVP], 1, FALSE, (float*)&mvp);
		
		
		// Update attribute values
		glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, squareVertices);
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, 1, 0, squareColors);
		glEnableVertexAttribArray(ATTRIB_COLOR);
		
		// Validate program before drawing. This is a good check, but only really necessary in a debug build.
		// DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
		if (![self validateProgram:program])
		{
			NSLog(@"Failed to validate program: %d", program);
			return;
		}
#endif
		
		// Draw
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
	}
	
	// This application only creates a single color renderbuffer which is already bound at this point.
	// This call is redundant, but needed if dealing with multiple renderbuffers.
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
	GLint status;
	const GLchar *source;
	
	source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
	if (!source)
	{
		NSLog(@"Failed to load vertex shader");
		return FALSE;
	}
	
	*shader = glCreateShader(type);
	glShaderSource(*shader, 1, &source, NULL);
	glCompileShader(*shader);
	
#if defined(DEBUG)
	GLint logLength;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s", log);
		free(log);
	}
#endif
	
	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		glDeleteShader(*shader);
		return FALSE;
	}
	
	return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
	GLint status;
	
	glLinkProgram(prog);
	
#if defined(DEBUG)
	GLint logLength;
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s", log);
		free(log);
	}
#endif
	
	glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0)
		return FALSE;
	
	return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
	GLint logLength, status;
	
	glValidateProgram(prog);
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}
	
	glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
	if (status == 0)
		return FALSE;
	
	return TRUE;
}

- (BOOL)loadShaders
{
	GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;
	
	// Create shader program
	program = glCreateProgram();
	
	// Create and compile vertex shader
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
	{
		NSLog(@"Failed to compile vertex shader");
		return FALSE;
	}
	
	// Create and compile fragment shader
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
	if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
	{
		NSLog(@"Failed to compile fragment shader");
		return FALSE;
	}
	
	// Attach vertex shader to program
	glAttachShader(program, vertShader);
	
	// Attach fragment shader to program
	glAttachShader(program, fragShader);
	
	// Bind attribute locations
	// this needs to be done prior to linking
	glBindAttribLocation(program, ATTRIB_VERTEX, "position");
	glBindAttribLocation(program, ATTRIB_COLOR, "color");
	
	// Link program
	if (![self linkProgram:program])
	{
		NSLog(@"Failed to link program: %d", program);
		
		if (vertShader)
		{
			glDeleteShader(vertShader);
			vertShader = 0;
		}
		if (fragShader)
		{
			glDeleteShader(fragShader);
			fragShader = 0;
		}
		if (program)
		{
			glDeleteProgram(program);
			program = 0;
		}
		
		return FALSE;
	}
	
	// Get uniform locations
	uniforms[UNIFORM_MVP] = glGetUniformLocation(program, "mvp");
	
	// Release vertex and fragment shaders
	if (vertShader)
		glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);
	
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
	
	if (program)
	{
		glDeleteProgram(program);
		program = 0;
	}
	
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
@end
