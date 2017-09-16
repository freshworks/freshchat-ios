//
//  FDBarButtonItem.m
//  HotlineSDK
//
//  Created by Hrishikesh on 03/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "FDBarButtonItem.h"
#import "FDButton.h"
#import "FCTheme.h"

@interface FDBarButtonItem ()

@end

@implementation FDBarButtonItem

-(id)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action{
    self = [super initWithTitle:title style:style target:target action:action];
    if (self) {
        FCTheme *theme = [FCTheme sharedInstance];
        FDButton *button            = [FDButton buttonWithType:UIButtonTypeSystem];
        UIColor *barButtonColor     = [theme navigationBarButtonColor];
        [button setTitleColor:barButtonColor forState:UIControlStateNormal];
        button.titleLabel.font      = [theme navigationBarButtonFont];
        button.backgroundColor = [UIColor clearColor];
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
        self.tintColor = [[FCTheme sharedInstance] navigationBarButtonColor];
    }
    return self;
}

@end
