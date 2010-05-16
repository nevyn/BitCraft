//
//  UIImage+getPixels.h
//  BitCraft
//
//  Created by Joachim Bengtsson on 2010-05-15.
//  Copyright 2010 Third Cog Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIImage (BCGetPixels)
-(void)bc_getPixels:(unsigned char*)pixels;
@end
