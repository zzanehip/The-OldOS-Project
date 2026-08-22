//
//  CGPointAdditions.h
//  XBPageCurl
//
//  Created by xiss burg on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef XBPageCurl_CGPointAdditions_h
#define XBPageCurl_CGPointAdditions_h

#include <CoreGraphics/CGGeometry.h>

/**
 * Adds two CGPoints as if they were vectors.
 */
CGPoint CGPointAdd(CGPoint p0, CGPoint p1);

/**
 * Subtracts two CGPoint as if they were vectors.
 */
CGPoint CGPointSub(CGPoint p0, CGPoint p1);

/**
 * Returns the dot product of p0 and p1.
 */
CGFloat CGPointDot(CGPoint p0, CGPoint p1);

/**
 * Retuns the length of p.
 */
CGFloat CGPointLength(CGPoint p);

/**
 * Returns the squared length of p.
 */
CGFloat CGPointLengthSq(CGPoint p);

/**
 * Multiples p by the scalar s.
 */
CGPoint CGPointMul(CGPoint p, CGFloat s);

/**
 * Returns p rotated π/2 rad counter clockwise. Also known as perp operator.
 */
CGPoint CGPointRotateCCW(CGPoint p);

/**
 * Returns p rotated π/2 rad clockwise.
 */
CGPoint CGPointRotateCW(CGPoint p);

/**
 * Returns the distance between the point p and the line with direction v (not necessarily normalized) and containing the point q.
 */
CGFloat CGPointToLineDistance(CGPoint p, CGPoint q, CGPoint v);
CGFloat CGPointToLineDistanceSq(CGPoint p, CGPoint q, CGPoint v);

/**
 * Computes the intersect between the two segments p0 - p1 and q0 - q1. Returns whether the segments intersect or not.
 * To get the intersection point pass the pointer of a CGPoint in the x parameter.
 */
bool CGPointIntersectSegments(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1, CGPoint *x);

#endif
