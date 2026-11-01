//
//  UIView+FlipViews.m
//  ViewTransitionTest
//
//  Created by Andrea Ottolina on 10/08/2011.
//  Copyright 2011 Pixelinlove ltd. All rights reserved.
//

#import "UIView+FlipTransition.h"

@implementation UIView (UIView_FlipTransition)

+ (void)flipTransitionFromView:(UIView *)firstView toView:(UIView *)secondView duration:(float)aDuration completion:(void (^)(BOOL finished))completion
{
	firstView.layer.doubleSided = NO;
	secondView.layer.doubleSided = NO;
	
	firstView.layer.zPosition = firstView.layer.bounds.size.width / 2;
	secondView.layer.zPosition = secondView.layer.bounds.size.width / 2;
	
	CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0f/500.0f;
	
	CGAffineTransform translation = CGAffineTransformMakeTranslation(secondView.layer.position.x - firstView.layer.position.x, secondView.layer.position.y - firstView.layer.position.y);
	
	CGAffineTransform scaling = CGAffineTransformMakeScale(secondView.bounds.size.width / firstView.bounds.size.width, secondView.bounds.size.height / firstView.bounds.size.height);
	
	CATransform3D rotation = CATransform3DRotate(transform, -0.999 * M_PI, 0.0f, 1.0f, 0.0f);
	
	CATransform3D firstViewTransform = CATransform3DConcat(rotation, CATransform3DMakeAffineTransform(CGAffineTransformConcat(scaling, translation)));
	
	CATransform3D secondViewTransform = CATransform3DConcat(CATransform3DInvert(rotation), CATransform3DMakeAffineTransform(CGAffineTransformConcat(CGAffineTransformInvert(scaling), CGAffineTransformInvert(translation))));
	
	if (secondView.hidden)
	{
		secondView.layer.transform = secondViewTransform;
	}
	
	firstView.hidden = NO;
	secondView.hidden = NO;
	
	CATransform3D firstToTransform = firstViewTransform;
    CATransform3D secondToTransform = CATransform3DIdentity;
	BOOL firstViewWillHide = YES;
	
    if (CATransform3DIsIdentity(secondView.layer.transform))
    {
		firstToTransform = CATransform3DIdentity;
        secondToTransform = secondViewTransform;
		firstViewWillHide = NO;
    }
	
    [UIView animateWithDuration:aDuration
                     animations:^(void){
                         firstView.layer.transform = firstToTransform;
                         secondView.layer.transform = secondToTransform;
                     }
                     completion:^(BOOL finished) {
						 firstView.hidden = firstViewWillHide;
						 secondView.hidden = !firstView.hidden;
						 if (completion)
							 completion(finished);
					 }];
}

@end
