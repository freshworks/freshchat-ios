//
//  HLLoadingViewBehaviour.h
//  HotlineSDK
//
//  Created by Hrishikesh on 11/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#ifndef HLLoadingViewBehaviour_h
#define HLLoadingViewBehaviour_h

#import <UIKit/UIKit.h>
#import "FreshchatSDK.h"
#import "FCEmptyResultView.h"

@protocol HLLoadingViewBehaviourDelegate

-(UIView *) contentDisplayView;
-(NSString *) loadingText;
-(NSString *) emptyText;

@end

@interface FCLoadingViewBehaviour : NSObject


-(instancetype) initWithViewController:(UIViewController <HLLoadingViewBehaviourDelegate> *) viewController withType:(enum SupportType)solType;

-(void) load:(long)currentCount;
-(void) unload;
-(void) updateResultsView:(BOOL)isLoading andCount:(long) count;
-(void) setJWTState:(BOOL) isAuthInProgress;
-(void) showLoadingScreen;
-(void) hideLoadingScreen;
-(void) killTimer;

@end


#endif /* HLLoadingViewBehaviour_h */
