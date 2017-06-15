//
//  FDHtmlFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDHtmlFragment.h"

@implementation FDHtmlFragment
    -(id) initWithFragment: (FragmentData *) fragment {
        self = [self initWithFrame:CGRectZero];
        if(self) {
            self.translatesAutoresizingMaskIntoConstraints = false;
            self.numberOfLines = 0;
            NSString *fragmentHTML = fragment.content;
            fragmentHTML = [fragmentHTML stringByAppendingString:@"<style>body{font-family:'HelveticaNeue'; font-size:'20';}</style>"];
            
            NSMutableAttributedString *attributedTitleString = [[NSMutableAttributedString alloc] initWithData:[fragmentHTML dataUsingEncoding:NSUnicodeStringEncoding]             options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
            self.attributedText = attributedTitleString;
            [self setLineBreakMode:NSLineBreakByWordWrapping];
            //[self setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
        }
        return self;
    }
@end
