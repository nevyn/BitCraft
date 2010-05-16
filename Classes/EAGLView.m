//
//  EAGLView.m
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-04-24.
//  Copyright Spotify 2010. All rights reserved.
//

#import "EAGLView.h"

#import "ES2Renderer.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
	if ((self = [super initWithCoder:coder]))
	{
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = TRUE;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
																		[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
		renderer = [[ES2Renderer alloc] init];
		
		if (!renderer)
		{
			[self release];
			return nil;
		}
		
		animating = FALSE;
		displayLinkSupported = FALSE;
		animationFrameInterval = 1;
		displayLink = nil;
		animationTimer = nil;
		
		// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
		// class is used as fallback when it isn't available.
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
			displayLinkSupported = TRUE;
	}
	
	return self;
}

- (void)drawView:(id)sender
{
	[renderer render];
}

- (void)layoutSubviews
{
	[renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
	[self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
	return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
	// Frame interval defines how many display frames must pass between each time the
	// display link fires. The display link will only fire 30 times a second when the
	// frame internal is two on a display that refreshes 60 times a second. The default
	// frame interval setting of one will fire 60 times a second when the display refreshes
	// at 60 times a second. A frame interval setting of less than one results in undefined
	// behavior.
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void)startAnimation
{
	if (!animating)
	{
		if (displayLinkSupported)
		{
			// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
			// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
			// not be called in system versions earlier than 3.1.
			
			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		}
		else
			animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];
		
		animating = TRUE;
	}
}

- (void)stopAnimation
{
	if (animating)
	{
		if (displayLinkSupported)
		{
			[displayLink invalidate];
			displayLink = nil;
		}
		else
		{
			[animationTimer invalidate];
			animationTimer = nil;
		}
		
		animating = FALSE;
	}
}

- (void)dealloc
{
	[renderer release];
	
	[super dealloc];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[first release];
	first = [[touches anyObject] retain];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	UITouch *t = first;
  CGPoint oldP = [t previousLocationInView:self];
	CGPoint p = [t locationInView:self];
	CGSize sz = CGSizeMake(oldP.x-p.x, p.y-oldP.y);
  scrollVelocity = sz;
  if([touches count] == 1)
		[renderer pan:sz];
  else 
  	[renderer debugPan:sz];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent*)evt;
{
	[self performSelector:@selector(velocityScroll) withObject:nil afterDelay:0.01];
}
-(void)velocityScroll;
{
	CGSize thisScroll = CGSizeMake(scrollVelocity.width*0.5, scrollVelocity.height*0.5);
	[renderer pan:thisScroll];
  scrollVelocity = CGSizeMake(scrollVelocity.width*0.9, scrollVelocity.height*0.9);
  if(abs(scrollVelocity.width) + abs(scrollVelocity.height) > 0.1)
  	[self performSelector:@selector(velocityScroll) withObject:nil afterDelay:0.01];
}
@end
