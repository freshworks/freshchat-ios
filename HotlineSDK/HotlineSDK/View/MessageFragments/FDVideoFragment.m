//
//  FDVideoFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDVideoFragment.h"
#import "HLTheme.h"
#import "HLLocalization.h"

@implementation FDVideoFragment

-(id) initWithFragment: (FragmentData *) fragment {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.fragmentData = fragment;
        HLTheme *theme = [HLTheme sharedInstance];
        UIFont *actionLabelFont=[theme getChatBubbleMessageFont];
        float padding = 10;
        self.backgroundColor = [theme actionButtonColor];
        self.contentEdgeInsets = UIEdgeInsetsMake(padding, padding, padding, padding);
        self.backgroundColor = [theme actionButtonColor];
        self.layer.borderColor=[[theme actionButtonBorderColor] CGColor];
        self.layer.borderWidth=0.5;
        self.layer.cornerRadius=5.0;
        NSString *actionLabel = @"Watch Video";
        [self setAttributedTitle:
         [[NSAttributedString alloc] initWithString:actionLabel
                                         attributes:[NSDictionary dictionaryWithObjectsAndKeys:actionLabelFont,NSFontAttributeName,[theme actionButtonTextColor],NSForegroundColorAttributeName,nil]]
                        forState:UIControlStateNormal];
        [self setTitleColor:[theme actionButtonSelectedTextColor] forState:UIControlStateSelected];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.userInteractionEnabled = true;
    }
    return self;
}

@end


