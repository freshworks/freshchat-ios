//
//  FDNavigationBar.m
//  FreshdeskSDK
//
//  Created by Aravinth on 18/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDNavigationBar.h"
#import "FDTheme.h"

@interface FDNavigationBar ()
@property (strong, nonatomic) FDTheme *theme;
@end

@implementation FDNavigationBar

-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        //Bar Button - "<Back" Color
        self.tintColor = [self.theme navigationBarButtonColor];
        
        //Bar Background    Color
        self.barTintColor = [self.theme navigationBarBackground];
        self.backgroundColor = nil;
        
        //Navigation Bar Title
        self.titleTextAttributes = @{
            NSForegroundColorAttributeName: [self.theme navigationBarTitleColor],
            NSFontAttributeName : [UIFont fontWithName:[self.theme navigationBarTitleFontName] size:[self.theme navigationBarTitleFontSize]]
            };
    }
    return self;
}


@end