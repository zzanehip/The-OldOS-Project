//
//  XBAnimationManager.h
//  XBPageCurl
//
//  Created by xiss burg on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XBAnimation;

/**
 * XBAnimationManager
 * Manages a set of animations. Animations can be added and removed manually and they are automatically removed after
 * they're finished. The update: method must be called to mvoe things forward.
 */
@interface XBAnimationManager : NSObject

- (void)runAnimation:(XBAnimation *)animation;
- (void)stopAnimation:(XBAnimation *)animation;
- (void)stopAnimationNamed:(NSString *)name;
- (void)stopAllAnimations;

- (void)update:(NSTimeInterval)dt;

@end
