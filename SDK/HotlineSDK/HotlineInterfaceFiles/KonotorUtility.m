//
//  KonotorUtility.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 20/08/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorUtility.h"

#define KONOTOR_SYSTEM_VERSION_LESS_THAN(v)            ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

static UILabel* toastView=nil;
static UITapGestureRecognizer* tapRecognizer=nil;
static NSTimer* timer=nil;
static BOOL _useiOS7Style;


@implementation KonotorUtility

+ (void) showToastWithString:(NSString*) message forMessageID:(NSString*)messageID
{
    
    UIViewController *currentViewController=[[[UIApplication sharedApplication] keyWindow] rootViewController];
    if([[KonotorUIParameters sharedInstance] toastStyle]==KonotorToastStyleDefault){
        CGRect windowFrame=[[UIScreen mainScreen] bounds];
        float toastX=[UIScreen mainScreen].bounds.size.width/2-140;
        float toastY=40;
        float toastWidth=280;
        float toastHeight=40;
        [KonotorUtility dismissToast];
        toastView=[[UILabel alloc] initWithFrame:CGRectMake(toastX, toastY, toastWidth, toastHeight)];
        [toastView setUserInteractionEnabled:YES];
        [toastView setBackgroundColor:[[KonotorUIParameters sharedInstance] toastBGColor]];
        [toastView setFont:[UIFont systemFontOfSize:14.0]];
        [toastView setTextAlignment:NSTextAlignmentCenter];
        [toastView setTextColor:[[KonotorUIParameters sharedInstance] toastTextColor]];
        [toastView setText:message];
        [toastView setClipsToBounds:NO];
        toastView.layer.shadowColor=[[UIColor blackColor] CGColor];
        toastView.layer.shadowRadius=2.0;
        toastView.layer.shadowOpacity=1.0;
        toastView.layer.shadowOffset=CGSizeMake(2.0, 2.0);
        
        CGPoint centerpoint;
        switch ([[UIDevice currentDevice] orientation]) {
            case UIDeviceOrientationLandscapeLeft:
                centerpoint=CGPointMake(windowFrame.size.width-40, windowFrame.size.height/2);
                toastView.transform=CGAffineTransformMakeRotation(M_PI/2);
                break;
            case UIDeviceOrientationLandscapeRight:
                centerpoint=CGPointMake(40, windowFrame.size.height/2);
                toastView.transform=CGAffineTransformMakeRotation(-M_PI/2);
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                centerpoint=CGPointMake(windowFrame.size.width/2,windowFrame.size.height-40);
                toastView.transform=CGAffineTransformMakeRotation(M_PI);
                break;
                
            default:
                centerpoint=toastView.center;
                break;
        }
        
        toastView.center=centerpoint;
        toastView.frame=CGRectIntegral(toastView.frame);
        
        if(messageID==nil)
            tapRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorUtility class] action:@selector(dismissToast:)];
        else
            tapRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorUtility class] action:@selector(showFeedback:)];
        [toastView addGestureRecognizer:tapRecognizer];
        [[[[UIApplication sharedApplication] delegate] window] addSubview:toastView];
        
        timer=[NSTimer scheduledTimerWithTimeInterval:4.0 target:[KonotorUtility class] selector:@selector(dismissToast:) userInfo:nil repeats:YES];
        [timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:4.0]];
    }
    else if([[KonotorUIParameters sharedInstance] toastStyle]==KonotorToastStyleBarOnWindow){
        CGRect windowFrame=[[UIScreen mainScreen] bounds];
        float toastX,toastY, toastWidth, toastHeight;
        
        if([KonotorUtility KonotorIsInterfaceLandscape:(currentViewController)])
        {
            toastX=0;
            toastY=0;
            toastWidth=windowFrame.size.height;
            toastHeight=40;
        }
        else{
            toastX=0;
            toastY=0;
            toastWidth=windowFrame.size.width;
            toastHeight=40;
        }
        
        [KonotorUtility dismissToast];
        
        
        toastView=[[UILabel alloc] initWithFrame:CGRectMake(toastX, toastY, toastWidth, toastHeight)];
        [toastView setUserInteractionEnabled:YES];
        [toastView setBackgroundColor:[[KonotorUIParameters sharedInstance] toastBGColor]];
        [toastView setFont:[UIFont systemFontOfSize:14.0]];
        [toastView setTextAlignment:NSTextAlignmentCenter];
        [toastView setTextColor:[[KonotorUIParameters sharedInstance] toastTextColor]];
        [toastView setText:message];
        [toastView setClipsToBounds:NO];
        
        CGPoint centerpoint;
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
        switch ([[[[UIApplication sharedApplication] keyWindow] rootViewController] interfaceOrientation]) {
            case UIInterfaceOrientationLandscapeLeft:
                centerpoint=CGPointMake(20, windowFrame.size.height/2);
                toastView.transform=CGAffineTransformMakeRotation(-M_PI/2);
                break;
            case UIInterfaceOrientationLandscapeRight:
                centerpoint=CGPointMake(windowFrame.size.width-20, windowFrame.size.height/2);
                toastView.transform=CGAffineTransformMakeRotation(M_PI/2);
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                centerpoint=CGPointMake(windowFrame.size.width/2,windowFrame.size.height-20);
                toastView.transform=CGAffineTransformMakeRotation(M_PI);
                break;
                
            default:
                centerpoint=toastView.center;
                break;
        }
#else
        centerpoint=toastView.center;
#endif
        
        toastView.center=centerpoint;
        toastView.frame=CGRectIntegral(toastView.frame);
        
        
        
        if(messageID==nil)
            tapRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorUtility class] action:@selector(dismissToast:)];
        else
            tapRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorUtility class] action:@selector(showFeedback:)];
        [toastView addGestureRecognizer:tapRecognizer];

        
       [[[[UIApplication sharedApplication] delegate] window] addSubview:toastView];
        
        
        timer=[NSTimer scheduledTimerWithTimeInterval:3.0 target:[KonotorUtility class] selector:@selector(dismissToast:) userInfo:nil repeats:YES];
        [timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];

    }
    else if([[KonotorUIParameters sharedInstance] toastStyle]==KonotorToastStyleBarOnRootView){
        CGRect windowFrame=[[UIScreen mainScreen] bounds];
        float toastX,toastY, toastWidth, toastHeight;
        
        CGFloat verticalOffset = 0.0f;
        
        
        if([KonotorUtility KonotorIsInterfaceLandscape:currentViewController])
        {
            toastX=0;
            toastY=-40;
            toastWidth=windowFrame.size.height;
            toastHeight=40;
        }
        else{
            toastX=0;
            toastY=-40;
            toastWidth=windowFrame.size.width;
            toastHeight=40;
        }
        
        [KonotorUtility dismissToast];
        
        
        BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
        CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
        CGFloat statusBarOffset = isPortrait ? statusBarSize.height : statusBarSize.width;
        
        
        toastView=[[UILabel alloc] initWithFrame:CGRectMake(toastX, toastY, toastWidth, toastHeight)];
        [toastView setUserInteractionEnabled:YES];
        [toastView setBackgroundColor:[[KonotorUIParameters sharedInstance] toastBGColor]];
        [toastView setFont:[UIFont systemFontOfSize:13.0]];
        [toastView setTextAlignment:NSTextAlignmentCenter];
        [toastView setTextColor:[[KonotorUIParameters sharedInstance] toastTextColor]];
        [toastView setText:message];
        [toastView setClipsToBounds:NO];
        
        if(messageID==nil)
            tapRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorUtility class] action:@selector(dismissToast:)];
        else
            tapRecognizer=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorUtility class] action:@selector(showFeedback:)];
        [toastView addGestureRecognizer:tapRecognizer];
        
        
        if ([currentViewController isKindOfClass:[UINavigationController class]] || [currentViewController.parentViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *currentNavigationController;
            
            if([currentViewController isKindOfClass:[UINavigationController class]])
                currentNavigationController = (UINavigationController *)currentViewController;
            else
                currentNavigationController = (UINavigationController *)currentViewController.parentViewController;
            
            BOOL isViewIsUnderStatusBar = [[[currentNavigationController childViewControllers] firstObject] wantsFullScreenLayout];
            if (!isViewIsUnderStatusBar && currentNavigationController.parentViewController == nil) {
                isViewIsUnderStatusBar = !([currentNavigationController isNavigationBarHidden]||[[currentNavigationController navigationBar] isHidden]); // strange but true
            }
            if (!([currentNavigationController isNavigationBarHidden]||[[currentNavigationController navigationBar] isHidden]))
            {
                [currentNavigationController.view insertSubview:toastView
                                                   belowSubview:[currentNavigationController navigationBar]];
                verticalOffset = [currentNavigationController navigationBar].bounds.size.height;
                if ([KonotorUtility iOS7StyleEnabled] || isViewIsUnderStatusBar) {
                    verticalOffset+=statusBarOffset;
                }
            }
            else
            {
                [currentViewController.view addSubview:toastView];
                if ([KonotorUtility iOS7StyleEnabled] || isViewIsUnderStatusBar) {
                    verticalOffset+=statusBarOffset;
                }
            }
        }
        else
        {
            [currentViewController.view addSubview:toastView];
            if ([KonotorUtility iOS7StyleEnabled]) {
                verticalOffset+=statusBarOffset;
            }
        }
        
        CGPoint toPoint;
        toPoint = CGPointMake(toastView.center.x,
                               verticalOffset + CGRectGetHeight(toastView.frame) / 2.0);
        dispatch_block_t animationBlock = ^{
            toastView.center = toPoint;
        };
        
        if (![KonotorUtility iOS7StyleEnabled]) {
            [UIView animateWithDuration:konotorToastAnimationDuration
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                             animations:animationBlock
                             completion:nil];
        } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
            [UIView animateWithDuration:konotorToastAnimationDuration + 0.1
                                  delay:0
                 usingSpringWithDamping:0.8
                  initialSpringVelocity:0.f
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                             animations:animationBlock
                             completion:nil];
#endif
        }
        
        
        timer=[NSTimer scheduledTimerWithTimeInterval:3.0 target:[KonotorUtility class] selector:@selector(dismissToast:) userInfo:nil repeats:YES];
        [timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
        
    }

}

+ (BOOL)iOS7StyleEnabled
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Decide wheter to use iOS 7 style or not based on the running device and the base sdk
        BOOL iOS7SDK = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        iOS7SDK = YES;
#endif
        
        _useiOS7Style = ! (KONOTOR_SYSTEM_VERSION_LESS_THAN(@"7.0") || !iOS7SDK);
    });
    return _useiOS7Style;
}

+(void) dismissToast
{
    [toastView removeFromSuperview];
    toastView=nil;
    tapRecognizer=nil;
    [timer invalidate];
    timer=nil;
}
+(void) dismissToast: (UIGestureRecognizer*) gestureRecognizer
{
    [KonotorUtility dismissToast];
}

+(void) showFeedback: (UIGestureRecognizer*) gestureRecognizer
{
    [KonotorUtility dismissToast];
    [KonotorFeedbackScreen showFeedbackScreen];
}

+(void) updateBadgeLabel:(UILabel*) badgeLabel
{
    if(badgeLabel){
        int count=[Konotor getUnreadMessagesCount];
        if(count>0)
        {
            [badgeLabel setText:[NSString stringWithFormat:@"%d",count]];
            [badgeLabel setHidden:NO];
        }
        else
        [badgeLabel setHidden:YES];
    }
}

+ (BOOL) KonotorIsInterfaceLandscape:(UIViewController*)viewController
{
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        return NO;
    else{
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
        return (UIInterfaceOrientationIsLandscape(viewController.interfaceOrientation));
#else
        return NO;
#endif
    }
}


@end
