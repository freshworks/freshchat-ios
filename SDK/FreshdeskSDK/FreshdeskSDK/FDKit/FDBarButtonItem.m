//
//  FDBarButtonItem.m
//  FreshdeskSDK
//
//  Created by Aravinth on 18/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDBarButtonItem.h"
#import "FDButton.h"
#import "FDSearchBar.h"
#import "FDTheme.h"

@interface FDBarButtonItem ()
@property (strong, nonatomic) FDTheme *theme;
@end

@implementation FDBarButtonItem

-(FDTheme *)theme{
    if(!_theme){ _theme = [FDTheme sharedInstance]; }
    return _theme;
}

-(id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action{
    self = [super initWithTitle:title style:style target:target action:action];
    if (self) {

        FDButton *button            = [FDButton buttonWithType:UIButtonTypeSystem];
        NSString *barButtonFontName = [self.theme navigationBarButtonFontName];
        UIColor *barButtonColor     = [self.theme navigationBarButtonColor];
        CGFloat barButtonFontSize   = [self.theme navigationBarButtonFontSize];
        [button setTitleColor:barButtonColor forState:UIControlStateNormal];
        button.titleLabel.font      = [UIFont fontWithName:barButtonFontName size:barButtonFontSize];
        [button setTitle:title forState:UIControlStateNormal];
        [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        self.customView = button;
    }
    return self;
}

-(instancetype)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action{
    self = [super initWithBarButtonSystemItem:systemItem target:target action:action];
    if (self) {
        self.tintColor = [self.theme navigationBarButtonColor];
    }
    return self;
}

@end
