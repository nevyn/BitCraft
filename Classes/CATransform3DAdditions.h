//
//  CATransform3DAdditions.h
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-05-14.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

// From https://cvs.khronos.org/svn/repos/registry/trunk/public/webgl/sdk/demos/webkit/resources/CanvasMatrix.js

extern CATransform3D CATransform3DLookAt(
	CATransform3D t,
	CGFloat eyex, CGFloat eyey, CGFloat eyez,
	CGFloat centerx, CGFloat centery, CGFloat centerz,
	CGFloat upx, CGFloat upy, CGFloat upz
);

extern CATransform3D CATransform3DPerspective(
	CATransform3D t,
	CGFloat fovy, 
	CGFloat aspect, 
	CGFloat zNear, CGFloat zFar
);

extern CATransform3D CATransform3DFrustrum(
	CATransform3D t,
	CGFloat left, CGFloat right,
	CGFloat bottom, CGFloat top,
	CGFloat near, CGFloat far
);

extern CATransform3D CATransform3DTranspose(
	CATransform3D t
);