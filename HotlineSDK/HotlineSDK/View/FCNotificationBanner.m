//
//  FDNotificationBanner.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCNotificationBanner.h"
#import "FCChannels.h"
#import "FCCell.h"
#import <AudioToolbox/AudioServices.h>
#import "FCSecureStore.h"
#import "FCLocalization.h"
#import "FCTheme.h"
#import "FCAutolayoutHelper.h"
#import "FCUtilities.h"
#import "FCAttributedText.h"

#define systemSoundID 1315
#define IPHONEX_STATUSBAR_HEIGHT 30

@interface FCNotificationBanner ()

@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (strong, nonatomic) UIView *contentEncloser;
@property (strong, nonatomic) UIView *contentView;
@property (nonatomic, strong) FCTheme *theme;
@property (nonatomic, strong) NSLayoutConstraint *bannerTopConstraint;
@property (nonatomic, strong, readwrite) FCChannels *currentChannel;
@property (strong, nonatomic) NSLayoutConstraint *encloserHeightConstraint;
@property (strong, nonatomic) UIView *iPhoneXStatusbarView;
@property (strong, nonatomic) NSLayoutConstraint *iPhoneXStatusbarHeightConstraint;
@property (strong, nonatomic) FCChannels *channel;

@end

@implementation FCNotificationBanner

+ (instancetype)sharedInstance{
    static FCNotificationBanner *banner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        banner = [[self alloc]init];
    });
    return banner;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.theme = [FCTheme sharedInstance];
        [self setSubViews];
        [self setView];
    }
    return self;
}

-(void) resetView {
    if (self) {
        if(self.iPhoneXStatusbarView) {
            [self.iPhoneXStatusbarView removeFromSuperview];
        }
        if(self.contentView) {
            [self.contentView removeFromSuperview];
        }
        self.theme = [FCTheme sharedInstance];
        [self setSubViews];
        [self setNeedsDisplay];
    }
}

-(void)setMessage:(NSString *)message inChannel:(FCChannels *)channel {
    self.currentChannel = channel;
    if (message && ![message isKindOfClass:[NSNull class]]) {
        if([FCUtilities containsHTMLContent:message]) {
            NSMutableAttributedString *str = [[FCAttributedText sharedInstance] getAttributedString:message];
            if(str == nil) {
                NSMutableAttributedString *content = [[FCAttributedText sharedInstance] addAttributedString:message withFont:[self.theme notificationTitleFont]];
                self.messageLabel.text = content.string;
            } else {
                self.messageLabel.text = str.string;
            }
        } else {
            self.messageLabel.text = message;
        }
    }else{
        self.messageLabel.text = HLLocalizedString(LOC_DEFAULT_NOTIFICATION_MESSAGE);
    }
}

-(void)setSubViews{
    self.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerTapped:)];
    [self addGestureRecognizer:singleFingerTap];
    
    self.iPhoneXStatusbarView=[[UIView alloc]init];
    self.iPhoneXStatusbarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.iPhoneXStatusbarView setBackgroundColor:[[FCTheme sharedInstance] notificationBackgroundColor]];
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.contentEncloser = [[UIView alloc]init];
    self.contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.titleLabel = [[UILabel alloc] init];
    [self.titleLabel setNumberOfLines:1];
    [self.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    self.titleLabel.font = [self.theme notificationTitleFont];
    self.titleLabel.textColor = [self.theme notificationTitleTextColor];
    
    self.messageLabel = [[UILabel alloc] init];
    [self.messageLabel setNumberOfLines:2];
    [self.messageLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    self.messageLabel.font = [self.theme notificationMessageFont];
    self.messageLabel.textColor = [self.theme notificationMessageTextColor];
    
    self.imgView=[[UIImageView alloc] init];
    self.imgView.backgroundColor = [self.theme notificationChannelIconBackgroundColor];
    [self.imgView.layer setMasksToBounds:YES];
    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self addSubview:self.iPhoneXStatusbarView];
    [self addSubview:self.contentView];
    
    UIButton *closeButton = [[UIButton alloc] init];
    [closeButton setBackgroundImage:[self.theme getImageValueWithKey:IMAGE_NOTIFICATION_CANCEL_ICON] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissBanner:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    [self.contentView addSubview:self.imgView];
    [self.contentView addSubview:closeButton];
    self.contentView.backgroundColor = [[FCTheme sharedInstance] notificationBackgroundColor];
    
    [self.contentView addSubview:self.contentEncloser];
    [self.contentEncloser addSubview:self.titleLabel];
    [self.contentEncloser addSubview:self.messageLabel];
    
    if([FCUtilities hasNotchDisplay]){
        if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
        {
            self.iPhoneXStatusbarHeightConstraint = [FCAutolayoutHelper setHeight:0 forView:self.iPhoneXStatusbarView inView:self];
        }
        else{
            self.iPhoneXStatusbarHeightConstraint = [FCAutolayoutHelper setHeight:IPHONEX_STATUSBAR_HEIGHT forView:self.iPhoneXStatusbarView inView:self];
        }
    }
    else{
        self.iPhoneXStatusbarHeightConstraint = [FCAutolayoutHelper setHeight:0 forView:self.iPhoneXStatusbarView inView:self];
    }
    
    NSDictionary *views = @{@"banner" : self, @"title" : self.titleLabel,
                            @"message" : self.messageLabel, @"imgView" : self.imgView, @"closeButton" : closeButton, @"contentEncloser" : self.contentEncloser, @"iPhoneXTopView": self.iPhoneXStatusbarView, @"contentView" : self.contentView};
    
    [FCAutolayoutHelper centerY:closeButton onView:self.contentView];
    
    [FCAutolayoutHelper centerY:self.imgView onView:self.contentView];
    
    [FCAutolayoutHelper centerY:self.contentEncloser onView:self.contentView];
    
    [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title][message]|" options:0 metrics:nil  views:views]];
    
    [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]|" options:0 metrics:nil  views:views]];
    [self.contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[message]|" options:0 metrics:nil  views:views]];
    
    
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imgView(50)]" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imgView(50)]-[contentEncloser]-[closeButton(22)]-|" options:0 metrics:nil views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[closeButton(22)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[iPhoneXTopView][contentView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[iPhoneXTopView]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:views]];
    

}

-(void) setView {
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self];
    
    self.frame = CGRectMake(0, -(NOTIFICATION_BANNER_HEIGHT+(float)self.iPhoneXStatusbarHeightConstraint.constant), currentWindow.frame.size.width, NOTIFICATION_BANNER_HEIGHT+(float)self.iPhoneXStatusbarHeightConstraint.constant);
    self.hidden = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = [self.theme notificationBackgroundColor];
}

- (void)orientationChanged:(NSNotification *)notification{
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void) adjustViewsForOrientation:(UIInterfaceOrientation) orientation {
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            //load the portrait view
            self.iPhoneXStatusbarHeightConstraint.constant = IPHONEX_STATUSBAR_HEIGHT;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            //load the landscape view
            self.iPhoneXStatusbarHeightConstraint.constant = 0;
        }
            break;
        case UIInterfaceOrientationUnknown:break;
    }
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.iPhoneXStatusbarHeightConstraint.constant+NOTIFICATION_BANNER_HEIGHT);
}

-(void)adjustPadding{
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    CGFloat titleHeight  = self.titleLabel.intrinsicContentSize.height;
    CGFloat messageHeight = self.messageLabel.intrinsicContentSize.height;
    self.encloserHeightConstraint = [FCAutolayoutHelper setHeight:(messageHeight+titleHeight) forView:self.contentEncloser inView:self.contentView];

}

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    self.layer.borderWidth = 0.6;
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
    self.imgView.layer.masksToBounds = YES;
    [self.imgView.layer setBorderColor:[[self.theme notificationChannelIconBorderColor]CGColor]];
    [self.imgView.layer setBorderWidth: 1.5];
}

-(void)displayBannerWithChannel:(FCChannels *)channel{
    
    [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelStatusBar+1];
    
    if([FCUtilities hasNotchDisplay]) {
        self.iPhoneXStatusbarHeightConstraint.constant = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) ? 0 : IPHONEX_STATUSBAR_HEIGHT;
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    }
    
    self.currentChannel = channel;
    
    if (!TARGET_IPHONE_SIMULATOR) {
        FCSecureStore *store = [FCSecureStore sharedInstance];
        BOOL isNotificationSoundEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED];
        if(isNotificationSoundEnabled){
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            AudioServicesPlaySystemSound(systemSoundID);
        }
    }
    
    self.titleLabel.text = channel.name;
    
    [FCUtilities loadImageAndPlaceholderBgWithUrl:channel.iconURL forView:self.imgView withColor:[[FCTheme sharedInstance] channelIconPlaceholderImageBackgroundColor] andName:channel.name];
    
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow bringSubviewToFront:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.hidden = NO;
        CGRect myFrame = self.frame;
        myFrame.size.height = self.iPhoneXStatusbarHeightConstraint.constant+NOTIFICATION_BANNER_HEIGHT;
        myFrame.origin.y = 0;
        self.frame = myFrame;
    }];
    [self adjustPadding];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissBanner:) object:nil];
        [self performSelector:@selector(dismissBanner:) withObject:nil afterDelay:5.0f];
    
}

-(void)dismissBanner:(id)sender{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect myFrame = self.frame;
        myFrame.origin.y = -NOTIFICATION_BANNER_HEIGHT;
        self.frame = myFrame;
        
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelNormal];
    } ];
    if([FCUtilities hasNotchDisplay]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
}

-(void)bannerTapped:(id)sender{
    [self.delegate notificationBanner:self bannerTapped:sender];
    [self dismissBanner:nil];
}

@end
