//
//  XBSnappingPoint.h
//  XBPageCurl
//
//  Created by xiss burg on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface XBSnappingPoint : NSObject

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGFloat angle;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat weight;
@property (nonatomic, assign) int tag;

- (id)initWithPosition:(CGPoint)position angle:(CGFloat)angle radius:(CGFloat)radius;
- (id)initWithPosition:(CGPoint)position angle:(CGFloat)angle radius:(CGFloat)radius weight:(CGFloat)weight;

@end
