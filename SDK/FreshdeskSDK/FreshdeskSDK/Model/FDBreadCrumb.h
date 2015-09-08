//
//  FDBreadCrumb.h
//  FreshdeskSDK
//
//  Created by balaji on 14/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDBreadCrumb : NSObject

+ (FDBreadCrumb *)sharedInstance;
- (void)addCrumb:(NSString *)crumb;
- (NSArray *)getCrumbs;
- (void)clearBreadCrumbs;

@end