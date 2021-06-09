//
//  XBPageCurlView.h
//  XBPageCurl
//
//  Created by xiss burg on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBCurlView.h"
#import "XBSnappingPoint.h"

/**
 * XBPageCurlView
 * Adds user interaction to XBCurlView. Allows the user to drag the page with his finger and also supports the placement of 
 * snapping points that the cylinder will stick to after the user releases his finger off the screen.
 */
@interface XBPageCurlView : XBCurlView

@property (nonatomic, assign) BOOL snappingEnabled;
@property (nonatomic, assign) CGFloat minimumCylinderAngle;
@property (nonatomic, assign) CGFloat maximumCylinderAngle;
@property (nonatomic, readonly) NSArray *snappingPoints;

- (void)touchBeganAtPoint:(CGPoint)p;
- (void)touchMovedToPoint:(CGPoint)p;
- (void)touchEndedAtPoint:(CGPoint)p;
- (void)addSnappingPoint:(XBSnappingPoint *)snappingPoint;
- (void)addSnappingPointsFromArray:(NSArray *)snappingPoints;
- (void)removeSnappingPoint:(XBSnappingPoint *)snappingPoint;
- (void)removeAllSnappingPoints;

@end

/**
 * Every XBPageCurlView instance posts these notifications before and after the cylinder snaps to a point (if snapping is enabled for that
 * view). The object of the notification is the XBPageCurlView instance itself and the snapping point instance is under the 
 * kXBSnappingPointKey key in the userInfo dictionary.
 */
extern NSString *const XBPageCurlViewWillSnapToPointNotification;
extern NSString *const XBPageCurlViewDidSnapToPointNotification;
extern NSString *const kXBSnappingPointKey;