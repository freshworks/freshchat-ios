//
//  FDSearchBar.m
//  FreshdeskSDK
//
//  Created by Aravinth on 19/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDSearchBar.h"
#import <UIKit/UIKit.h>
#import "FDUtilities.h"
#import "HLTheme.h"

@interface FDSearchBar ()

@property (strong, nonatomic) HLTheme *theme;

@end

@implementation FDSearchBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.theme = [HLTheme sharedInstance];
        self.searchBarStyle = UISearchBarStyleProminent;

        self.tintColor = [self.theme searchBarCursorColor];

        //Search bar outer background color
        [self setBackgroundImage:[FDUtilities imageWithColor:[self.theme searchBarOuterBackgroundColor]] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];

        //Search bar cancel button color
        NSDictionary *attrDict = @{NSFontAttributeName:[self.theme searchBarCancelButtonFont],
                                   NSForegroundColorAttributeName:[self.theme searchBarCancelButtonColor]};
        UIBarButtonItem *buttonItemProxy = [UIBarButtonItem appearanceWhenContainedIn:[FDSearchBar class], nil];
        [buttonItemProxy setTitleTextAttributes:attrDict forState:UIControlStateNormal];
        
        //Search text font color
        NSDictionary *textAttrDict = @{NSFontAttributeName:[self.theme searchBarFont],
                                       NSForegroundColorAttributeName:[self.theme searchBarFontColor]};
        UITextField *textItemProxy = [UITextField appearanceWhenContainedIn:[FDSearchBar class], nil];
        [textItemProxy setDefaultTextAttributes:textAttrDict];
    }
    return self;
}

@end