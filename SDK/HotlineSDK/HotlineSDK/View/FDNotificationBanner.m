//
//  FDNotificationBanner.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 07/01/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDNotificationBanner.h"
#import "HLChannel.h"
#import "FDChannelListViewCell.h"
#import <AudioToolbox/AudioServices.h>

@interface FDNotificationBanner ()

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSLayoutConstraint *bannerTopConstraint;

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
        [self setSubViews];
    }
    return self;
}


//TODO: Add theming
-(void)setSubViews{
    self.userInteractionEnabled = YES;
    

    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerTapped:)];
    [self addGestureRecognizer:singleFingerTap];
    
    self.title = [[UILabel alloc] init];
    [self.title setNumberOfLines:2];
    [self.title setLineBreakMode:NSLineBreakByTruncatingTail];
//    self.title.font = [self.theme tableViewCellDetailFont];
//    self.title.textColor = [self.theme tableViewCellDetailFontColor];
    
    self.message = [[UILabel alloc] init];
    [self.message setNumberOfLines:2];
    [self.message setLineBreakMode:NSLineBreakByTruncatingTail];
//    self.message.font = [self.theme tableViewCellDetailFont];
//    self.message.textColor = [self.theme tableViewCellDetailFontColor];

    self.imgView=[[UIImageView alloc] init];
//    self.imgView.backgroundColor=[self.theme tableViewCellImageBackgroundColor];
    [self.imgView.layer setMasksToBounds:YES];
    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    

    [self.title setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.message setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.imgView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self addSubview:self.title];
    [self addSubview:self.message];
    [self addSubview:self.imgView];
    
    NSDictionary *views = @{@"banner" : self, @"title" : self.title, @"message" : self.message, @"imgView" : self.imgView};
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.imgView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imgView(50)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imgView(50)]-[title]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[title]-5-[message]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imgView]-[message]" options:0 metrics:nil views:views]];
    
    self.backgroundColor = [UIColor redColor];
    
    UIWindow* currentWindow = [UIApplication sharedApplication].keyWindow;
    [currentWindow addSubview:self];
    
    self.frame = CGRectMake(0, -70, currentWindow.frame.size.width, 70);
    self.hidden = YES;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
}

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    self.layer.borderWidth = 0.6;
    self.imgView.layer.cornerRadius = self.imgView.frame.size.width / 2;
    self.imgView.layer.masksToBounds = YES;
//    self.layer.borderColor = [[HLTheme sharedInstance] tableViewCellSeparatorColor].CGColor;
}

-(void)displayBannerWithChannel:(HLChannel *)channel{
    
    if (!TARGET_IPHONE_SIMULATOR) {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }

    
    self.title.text = channel.name;
    
    if (channel.icon) {
        self.imgView.image = [UIImage imageWithData:channel.icon];
    }else{
        UIImage *placeholderImage = [FDChannelListViewCell generateImageForLabel:channel.name];
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
}

-(void)dismiss{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect myFrame = self.frame;
        myFrame.origin.y = -70;
        self.frame = myFrame;

    } completion:^(BOOL finished) {
        self.hidden = YES;
    } ];
}

-(void)bannerTapped:(id)gestureRecognizer{
    NSLog(@"tapped !@!!!!!");
    [self dismiss];
}

@end