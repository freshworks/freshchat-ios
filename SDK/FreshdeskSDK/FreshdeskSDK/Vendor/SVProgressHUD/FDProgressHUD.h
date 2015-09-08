//
//  FDProgressHUD.h
//
//  Created by Sam Vermette on 27.03.11.
//  Copyright 2011 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/FDProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * const FDProgressHUDDidReceiveTouchEventNotification;
extern NSString * const FDProgressHUDWillDisappearNotification;
extern NSString * const FDProgressHUDDidDisappearNotification;
extern NSString * const FDProgressHUDWillAppearNotification;
extern NSString * const FDProgressHUDDidAppearNotification;

extern NSString * const FDProgressHUDStatusUserInfoKey;

enum {
    FDProgressHUDMaskTypeNone = 1, // allow user interactions while HUD is displayed
    FDProgressHUDMaskTypeClear, // don't allow
    FDProgressHUDMaskTypeBlack, // don't allow and dim the UI in the back of the HUD
    FDProgressHUDMaskTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

typedef NSUInteger FDProgressHUDMaskType;

@interface FDProgressHUD : UIView

#pragma mark - Customization

+ (void)setBackgroundColor:(UIColor*)color; // default is [UIColor whiteColor]
+ (void)setForegroundColor:(UIColor*)color; // default is [UIColor blackColor]
+ (void)setRingThickness:(CGFloat)width; // default is 4 pt
+ (void)setFont:(UIFont*)font; // default is [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
+ (void)setSuccessImage:(UIImage*)image; // default is bundled success image from Glyphish
+ (void)setErrorImage:(UIImage*)image; // default is bundled error image from Glyphish

#pragma mark - Show Methods

+ (void)show;
+ (void)showWithMaskType:(FDProgressHUDMaskType)maskType;
+ (void)showWithStatus:(NSString*)status;
+ (void)showWithStatus:(NSString*)status maskType:(FDProgressHUDMaskType)maskType;

+ (void)showProgress:(float)progress;
+ (void)showProgress:(float)progress status:(NSString*)status;
+ (void)showProgress:(float)progress status:(NSString*)status maskType:(FDProgressHUDMaskType)maskType;

+ (void)setStatus:(NSString*)string; // change the HUD loading status while it's showing

// stops the activity indicator, shows a glyph + status, and dismisses HUD 1s later
+ (void)showSuccessWithStatus:(NSString*)string;
+ (void)showErrorWithStatus:(NSString *)string;
+ (void)showImage:(UIImage*)image status:(NSString*)status; // use 28x28 white pngs

+ (void)setOffsetFromCenter:(UIOffset)offset;
+ (void)resetOffsetFromCenter;

+ (void)popActivity;
+ (void)dismiss;

+ (BOOL)isVisible;

@end


@interface FDIndefiniteAnimatedView : UIView

@property (nonatomic, assign) CGFloat strokeThickness;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, strong) UIColor *strokeColor;

@end