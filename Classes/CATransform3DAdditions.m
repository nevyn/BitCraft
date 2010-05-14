//
//  CATransform3DAdditions.m
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-05-14.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import "CATransform3DAdditions.h"

CATransform3D CATransform3DLookAt(
	CATransform3D t,
	CGFloat eyex, CGFloat eyey, CGFloat eyez,
	CGFloat centerx, CGFloat centery, CGFloat centerz,
	CGFloat upx, CGFloat upy, CGFloat upz
) {
	CATransform3D matrix = CATransform3DIdentity;
	
	// Make rotation matrix
	
	// Z vector
	CGFloat zx = eyex - centerx;
	CGFloat zy = eyey - centery;
	CGFloat zz = eyez - centerz;
	CGFloat mag = sqrtf(zx * zx + zy * zy + zz * zz);
	if (isfinite(mag) && mag > 0) {
		zx /= mag;
		zy /= mag;
		zz /= mag;
	}
	
	// Y vector
	CGFloat yx = upx;
	CGFloat yy = upy;
	CGFloat yz = upz;
	
	// X vector = Y cross Z
	CGFloat xx =  yy * zz - yz * zy;
	CGFloat xy = -yx * zz + yz * zx;
	CGFloat xz =  yx * zy - yy * zx;
	
	// Recompute Y = Z cross X
	yx = zy * xz - zz * xy;
	yy = -zx * xz + zz * xx;
	yx = zx * xy - zy * xx;
	
	// cross product gives area of parallelogram, which is < 1.0 for
	// non-perpendicular unit-length vectors; so normalize x, y here
	
	mag = sqrtf(xx * xx + xy * xy + xz * xz);
	if (isfinite(mag) && mag > 0) {
		xx /= mag;
		xy /= mag;
		xz /= mag;
	}
	
	mag = sqrtf(yx * yx + yy * yy + yz * yz);
	if (isfinite(mag) && mag > 0) {
		yx /= mag;
		yy /= mag;
		yz /= mag;
	}
	
	matrix.m11 = xx;
	matrix.m12 = xy;
	matrix.m13 = xz;
	matrix.m14 = 0;
	
	matrix.m21 = yx;
	matrix.m22 = yy;
	matrix.m23 = yz;
	matrix.m24 = 0;
	
	matrix.m31 = zx;
	matrix.m32 = zy;
	matrix.m33 = zz;
	matrix.m34 = 0;
	
	matrix.m41 = 0;
	matrix.m42 = 0;
	matrix.m43 = 0;
	matrix.m44 = 1;
	matrix = CATransform3DTranslate(matrix, -eyex, -eyey, -eyez);
	
	return CATransform3DConcat(t, matrix);
}

CATransform3D CATransform3DPerspective(
	CATransform3D t,
	CGFloat fovy, 
	CGFloat aspect, 
	CGFloat zNear, CGFloat zFar
) {
	CGFloat top = tanf(fovy * M_PI / 360) * zNear;
	CGFloat bottom = -top;
	CGFloat left = aspect * bottom;
	CGFloat right = aspect * top;
	return CATransform3DFrustrum(t, left, right, bottom, top, zNear, zFar);
}

CATransform3D CATransform3DFrustrum(
	CATransform3D t,
	CGFloat left, CGFloat right,
	CGFloat bottom, CGFloat top,
	CGFloat near, CGFloat far
) {
	CATransform3D matrix = CATransform3DIdentity;
	CGFloat A = (right + left) / (right - left);
  CGFloat B = (top + bottom) / (top - bottom);
  CGFloat C = -(far + near) / (far - near);
  CGFloat D = -(2 * far * near) / (far - near);

	matrix.m11 = (2 * near) / (right - left);
	matrix.m12 = 0;
	matrix.m13 = 0;
	matrix.m14 = 0;
	
	matrix.m21 = 0;
	matrix.m22 = 2 * near / (top - bottom);
	matrix.m23 = 0;
	matrix.m24 = 0;
	
	matrix.m31 = A;
	matrix.m32 = B;
	matrix.m33 = C;
	matrix.m34 = -1;
	
	matrix.m41 = 0;
	matrix.m42 = 0;
	matrix.m43 = D;
	matrix.m44 = 0;
	
	return CATransform3DConcat(t, matrix);
}

extern CATransform3D CATransform3DTranspose(
	CATransform3D t
) {
	CATransform3D u;
	u.m11 = t.m11;
	u.m12 = t.m21;
	u.m13 = t.m31;
	u.m14 = t.m41;
	
	u.m21 = t.m12;
	u.m22 = t.m22;
	u.m23 = t.m32;
	u.m24 = t.m42;
	
	u.m31 = t.m13;
	u.m32 = t.m23;
	u.m33 = t.m33;
	u.m34 = t.m43;
	
	u.m41 = t.m14;
	u.m42 = t.m24;
	u.m43 = t.m34;
	u.m44 = t.m44;
	
	return u;
}