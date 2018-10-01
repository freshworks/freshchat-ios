//
//  FDHtmlFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCHtmlFragment.h"
#import "FCTheme.h"
#import "FCAttributedText.h"
#import "FCUtilities.h"

@implementation FCHtmlFragment

-(id) initFragment: (FragmentData *) fragment withFont :(UIFont *)font andType:(enum ConvMessageType) type{
        @synchronized(self) {
            self = [self initWithFrame:CGRectZero];
            if(self) {
                self.translatesAutoresizingMaskIntoConstraints = false;
                [self setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                [self setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                self.dataDetectorTypes = UIDataDetectorTypeAll;
                [self setEditable:NO];
                [self setSelectable:YES];
                [self setBackgroundColor:UIColor.clearColor];                
                [self setScrollEnabled:NO];
                self.delegate = self;
                self.font = font;
                if([FCUtilities containsHTMLContent:fragment.content]) {
                    self.attributedText = [FCUtilities getAttributedContentForString:fragment.content withFont:self.font];
                } else {
                    self.text = fragment.content;
                }
                //Req. color values here, else color property will not apply for html content as attributedtext default color (black) will over-ride for message
                if(type == AGENT){
                    [self setTintColor:[[FCTheme sharedInstance] agentHyperlinkColor]];
                    self.textColor = [[FCTheme sharedInstance] agentMessageFontColor];
                    [self setTextAlignment:[[FCTheme sharedInstance] agentMessageTextAlignment]];
                }
                else{
                    [self setTintColor:[[FCTheme sharedInstance] userHyperlinkColor]];
                    self.textColor = [[FCTheme sharedInstance] userMessageFontColor];
                    [self setTextAlignment:[[FCTheme sharedInstance] userMessageTextAlignment]];
                }
            }
            return self;
        }
    }

    - (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
        if ([Freshchat sharedInstance].shouldInteractWithURL != nil) {
            return [Freshchat sharedInstance].shouldInteractWithURL(URL);            
        } else {
            return YES;
        }
    }


@end
