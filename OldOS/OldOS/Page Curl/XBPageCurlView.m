//
//  XBPageCurlView.m
//  XBPageCurl
//
//  Created by xiss burg on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "XBPageCurlView.h"
#import "CGPointAdditions.h"

#define kDuration 0.3
#define CLAMP(x, a, b) MAX(a, MIN(x, b))

@interface XBPageCurlView ()

@property (nonatomic, assign) CGFloat cylinderAngle;
@property (nonatomic, assign) CGPoint startPickingPosition;
@property (nonatomic, strong) NSMutableArray *snappingPointArray;

@end

@implementation XBPageCurlView

@dynamic cylinderAngle;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.snappingPointArray = [[NSMutableArray alloc] init];
        self.snappingEnabled = NO;
        self.minimumCylinderAngle = -FLT_MAX;
        self.maximumCylinderAngle = FLT_MAX;
    }
    return self;
}

#pragma mark - Properties

- (NSArray *)snappingPoints
{
    return [self.snappingPointArray copy];
}

#pragma mark - Methods

- (void)addSnappingPoint:(XBSnappingPoint *)snappingPoint
{
    [self.snappingPointArray addObject:snappingPoint];
}

- (void)addSnappingPointsFromArray:(NSArray *)snappingPoints
{
    [self.snappingPointArray addObjectsFromArray:snappingPoints];
}

- (void)removeSnappingPoint:(XBSnappingPoint *)snappingPoint
{
    [self.snappingPointArray removeObject:snappingPoint];
}

- (void)removeAllSnappingPoints
{
    [self.snappingPointArray removeAllObjects];
}

- (void)updateCylinderStateWithPoint:(CGPoint)p animated:(BOOL)animated
{
    CGPoint v = CGPointSub(p, self.startPickingPosition);
    CGFloat l = CGPointLength(v);
    
    if (fabs(l) < FLT_EPSILON) {
        return;
    }
    
    CGFloat r = 16 + l/8;
    CGFloat d = 0; // Displacement of the cylinder position along the segment with direction v starting at startPickingPosition
    CGFloat quarterDistance = (M_PI_2 - 1)*r; // Distance ran by the finger to make the cylinder perform a quarter turn
    
    if (l < quarterDistance) {
        d = (l/quarterDistance)*(M_PI_2*r);
    }
    else if (l < M_PI*r) {
        d = (((l - quarterDistance)/(M_PI*r - quarterDistance)) + 1)*(M_PI_2*r);
    }
    else {
        d = M_PI*r + (l - M_PI*r)/2;
    }
    
    CGPoint vn = CGPointMul(v, 1.f/l); //Normalized
    CGPoint c = CGPointAdd(self.startPickingPosition, CGPointMul(vn, d));
    CGFloat angle = atan2f(-vn.x, vn.y);
    
    NSTimeInterval duration = animated? kDuration: 0;
    CGFloat a = CLAMP(angle, self.minimumCylinderAngle, self.maximumCylinderAngle);
    [self setCylinderPosition:c cylinderAngle:a cylinderRadius:r animatedWithDuration:duration];
}

- (void)touchBeganAtPoint:(CGPoint)p
{
    CGPoint v = CGPointMake(cosf(self.cylinderAngle), sinf(self.cylinderAngle));
    CGPoint vp = CGPointRotateCW(v);
    CGPoint ex = CGPointMul(vp, 12345.6);
    CGPoint p0 = CGPointSub(p, ex);
    CGPoint p1 = CGPointAdd(p, ex);
    
    CGPoint q[] = {
        //CGPointMake(0, 0), CGPointMake(self.bounds.size.width, 0),
        CGPointMake(0, 0), CGPointMake(0, self.bounds.size.height),
        //CGPointMake(0, self.bounds.size.height), CGPointMake(self.bounds.size.width, self.bounds.size.height),
        CGPointMake(self.bounds.size.width, 0), CGPointMake(self.bounds.size.width, self.bounds.size.height)
    };
    CGPoint x[2];
    
    for (int i = 0; i < 2; ++i) {
        if (!CGPointIntersectSegments(p0, p1, q[i*2], q[i*2 + 1], &x[i])) {
            x[i] = CGPointMake(12345.6, -12345.6);
        }
    }
    
    CGFloat d = 123456.7;
    for (int i = 0; i < 2; ++i) {
        CGFloat dd = CGPointLengthSq(CGPointSub(x[i], p));
        if (dd < d) {
            d = dd;
            self.startPickingPosition = x[i];
        }
    }
    
    [self updateCylinderStateWithPoint:p animated:YES];
}

- (void)touchMovedToPoint:(CGPoint)p
{
    [self updateCylinderStateWithPoint:p animated:NO];
}

- (void)touchEndedAtPoint:(CGPoint)p
{
    if (self.snappingEnabled && self.snappingPointArray.count > 0) {
        XBSnappingPoint *closestSnappingPoint = nil;
        CGFloat d = FLT_MAX;
        CGPoint v = CGPointMake(cosf(self.cylinderAngle), sinf(self.cylinderAngle));
        //Find the snapping point closest to the cylinder axis
        for (XBSnappingPoint *snappingPoint in self.snappingPointArray) {
            //Compute the distance between the snappingPoint.position and the cylinder axis weighted by the snapping point weight
            CGFloat weightedSquareDistance = CGPointToLineDistance(snappingPoint.position, self.cylinderPosition, v) / snappingPoint.weight;
            if (weightedSquareDistance < d) {
                closestSnappingPoint = snappingPoint;
                d = weightedSquareDistance;
            }
        }
        
        NSAssert(closestSnappingPoint != nil, @"There is always a closest point in a non-empty set of points hence closestSnappingPoint should not be nil.");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:XBPageCurlViewWillSnapToPointNotification object:self userInfo:@{kXBSnappingPointKey: closestSnappingPoint}];
        
        __weak XBPageCurlView *weakSelf = self;
        CGFloat angle = CLAMP(closestSnappingPoint.angle, self.minimumCylinderAngle, self.maximumCylinderAngle);
        [self setCylinderPosition:closestSnappingPoint.position cylinderAngle:angle cylinderRadius:closestSnappingPoint.radius animatedWithDuration:kDuration completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:XBPageCurlViewDidSnapToPointNotification object:weakSelf userInfo:@{kXBSnappingPointKey: closestSnappingPoint}];
        }];
    }
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    [self touchBeganAtPoint:p];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:self];
    [self touchMovedToPoint:p];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:self];
    [self touchEndedAtPoint:p];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

@end

#pragma mark - Notifications

NSString *const XBPageCurlViewWillSnapToPointNotification = @"XBPageCurlViewWillSnapToPointNotification";
NSString *const XBPageCurlViewDidSnapToPointNotification = @"XBPageCurlViewDidSnapToPointNotification";
NSString *const kXBSnappingPointKey = @"XBSnappingPointKey";
