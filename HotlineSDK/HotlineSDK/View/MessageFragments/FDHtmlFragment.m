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
-(id) initFragment: (FragmentData *) fragment withFont :(UIFont *)font andType:(enum ConvMessageType) type{
        @synchronized(self) {
            self = [self initWithFrame:CGRectZero];
            if(self) {
                self.translatesAutoresizingMaskIntoConstraints = false;
                [self setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                [self setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                self.dataDetectorTypes = UIDataDetectorTypeAll;
                [self setEditable:NO];
                self.dataDetectorTypes = UIDataDetectorTypeAll;
                [self setTextAlignment:NSTextAlignmentLeft];
                if(type == AGENT){
                    [self setTintColor:[[FCTheme sharedInstance] agentHyperlinkColor]];
                }
                else{
                    [self setTintColor:[[FCTheme sharedInstance] userHyperlinkColor]];
                }
                [self setBackgroundColor:UIColor.clearColor];                
                [self setScrollEnabled:NO];
                self.font = font;
                if([FDUtilities containsHTMLContent:fragment.content]) {
                    NSMutableAttributedString *str = [[HLAttributedText sharedInstance] getAttributedString:fragment.content];
                    if(str == nil) {
                        NSMutableAttributedString *content = [[HLAttributedText sharedInstance] addAttributedString:fragment.content withFont:self.font];
                        self.attributedText = content;
                    } else {
                        self.attributedText = str;
                    }
                } else {
                    self.text = fragment.content;
                }
            }
            return self;
        }
    }
@end
