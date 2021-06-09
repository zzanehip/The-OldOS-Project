//
//  XBCurlView.h
//  XBPageCurl
//
//  Created by xiss burg on 8/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "XBAnimation.h"
#import "XBAnimationManager.h"

/**
 * A view that renders a curled version of an image or a UIView instance using OpenGL.
 */
@interface XBCurlView : UIView 

@property (nonatomic, readonly) BOOL antialiasing;
@property (nonatomic, assign) BOOL pageOpaque; // Whether the page texture is opaque
@property (nonatomic, readonly) NSUInteger horizontalResolution; //Number of colums of rectangles
@property (nonatomic, readonly) NSUInteger verticalResolution; //Number of rows..
@property (nonatomic, assign) CGPoint cylinderPosition;
@property (nonatomic, assign) CGFloat cylinderAngle;
@property (nonatomic, assign) CGFloat cylinderRadius;

/**
 * Initializers
 * The horizontalResolution: and verticalResolution arguments determine how many rows and colums of quads (two triangles) the 3D
 * page mesh should have. By default, it has 1/10th of the view size, which is good enough for most situations. You should only 
 * use a higher resolution if your cylinder radius goes under ~20.
 */
- (id)initWithFrame:(CGRect)frame;
- (id)initWithFrame:(CGRect)frame antialiasing:(BOOL)antialiasing;
- (id)initWithFrame:(CGRect)frame horizontalResolution:(NSUInteger)horizontalResolution verticalResolution:(NSUInteger)verticalResolution antialiasing:(BOOL)antialiasing;

/**
 * The following set of methods allows you to set the cylinder properties, namely, the (x,y) position of its axis,
 * the angle of its axis and its radius. The position is specified in UIKit's coordinate system: origin at the top
 * left corner, x increases towards the right and y increases towards the bottom. In the zoomed-out two-page 
 * configuration though, the origin is at the center horizontally and at the top vertically, but the cylinder axis
 * cant pass the central, vertical axis (which holds the page in place). The angle is specified in radians and
 * increases in counter clockwise direction. The radius allows you to control the curvature of the curled section
 * of the page.
 */
- (void)setCylinderPosition:(CGPoint)cylinderPosition animatedWithDuration:(NSTimeInterval)duration;
- (void)setCylinderPosition:(CGPoint)cylinderPosition animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;
- (void)setCylinderPosition:(CGPoint)cylinderPosition animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion;
- (void)setCylinderAngle:(CGFloat)cylinderAngle animatedWithDuration:(NSTimeInterval)duration;
- (void)setCylinderAngle:(CGFloat)cylinderAngle animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;
- (void)setCylinderAngle:(CGFloat)cylinderAngle animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion;
- (void)setCylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration;
- (void)setCylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;
- (void)setCylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion;
- (void)setCylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration;
- (void)setCylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;
- (void)setCylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration interpolator:(double (^)(double t))interpolator completion:(void (^)(void))completion;

/**
 * Starts/stops the CADisplayLink that updates and redraws everything in this view.
 * This should be called manually whenever you are going to present this view and change its properties 
 * (for example, before adding it as subview and changing the cylinder properties). stopAnimating should
 * be called whenever you don't need to animate this anymore (for example, after removing it from superview),
 * otherwise your XBCurlView instance won't be deallocated because, internally, the CADisplayLink retains its
 * target which is the XBCurlView instance itself. So, if you call startAnimating, you must call stopAnimating
 * later.
 */
- (void)startAnimating;
- (void)stopAnimating;

- (void)drawImageOnFrontOfPage:(UIImage *)image;
- (void)drawViewOnFrontOfPage:(UIView *)view;

- (void)drawImageOnBackOfPage:(UIImage *)image;
- (void)drawViewOnBackOfPage:(UIView *)view;

/**
 * The nextPage is a page that is rendered behind the curled page. You can set the XBCurlView opaque property
 * to NO in order to see whatever view is behind the XBCurlView through the pixels not filled by the curled page.
 * You can also set it to YES and draw something in a texture to be rendered as the nextPage, using one of the
 * methods below. Depending on your configuration and needs, it may be more efficient to draw just a texture than
 * a full view. Also, they say a view backed by an CAEAGLLayer should be opaque for a better performance.
 */
- (void)drawImageOnNextPage:(UIImage *)image;
- (void)drawViewOnNextPage:(UIView *)view;

/**
 * The following methods allow you to curl a view without much code. Just choose the cylinder properties and go. You can uncurl 
 * it afterwards. It adds and removes itself to/from the target view automatically.
 */
- (void)curlView:(UIView *)view cylinderPosition:(CGPoint)cylinderPosition cylinderAngle:(CGFloat)cylinderAngle cylinderRadius:(CGFloat)cylinderRadius animatedWithDuration:(NSTimeInterval)duration;
- (void)uncurlAnimatedWithDuration:(NSTimeInterval)duration;
- (void)uncurlAnimatedWithDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 * Returns an UIImage instance with the current contents of the main framebuffer.
 */
- (UIImage *)imageFromFramebuffer;

/**
 * Returns an UIImage instance with the current contents of the main framebuffer and a background view that can
 * be seen through the transparent regions of the page.
 */
- (UIImage *)imageFromFramebufferWithBackgroundView:(UIView *)backgroundView;

@end
