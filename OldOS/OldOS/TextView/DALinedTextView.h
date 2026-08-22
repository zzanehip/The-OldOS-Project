//
//  DALinedTextView.h
//  DALinedTextView
//

#import <UIKit/UIKit.h>

@interface DALinedTextView : UITextView

@property (nonatomic, strong) UIColor *horizontalLineColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *verticalLineColor UI_APPEARANCE_SELECTOR;

@property (nonatomic) UIEdgeInsets margins UI_APPEARANCE_SELECTOR;

@end
