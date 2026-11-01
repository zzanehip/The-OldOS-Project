//
//  CGPointAdditions.c
//  XBPageCurl
//
//  Created by xiss burg on 1/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "CGPointAdditions.h"
#include <math.h>

#define EPSILON 0.00000001

CGPoint CGPointAdd(CGPoint p0, CGPoint p1)
{
    return CGPointMake(p0.x + p1.x, p0.y + p1.y);
}

CGPoint CGPointSub(CGPoint p0, CGPoint p1)
{
    return CGPointMake(p0.x - p1.x, p0.y - p1.y);
}

CGFloat CGPointDot(CGPoint p0, CGPoint p1)
{
    return p0.x*p1.x + p0.y*p1.y;
}

CGFloat CGPointLength(CGPoint p)
{
    return sqrtf(CGPointLengthSq(p));
}

CGFloat CGPointLengthSq(CGPoint p)
{
    return CGPointDot(p, p);
}

CGPoint CGPointMul(CGPoint p, CGFloat s)
{
    return CGPointMake(p.x*s, p.y*s);
}

CGFloat CGPointToLineDistance(CGPoint p, CGPoint q, CGPoint v)
{
    return  sqrtf(CGPointToLineDistanceSq(p, q, v));
}

CGFloat CGPointToLineDistanceSq(CGPoint p, CGPoint q, CGPoint v)
{
    CGPoint w = CGPointSub(p, q);
    CGFloat s = CGPointDot(w, v)/CGPointDot(v, v);
    CGPoint r = CGPointAdd(q, CGPointMul(v, s));
    CGFloat dSq = CGPointLengthSq(CGPointSub(r, p));
    return dSq;
}

CGPoint CGPointRotateCCW(CGPoint p)
{
    return CGPointMake(-p.y, p.x);
}

CGPoint CGPointRotateCW(CGPoint p)
{
    return CGPointMake(p.y, -p.x);
}

bool CGPointIntersectSegments(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1, CGPoint *x)
{
    CGPoint u = CGPointSub(p1, p0);
    CGPoint v = CGPointSub(q1, q0);
    CGPoint w = CGPointSub(q0, p0);
    CGPoint up = CGPointRotateCCW(u);
    CGPoint vp = CGPointRotateCCW(v);
    CGFloat uvp = CGPointDot(u, vp);
    
    if (fabs(uvp) < EPSILON) { // Parallel lines
        return false;
    }
    
    CGFloat uvpInv = 1.f/uvp;
    CGFloat wvp = CGPointDot(w, vp);
    CGFloat wup = CGPointDot(w, up);
    CGFloat s = wvp*uvpInv;
    CGFloat t = wup*uvpInv;
    
    if (s < 0 || s > 1 || t < 0 || t > 1) {
        return false;
    }
    
    if (x != NULL) {
        *x = CGPointAdd(p0, CGPointMul(u, s));
    }
    
    return true;
}
