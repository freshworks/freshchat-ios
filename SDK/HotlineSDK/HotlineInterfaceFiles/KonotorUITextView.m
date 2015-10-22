//
//  KonotorUITextView.m
//  KonotorSampleApp
//
//  Created by Srikrishnan Ganesan on 11/07/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorUITextView.h"
#import <QuartzCore/QuartzCore.h>

@implementation KonotorUITextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0]];
        [self setText:@""];
        [self setFont:[UIFont systemFontOfSize:14.0]];
        [self setTextColor:[UIColor blackColor]];
        [self setReturnKeyType:UIReturnKeySend];
        [self setEnablesReturnKeyAutomatically:YES];
                
    }
    return self;
}

- (BOOL) canBecomeFirstResponder{
    return YES;
}

@end