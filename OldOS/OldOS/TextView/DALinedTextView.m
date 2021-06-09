//
//  DALinedTextView.m
//  DALinedTextView
//

//Years ago, I built a Notes app and found this library "DALinedTextView." The chief reason I use it was as I struggled to properly get lines working. When I was building OldOS, I wondered if this could be of any use. And the answer is yes. Full credit goes to whomever built this great piece of work...still lives on years later. 

#import "DALinedTextView.h"

#define DEFAULT_HORIZONTAL_COLOR    [UIColor colorWithRed:78.0f/255.0f green:90.0f/255.0f blue:130.0f/255.0f alpha:0.4f]

@implementation DALinedTextView

+ (void)initialize
{
    if (self == [DALinedTextView class]) {
        id appearance = [self appearance];
        [appearance setContentMode:UIViewContentModeRedraw];
        [appearance setHorizontalLineColor:DEFAULT_HORIZONTAL_COLOR];
    }
}


#pragma mark - Superclass overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIFont *font = self.font;
        self.font = nil;
        self.font = font;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    UIScreen *screen = self.window.screen ?: [UIScreen mainScreen];
    CGFloat lineWidth = 3.0f / screen.scale;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, lineWidth);
    
    if (self.horizontalLineColor) {
        CGContextBeginPath(context);
        CGContextSetStrokeColorWithColor(context, self.horizontalLineColor.CGColor);
        CGFloat baseOffset = self.font.descender + 40;  //  original constant is 7.0f
        CGFloat screenScale = [UIScreen mainScreen].scale;
        CGFloat boundsX = self.bounds.origin.x;
        CGFloat boundsWidth = self.bounds.size.width;

        CGFloat kFactor = 0.0;
        
        BOOL isAtLeast7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
        if(isAtLeast7) {
            kFactor = self.font.pointSize * 0.015; //Noteworthy -> slightly less
        }

        float realContentOffsetY = self.contentOffset.y - (self.contentOffset.y/self.font.lineHeight) * kFactor;
        NSInteger firstVisibleLine = MAX(1, (realContentOffsetY / self.font.lineHeight));
        NSInteger lastVisibleLine = ceilf((self.contentOffset.y + self.bounds.size.height) / self.font.lineHeight);
        for (NSInteger line = firstVisibleLine; line <= lastVisibleLine; ++line)
        {
            CGFloat linePointY = (baseOffset + ((self.font.lineHeight + kFactor) * line));
            CGFloat roundedLinePointY = roundf(linePointY * screenScale) / screenScale;
            CGContextMoveToPoint(context, boundsX, roundedLinePointY);
            CGContextAddLineToPoint(context, boundsWidth, roundedLinePointY);
        }
        CGContextClosePath(context);
        CGContextStrokePath(context);
    }
    
    if (self.verticalLineColor) {
        CGContextBeginPath(context);
        CGContextSetStrokeColorWithColor(context, self.verticalLineColor.CGColor);
        CGContextMoveToPoint(context, -lineWidth + self.textContainerInset.left, self.contentOffset.y);
        CGContextAddLineToPoint(context, -lineWidth + self.textContainerInset.left, self.contentOffset.y + self.bounds.size.height);
        CGContextClosePath(context);
        CGContextStrokePath(context);
    }
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
    [super setTextContainerInset:textContainerInset];
    [self setNeedsDisplay];
}


#pragma mark - Property methods

- (void)setHorizontalLineColor:(UIColor *)horizontalLineColor
{
    _horizontalLineColor = horizontalLineColor;
    [self setNeedsDisplay];
}

- (void)setVerticalLineColor:(UIColor *)verticalLineColor
{
    _verticalLineColor = verticalLineColor;
    [self setNeedsDisplay];
}

@end
