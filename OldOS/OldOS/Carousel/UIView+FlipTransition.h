//
//  UIView+FlipViews.h
//  ViewTransitionTest
//
//  Created by Andrea Ottolina on 10/08/2011.
//  Copyright 2011 Pixelinlove ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIView (UIView_FlipTransition)

+ (void)flipTransitionFromView:(UIView *)firstView toView:(UIView *)secondView duration:(float)aDuration completion:(void (^)(BOOL finished))completion;

@end
