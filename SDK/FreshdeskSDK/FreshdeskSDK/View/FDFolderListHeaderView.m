//
//  FDFolderListHeaderView.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 27/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDFolderListHeaderView.h"
#import "FDBadgeView.h"
#import "FDTheme.h"
#import "FDMacros.h"
#import "FDSecureStore.h"

@interface FDFolderListHeaderView ()

@property (strong, nonatomic) FDTheme     *theme;
@property (strong, nonatomic) FDBadgeView *badgeView;
@property (strong, nonatomic) UILabel     *title;
@property (strong, nonatomic) UIView      *myConversationsView;

@end

@implementation FDFolderListHeaderView

-(FDTheme *)theme{
    if(!_theme){ _theme = [FDTheme sharedInstance]; }
    return _theme;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        FDSecureStore *secureStore = [FDSecureStore sharedInstance];
        if (![secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_CONVERSATIONS_DISABLED]) {
            [self addMyConversationsView];
            [self addBadgeWithCount:0];
            [self addSubview:self.myConversationsView];
        }
    }
    return self;
}

-(void)setBadgeCount:(NSInteger)badgeCount{
    [self updateBadgeButtonCount:badgeCount];
}

#pragma mark - Subview Initializations

-(void)addMyConversationsView{
    self.myConversationsView                        = [[UIView alloc]initWithFrame:CGRectZero];
    self.myConversationsView.backgroundColor        = [self.theme myConversationsCellBackgroundColor];
    self.myConversationsView.frame                  = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.myConversationsView.userInteractionEnabled = YES;
    self.myConversationsView.autoresizingMask       = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //Title
    self.title           = [[UILabel alloc]initWithFrame:CGRectZero];
    self.title.text      = FDLocalizedString(@"My Conversations Label" );
    self.title.textColor = [self.theme myConversationsCellFontColor];
    NSString *fontName   = [self.theme myConversationsCellFontName];
    CGFloat fontSize     = [self.theme myConversationsCellFontSize];
    self.title.font      = [UIFont fontWithName:fontName size:fontSize];

    [self.title sizeToFit];
    float labelXPos    = 10;
    float labelYPos    = (self.frame.size.height - self.title.frame.size.height)/2;
    float labelWidth   = self.title.frame.size.width;
    float labelHeight  = self.title.frame.size.height;
    self.title.frame   = CGRectMake(labelXPos, labelYPos, labelWidth, labelHeight);
    [self.myConversationsView addSubview:self.title];
}

-(void)addBadgeWithCount:(NSInteger)count{
    self.badgeView  = [[FDBadgeView alloc]initWithFrame:CGRectZero andBadgeNumber:count];
    self.badgeCount = count;
    [self.badgeView badgeButtonBackgroundColor:[self.theme badgeButtonBackgroundColor]];
    [self.badgeView badgeButtonTitleColor:[self.theme badgeButtonTitleColor]];
    self.badgeView.badgeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.myConversationsView addSubview:self.badgeView.badgeButton];
    NSDictionary *viewsDictionary = @{@"badgeButton":self.badgeView.badgeButton};
    NSArray *constraint_POS_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[badgeButton]-8-|" options:0 metrics:nil views:viewsDictionary];
    NSArray *constraint_POS_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[badgeButton]-6-|" options:0 metrics:nil views:viewsDictionary];
    [self.myConversationsView addConstraints:constraint_POS_H];
    [self.myConversationsView addConstraints:constraint_POS_V];
}

#pragma mark - Badge View

-(void)badgeViewBackgroundColor:(UIColor *)color{
    [self.badgeView badgeButtonBackgroundColor:color];
}

-(void)badgeViewTitleColor:(UIColor *)color{
    [self.badgeView badgeButtonTitleColor:color];
}

-(void)updateBadgeButtonCount:(NSInteger)count{
    [self.badgeView.badgeButton setHidden:NO];
    [self.badgeView updateBadgeCount:count];
}

-(void)removeBadgeView{
    [self.badgeView.badgeButton removeFromSuperview];
}

-(void)hideBadgeView{
    [self.badgeView.badgeButton setHidden:YES];
}

#pragma mark - Theming

-(void)myConversationsViewFont:(UIFont *)font{
    self.title.font = font;
}

-(void)myConversationsViewFontColor:(UIColor *)color{
    self.title.textColor = color;
}

-(void)myConversationsViewBackgroundColor:(UIColor *)color{
    self.myConversationsView.backgroundColor = color;
}

#pragma mark - 

-(void)tapGestureHander:(SEL)handler onController:(UIViewController *)controller{
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:controller action:handler];
    [self.myConversationsView addGestureRecognizer:singleFingerTap];
}

@end