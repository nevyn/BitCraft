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
    
    [self setMultipleTouchEnabled:YES];
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
  for(UITouch *t in touches){
    [renderer finger:t touchedPoint:[t locationInView:self]];
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
  if(touches.count == 2){
    UITouch *t1 = [[touches allObjects] objectAtIndex:0];
    UITouch *t2 = [[touches allObjects] objectAtIndex:1];
    
    CGPoint p1 = [t1 locationInView:self];
    CGPoint p2 = [t2 locationInView:self];
    
    CGPoint pp1 = [t1 previousLocationInView:self];
    CGPoint pp2 = [t2 previousLocationInView:self];
    
    CGPoint diffNow = CGPointMake(p1.x - p2.x, p1.y - p2.y);
    CGPoint diffThen = CGPointMake(pp1.x - pp2.x, pp1.y - pp2.y);
    
    float distNow = sqrt(diffNow.x * diffNow.x + diffNow.y * diffNow.y);
    float distThen = sqrt(diffThen.x * diffThen.x + diffThen.y * diffThen.y);
    
    float diff = distNow - distThen;
    NSLog(@"zoomdist: %f", diff);
    [renderer zoom:diff];
    
  } else {
    UITouch *t = [touches anyObject];
    CGPoint p = [t locationInView:self];
    if(oldP.x && oldP.y) {
      CGSize sz = CGSizeMake(oldP.x-p.x, p.y-oldP.y);
      [renderer pan:sz];
    }
    oldP = p;
  }
  
  for(UITouch *t in touches){
    [renderer finger:t movedToPoint:[t locationInView:self]];
  }
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	oldP = CGPointZero;
  
  for(UITouch *t in touches){
    [renderer finger:t releasedPoint:[t locationInView:self]];
  }
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)evt;
{
	oldP = CGPointZero;
  for(UITouch *t in touches){
    [renderer finger:t releasedPoint:[t locationInView:self]];
  }
}
@end
