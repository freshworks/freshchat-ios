//
//  FDNotificationBanner.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDNotificationBanner.h"
#import "HLChannel.h"
#import "FDCell.h"
#import <AudioToolbox/AudioServices.h>
#import "FDSecureStore.h"
#import "HLLocalization.h"
#import "HLTheme.h"

#define systemSoundID 1315

@interface FDNotificationBanner ()

@property (nonatomic, strong) HLTheme *theme;
@property (nonatomic, strong) NSLayoutConstraint *bannerTopConstraint;
@property (nonatomic, strong, readwrite) HLChannel *currentChannel;

@end

@implementation FDNotificationBanner

+ (instancetype)sharedInstance{
    static FDNotificationBanner *banner = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        banner = [[self alloc]init];
    });
    return banner;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        [self setSubViews];
    }
    return self;
}

-(void)setMessage:(NSString *)message{
    if (message && ![message isKindOfClass:[NSNull class]]) {
        self.messageLabel.text = message;
    }else{
        self.messageLabel.text = HLLocalizedString(LOC_DEFAULT_NOTIFICATION_MESSAGE);
    }
}

-(void)setSubViews{
    self.userInteractionEnabled = YES;
    

    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerTapped:)];
    [self addGestureRecognizer:singleFingerTap];
    
    self.titleLabel = [[UILabel alloc] init];
    [self.titleLabel setNumberOfLines:2];
    [self.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    self.titleLabel.font = [self.theme notificationTitleFont];
    self.titleLabel.textColor = [self.theme notificationTitleTextColor];
    
    self.messageLabel = [[UILabel alloc] init];
    [self.messageLabel setNumberOfLines:2];
    [self.messageLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    self.messageLabel.font = [self.theme notificationMessageFont];
    self.messageLabel.textColor = [self.theme notificationMessageTextColor];

    self.imgView=[[UIImageView alloc] init];
    [self.imgView.layer setMasksToBounds:YES];
    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIButton *closeButton = [[UIButton alloc] init];
    [closeButton setBackgroundImage:[self.theme getImageWithKey:IMAGE_NOTIFICATION_CANCEL_ICON] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissBanner:) forControlEvents:UIControlEventTouchUpInside];

    [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self addSubview:self.titleLabel];
    [self addSubview:self.messageLabel];
    [self addSubview:self.imgView];
    [self addSubview:closeButton];
    
    NSDictionary *views = @{@"banner" : self, @"title" : self.titleLabel,
                            @"message" : self.messageLabel, @"imgView" : self.imgView, @"closeButton" : closeButton};
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.imgView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imgView(50)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imgView(50)]-[title]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[closeButton(20)]-15-|" options:0 metrics:nil views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-5-[message]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imgView]-[message]-[closeButton]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[closeButton(20)]" options:0 metrics:nil views:views]];
    
    self.backgroundColor = [self.theme notificationBackgroundColor];
    
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self];
    
    self.frame = CGRectMake(0, -NOTIFICATION_BANNER_HEIGHT, currentWindow.frame.size.width, NOTIFICATION_BANNER_HEIGHT);
    self.hidden = YES;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    self.layer.borderWidth = 0.6;
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
    self.imgView.layer.masksToBounds = YES;
}

-(void)displayBannerWithChannel:(HLChannel *)channel{
    
    [[[[UIApplication sharedApplication] delegate] window] setWindowLevel:UIWindowLevelStatusBar+1];
    
    self.currentChannel = channel;
    
    if (!TARGET_IPHONE_SIMULATOR) {
        FDSecureStore *store = [FDSecureStore sharedInstance];
        BOOL isNotificationSoundEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_NOTIFICATION_SOUND_ENABLED];
        if(isNotificationSoundEnabled){
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            AudioServicesPlaySystemSound(systemSoundID);
        }
    }

    self.titleLabel.text = channel.name;
    
    if (channel.icon) {
        self.imgView.image = [UIImage imageWithData:channel.icon];
    }else{
        UIImage *placeholderImage = [FDCell generateImageForLabel:channel.name];
        self.imgView.image = placeholderImage;
    }
    
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow bringSubviewToFront:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.hidden = NO;
        CGRect myFrame = self.frame;
        myFrame.origin.y = 0;
        self.frame = myFrame;
    }];
    
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
}

-(void)bannerTapped:(id)sender{
    [self.delegate notificationBanner:self bannerTapped:sender];
    [self dismissBanner:nil];
}

@end