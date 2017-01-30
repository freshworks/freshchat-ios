//
//  CategoryViewBehaviour.m
//  HotlineSDK
//
//  Created by Hrishikesh on 11/01/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLLoadingViewBehaviour.h"
#import "HLFAQUtil.h"
#import "HLTagManager.h"
#import "FDLocalNotification.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDBarButtonItem.h"
#import "HLLocalization.h"
#import "HLEventManager.h"
#import "HLSearchViewController.h"
#import "HLControllerUtils.h"
#import "HLEmptyResultView.h"
#import "FDAutolayoutHelper.h"
#import "FDReachabilityManager.h"

@interface  HLLoadingViewBehaviour ()

@property (nonatomic, weak) UIViewController <HLLoadingViewBehaviourDelegate> *loadingViewDelegate;
@property (nonatomic, strong) HLTheme *theme;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;

@end

@implementation HLLoadingViewBehaviour

-(instancetype) initWithViewController:(UIViewController <HLLoadingViewBehaviourDelegate> *) viewController{
    self = [super init];
    if(self){
        self.loadingViewDelegate = viewController;
        self.theme = [HLTheme sharedInstance];
    }
    return self;
}

-(void) load:(long)currentCount{
    if(currentCount == 0 ){
        [self addLoadingIndicator];
        [self updateResultsView:YES andCount:currentCount];
    }
}

-(void) unload{
    self.activityIndicator = nil;
    self.emptyResultView = nil;
}

-(void)addLoadingIndicator{
    if(self.activityIndicator){
        return;
    }
    UIView *view = self.loadingViewDelegate.view;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    [view insertSubview:self.activityIndicator aboveSubview:[self.loadingViewDelegate contentDisplayView]];
    [self.activityIndicator startAnimating];
    [FDAutolayoutHelper centerX:self.activityIndicator onView:view M:1 C:0];
    [FDAutolayoutHelper centerY:self.activityIndicator onView:view M:1.5 C:0];
}

-(HLEmptyResultView *)emptyResultView
{
    if (!_emptyResultView) {
        _emptyResultView = [[HLEmptyResultView alloc]initWithImage:[self.theme getImageWithKey:IMAGE_FAQ_ICON] andText:@""];
        _emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _emptyResultView;
}


-(void)removeLoadingIndicator{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    });
}

-(void)updateResultsView:(BOOL)isLoading andCount:(long) count{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!isLoading){
            [self removeLoadingIndicator];
        }
        if(count == 0) {
            NSString *message;
            if(isLoading){
                message = [self.loadingViewDelegate loadingText];
            }
            else if(![[FDReachabilityManager sharedInstance] isReachable]){
                message = HLLocalizedString(LOC_OFFLINE_INTERNET_MESSAGE);
            }
            else {
                message = [self.loadingViewDelegate emptyText];
            }
            self.emptyResultView.emptyResultLabel.text = message;
            [self.loadingViewDelegate.view addSubview:self.emptyResultView];
            [FDAutolayoutHelper center:self.emptyResultView onView:self.loadingViewDelegate.view];
        }
        else{
            self.emptyResultView.frame = CGRectZero;
            [self.emptyResultView removeFromSuperview];
        }
    });
}

@end
