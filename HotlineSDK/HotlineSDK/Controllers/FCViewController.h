//
//  HLViewController.h
//  HotlineSDK
//
//  Created by Hrishikesh on 05/02/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#ifndef HLViewController_h
#define HLViewController_h

#import <UIKit/UIKit.h>
#import "FCLoadingViewBehaviour.h"

@interface FCViewController : UIViewController

@property BOOL embedded;

-(void)configureBackButton;
-(UIViewController <UIGestureRecognizerDelegate> *) gestureDelegate;

-(void)jwtEventChange;
-(void)addJWTObservers;
-(void)removeJWTObservers;
- (enum JWT_UI_STATE) getUpdatedAction;

@end



#endif /* HLViewController_h */
