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
#import "FDBarButtonItem.h"

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
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
         [self.theme searchBarCancelButtonColor], NSForegroundColorAttributeName, [self.theme searchBarCancelButtonFont], NSFontAttributeName, nil];
        
        [[UIBarButtonItem appearanceWhenContainedIn:[FDSearchBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithDictionary:attributes] forState:UIControlStateNormal];
        
        //Search text font color
        NSDictionary *textAttrDict = @{NSFontAttributeName:[self.theme searchBarFont],
                                       NSForegroundColorAttributeName:[self.theme searchBarFontColor]};
        UITextField *textItemProxy = [UITextField appearanceWhenContainedIn:[FDSearchBar class], nil];
        [textItemProxy setDefaultTextAttributes:textAttrDict];
    }
    return self;
}

@end