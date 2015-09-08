//
//  FDFooterView.m
//  FreshdeskSDK
//
//  Created by balaji on 17/06/14.
//  Copyright (c) 1514 Freshdesk. All rights reserved.
//

#import "FDFooterView.h"
#import "FDSecureStore.h"

@interface FDFooterView ()

@property (nonatomic) BOOL isPaidUser;

@end

@implementation FDFooterView

-(instancetype)initWithController:(UIViewController *)controller{
    
    if (!self.isPaidUser) {
        self = [super init];
        if (self) {
            self.backgroundColor = [UIColor blackColor];
            self.translatesAutoresizingMaskIntoConstraints = NO;
            [controller.view addSubview:self];
            
            UILabel *footerText = [[UILabel alloc] init];
            footerText.translatesAutoresizingMaskIntoConstraints = NO;
            footerText.textColor = [UIColor whiteColor];
            footerText.textAlignment = NSTextAlignmentCenter;
            [footerText sizeToFit];
            footerText.font          = [UIFont systemFontOfSize:10.0f];
            footerText.text          = @"Powered by Freshdesk";
            
            [self addSubview:footerText];
            
            [controller.view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:controller.view
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:-20.0]];
            
            [controller.view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeLeading
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:controller.view
                                                                  attribute:NSLayoutAttributeLeading
                                                                 multiplier:1.0
                                                                   constant:0.0]];
            
            [controller.view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0
                                                                   constant:20.0]];
            
            [controller.view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:controller.view
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1.0
                                                                   constant:0.0]];

            [self addConstraint:[NSLayoutConstraint constraintWithItem:footerText
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:footerText
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:footerText
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:0.0]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:footerText
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1.0
                                                                    constant:0.0]];
        }
        return self;
    }
    
    else {
        return nil;
    }
}

-(BOOL)isPaidUser{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    BOOL isPaidUser = [secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_PAID_USER];
    return isPaidUser;
}

@end
