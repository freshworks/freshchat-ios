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

@interface FCViewController : UIViewController

@property BOOL embedded;
@property (nonatomic,strong) NSDictionary *viewsVC;
@property (nonatomic,strong) UIView *loadingVC;

-(void)configureBackButton;
-(UIViewController <UIGestureRecognizerDelegate> *) gestureDelegate;
-(void)jwtActive;
-(void)waitForFirstToken;
-(void)verificationUnderProgress;
-(void)waitingForRefreshToken;
-(void)tokenVerificationFailed;
-(void)resetViews;
-(void)showLoadingScreen;
-(void)removeLoadingScreen;


@end



#endif /* HLViewController_h */
