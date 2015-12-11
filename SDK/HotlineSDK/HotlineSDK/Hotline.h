//
//  Hotline.h
//  Konotor
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Hotline : NSObject

@property(nonatomic) BOOL dispalySolutionAsGrid;

+(instancetype) sharedInstance;
+(void) setUnreadWelcomeMessage:(NSString *) text;
-(void) initWithAppID: (NSString *) AppID AppKey: (NSString *) AppKey withDelegate:(id) delegate;
+(void)presentFeedback:(UIViewController *)controller;
-(void)presentSolutions:(UIViewController *)controller;

@end