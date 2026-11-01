//
//  XBSnappingPoint.m
//  XBPageCurl
//
//  Created by xiss burg on 12/26/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "XBSnappingPoint.h"

@implementation XBSnappingPoint

- (id)init
{
    return [self initWithPosition:CGPointZero angle:0 radius:0 weight:1];
}

- (id)initWithPosition:(CGPoint)position angle:(CGFloat)angle radius:(CGFloat)radius
{
    return [self initWithPosition:position angle:angle radius:radius weight:1];
}

- (id)initWithPosition:(CGPoint)position angle:(CGFloat)angle radius:(CGFloat)radius weight:(CGFloat)weight
{
    self = [super init];
    if (self) {
        self.position = position;
        self.angle = angle;
        self.radius = radius;
        self.weight = weight;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: 0x%p> {\n\tposition = %@,\n\tangle = %f,\n\tradius = %f,\n\ttag = %d\n}", NSStringFromClass([self class]), self, NSStringFromCGPoint(self.position), self.angle, self.radius, self.tag];
}

@end
