//
//  XBAnimationManager.m
//  XBPageCurl
//
//  Created by xiss burg on 9/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "XBAnimationManager.h"
#import "XBAnimation.h"

@interface XBAnimationManager ()

@property (nonatomic, strong) NSMutableDictionary *animations;
@property (nonatomic, strong) NSMutableArray *animationsToRemove;
@property (nonatomic, assign) BOOL updateLock;

@end

@implementation XBAnimationManager

- (id)init
{
    self = [super init];
    if (self) {
        self.animations = [[NSMutableDictionary alloc] init];
        self.animationsToRemove = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - Methods

- (void)runAnimation:(XBAnimation *)animation
{
    self.animations[animation.name] = animation;
}

- (void)stopAnimation:(XBAnimation *)animation
{
    [self stopAnimationNamed:animation.name];
}

- (void)stopAnimationNamed:(NSString *)name
{
    if (self.updateLock) {
        [self.animationsToRemove addObject:name];
    }
    else {
        [self.animations removeObjectForKey:name];
    }
}

- (void)stopAllAnimations
{
    if (self.updateLock) {
        [self.animationsToRemove addObjectsFromArray:[self.animations allKeys]];
    }
    else {
        [self.animations removeAllObjects];
    }
}

- (void)update:(double)dt
{
    //Step all animations
    NSMutableArray *finishedAnimationKeys = [NSMutableArray array];//animations to be removed
    
    self.updateLock = YES;
    [self.animations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        XBAnimation *animation = (XBAnimation *)obj;
        if ([animation step:dt] == NO) {
            [finishedAnimationKeys addObject:key];
        }
    }];
    self.updateLock = NO;
    
    [self.animations removeObjectsForKeys:finishedAnimationKeys];
    [self.animations removeObjectsForKeys:self.animationsToRemove];
    [self.animationsToRemove removeAllObjects];
}

@end
