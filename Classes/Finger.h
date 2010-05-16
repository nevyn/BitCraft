//
//  Finger.h
//  BitCraft
//
//  Created by Patrik Sjöberg on 2010-05-15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Finger : NSObject {
  CGPoint point;
  CGPoint oldPoint;
  
  id object;
}

@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) CGPoint oldPoint;
@property (nonatomic, assign) id object;

@end
