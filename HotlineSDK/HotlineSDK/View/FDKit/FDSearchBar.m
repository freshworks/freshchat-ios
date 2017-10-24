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
#import "FCTheme.h"
#import "FDBarButtonItem.h"

@interface FDSearchBar ()

@property (strong, nonatomic) FCTheme *theme;

@end

@implementation FDSearchBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.theme = [FCTheme sharedInstance];
        self.searchBarStyle = UISearchBarStyleProminent;
        self.tintColor = [self.theme searchBarCursorColor];
        UIImage *searchClearIcon = [[FCTheme sharedInstance] getImageValueWithKey:IMAGE_SEARCH_BAR_CLEAR_ICON];
        if(searchClearIcon){
            [self setImage:searchClearIcon forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
        }
        UIImage *searchIcon = [[FCTheme sharedInstance] getImageValueWithKey:IMAGE_SEARCH_BAR_SEARCH_ICON];
        if(searchIcon){
            [self setImage:searchIcon
           forSearchBarIcon:UISearchBarIconSearch
                      state:UIControlStateNormal];
        }
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
