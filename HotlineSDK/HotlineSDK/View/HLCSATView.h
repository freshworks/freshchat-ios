//
//  HLCSATView.h
//  HotlineSDK
//
//  Created by user on 17/10/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLCsat.h"

@protocol HLCSATViewDelegate <NSObject>

-(void)submittedCSAT:(HLCsatHolder *)csatHolder;
-(void)handleUserEvadedCSAT;

@end

@interface HLCSATView : UIView

@property (nonatomic,weak) id<HLCSATViewDelegate> delegate;
@property (nonatomic, strong) UILabel *surveyTitle;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isResolved;
@property (nonatomic, strong) NSLayoutConstraint *CSATPromptCenterYConstraint;

- (instancetype)initWithController:(UIViewController *)controller hideFeedbackView:(BOOL)hideFeedbackView isResolved:(BOOL)isResolved;
- (void)show;
- (void)dismiss;

@end
