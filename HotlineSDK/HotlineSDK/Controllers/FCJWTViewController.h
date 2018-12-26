//
//  HLViewController.h
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "FCViewController.h"

@interface FCJWTViewController : FCViewController

-(void) jwtStateChange;
-(void) addJWTObservers;
-(void) removeJWTObservers;
-(void) showJWTLoading;
-(void) hideJWTLoading;
-(void) showJWTVerificationFailedAlert;

@end
