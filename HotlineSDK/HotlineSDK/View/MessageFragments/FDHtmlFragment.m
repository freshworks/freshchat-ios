//
//  FDHtmlFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDHtmlFragment.h"
#import "HLTheme.h"
#import "HLAttributedText.h"
#import "FDUtilities.h"

@implementation FDHtmlFragment
    -(id) initWithFragment: (FragmentData *) fragment {
        @synchronized(self) {
            self = [self initWithFrame:CGRectZero];
            if(self) {
                self.translatesAutoresizingMaskIntoConstraints = false;
                self.numberOfLines = 0;
                
                if([FDUtilities containsHTMLContent:fragment.content]) {                
                    NSMutableAttributedString *str = [[HLAttributedText sharedInstance] getAttributedString:fragment.content];
                    
                    if(str == nil) {
                        //NSLog(@"FRAGMENT::Setting un-cached attributedText::::%@",fragment.content);
                        NSMutableAttributedString *content = [[HLAttributedText sharedInstance] addAttributedString:fragment.content];
                        self.attributedText = content;
                    } else {
                        //NSLog(@"FRAGMENT::Setting cached attributedText::::%@",fragment.content);
                        self.attributedText = str;
                        
                    }
                } else {
                    UIFont *customFont = [[HLTheme sharedInstance] getChatBubbleMessageFont];
                    //NSLog(@"FRAGMENT::Setting normal Text::::%@",fragment.content);
                    self.text = fragment.content;
                    self.font = customFont;
                }
            }
            return self;
        }
    }
@end
