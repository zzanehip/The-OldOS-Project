//
//  XBPageDragView.m
//  XBPageCurl
//
//  Created by xiss burg on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBPageDragView.h"

@interface XBPageDragView ()

@property (nonatomic, assign) BOOL pageIsCurled;
@property (nonatomic, strong) XBPageCurlView *pageCurlView;

@end

@implementation XBPageDragView

@synthesize cornerSnappingPoint = _cornerSnappingPoint;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.pageCurlView stopAnimating];
}

#pragma mark - Properties

- (void)setViewToCurl:(UIView *)viewToCurl
{
    if (viewToCurl == _viewToCurl) {
        return;
    }
    
    _viewToCurl = viewToCurl;
    
    [self.pageCurlView removeFromSuperview];
    self.pageCurlView = nil;
    
    if (_viewToCurl == nil) {
        return;
    }
    
    [self refreshPageCurlView];
}

- (XBSnappingPoint *)cornerSnappingPoint
{
    if (_cornerSnappingPoint == nil) {
        _cornerSnappingPoint = [[XBSnappingPoint alloc] initWithPosition:CGPointMake(self.viewToCurl.frame.size.width, self.viewToCurl.frame.size.height) angle:3*M_PI_4 radius:30];
    }
    return _cornerSnappingPoint;
}

#pragma mark - Methods

- (void)uncurlPageAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    NSTimeInterval duration = animated? 0.3: 0;
    __weak XBPageDragView *weakSelf = self;
    [self.pageCurlView setCylinderPosition:self.cornerSnappingPoint.position cylinderAngle:self.cornerSnappingPoint.angle cylinderRadius:self.cornerSnappingPoint.radius animatedWithDuration:duration completion:^{
        weakSelf.hidden = NO;
        weakSelf.pageIsCurled= NO;
        weakSelf.viewToCurl.hidden = NO;
        [weakSelf.pageCurlView removeFromSuperview];
        [weakSelf.pageCurlView stopAnimating];
        if (completion) {
            completion();
        }
    }];
}

- (void)refreshPageCurlView
{
    XBPageCurlView *pageCurlView = [[XBPageCurlView alloc] initWithFrame:self.viewToCurl.frame];
    pageCurlView.pageOpaque = YES;
    pageCurlView.opaque = NO;
    pageCurlView.snappingEnabled = YES;
    [pageCurlView drawViewOnFrontOfPage:self.viewToCurl];
    
    if (self.pageCurlView != nil) {
        pageCurlView.maximumCylinderAngle = self.pageCurlView.maximumCylinderAngle;
        pageCurlView.minimumCylinderAngle = self.pageCurlView.minimumCylinderAngle;
        [pageCurlView addSnappingPointsFromArray:self.pageCurlView.snappingPoints];
        
        if (![self.pageCurlView.snappingPoints containsObject:self.cornerSnappingPoint]) {
            [pageCurlView addSnappingPoint:self.cornerSnappingPoint];
        }
        [self.pageCurlView removeFromSuperview];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:XBPageCurlViewDidSnapToPointNotification object:self.pageCurlView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageCurlViewDidSnapToPointNotification:) name:XBPageCurlViewDidSnapToPointNotification object:pageCurlView];
    self.pageCurlView = pageCurlView;
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
    
    if (CGRectContainsPoint(self.frame, touchLocation)) {
        self.hidden = YES;
        _pageIsCurled = YES;
        [self.pageCurlView drawViewOnFrontOfPage:self.viewToCurl];
        self.pageCurlView.cylinderPosition = self.cornerSnappingPoint.position;
        self.pageCurlView.cylinderAngle = self.cornerSnappingPoint.angle;
        self.pageCurlView.cylinderRadius = self.cornerSnappingPoint.radius;
        [self.pageCurlView touchBeganAtPoint:touchLocation];
        [self.viewToCurl.superview addSubview:self.pageCurlView];
        self.viewToCurl.hidden = YES;
        [self.pageCurlView startAnimating];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.pageIsCurled) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
        [self.pageCurlView touchMovedToPoint:touchLocation];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.pageIsCurled) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
        [self.pageCurlView touchEndedAtPoint:touchLocation];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.pageIsCurled) {
        UITouch *touch = [touches anyObject];
        CGPoint touchLocation = [touch locationInView:self.viewToCurl.superview];
        [self.pageCurlView touchEndedAtPoint:touchLocation];
    }
}

#pragma mark - Notifications

- (void)pageCurlViewDidSnapToPointNotification:(NSNotification *)notification
{
    XBSnappingPoint *snappingPoint = notification.userInfo[kXBSnappingPointKey];
    if (snappingPoint == self.cornerSnappingPoint) {
        self.hidden = NO;
        _pageIsCurled = NO;
        self.viewToCurl.hidden = NO;
        [self.pageCurlView removeFromSuperview];
        [self.pageCurlView stopAnimating];
    }
}

@end
