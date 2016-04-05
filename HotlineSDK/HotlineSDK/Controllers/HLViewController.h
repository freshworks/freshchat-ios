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

@interface HLViewController : UIViewController

@property BOOL embedded;

-(void)configureBackButtonWithGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate;

@end



#endif /* HLViewController_h */