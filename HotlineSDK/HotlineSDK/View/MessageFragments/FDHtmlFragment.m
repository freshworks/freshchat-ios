//
//  FDHtmlFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDHtmlFragment.h"
#import "FCTheme.h"
#import "HLAttributedText.h"
#import "FDUtilities.h"

@implementation FDHtmlFragment
    -(id) initWithFragment: (FragmentData *) fragment {
        @synchronized(self) {
            self = [self initWithFrame:CGRectZero];
            if(self) {
                self.translatesAutoresizingMaskIntoConstraints = false;
                [self setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                [self setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                [self setEditable:NO];
                [self setTextAlignment:NSTextAlignmentLeft];
                [self setTintColor:[[FCTheme sharedInstance] hyperlinkColor]];
                [self setBackgroundColor:UIColor.clearColor];                
                [self setScrollEnabled:NO];
                if([FDUtilities containsHTMLContent:fragment.content]) {
                    NSMutableAttributedString *str = [[HLAttributedText sharedInstance] getAttributedString:fragment.content];
                    if(str == nil) {
                        NSMutableAttributedString *content = [[HLAttributedText sharedInstance] addAttributedString:fragment.content];
                        self.attributedText = content;
                    } else {
                        self.attributedText = str;                        
                    }
                } else {
                    UIFont *customFont = [[FCTheme sharedInstance] getChatBubbleMessageFont];
                    self.text = fragment.content;
                    self.font = customFont;
                }
            }
            return self;
        }
    }
@end
