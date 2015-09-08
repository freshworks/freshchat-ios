//
//  KonotorFeedbackScreen.m
//  KonotorSampleApp
//
//  Created by Srikrishnan Ganesan on 09/07/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorFeedbackScreen.h"

static KonotorFeedbackScreen* konotorFeedbackScreen=nil;

@implementation KonotorFeedbackScreen

@synthesize conversationViewController,window,konotorFeedbackScreenNavigationController;

+ (KonotorFeedbackScreen*) sharedInstance
{
    if(konotorFeedbackScreen==nil){
        konotorFeedbackScreen=[[KonotorFeedbackScreen alloc] init];
    }
    return konotorFeedbackScreen;
}

+(BOOL) isShowingFeedbackScreen
{
    return ((konotorFeedbackScreen==nil)?NO:YES);
}

+ (BOOL) showFeedbackScreenWithViewController:(UIViewController*) viewController
{
    KonotorFeedbackScreen* fbScreen=[KonotorFeedbackScreen sharedInstance];
    if(fbScreen.conversationViewController!=nil)
        return NO;
    else{
        konotorFeedbackScreen.conversationViewController=[[KonotorFeedbackScreenViewController alloc] initWithNibName:@"KonotorFeedbackScreenViewController" bundle:nil];
        konotorFeedbackScreen.konotorFeedbackScreenNavigationController=[[UINavigationController alloc] initWithRootViewController:konotorFeedbackScreen.conversationViewController];

        [konotorFeedbackScreen.conversationViewController setupNavigationController];

        
        [konotorFeedbackScreen.conversationViewController setModalPresentationStyle:UIModalPresentationFullScreen];
        [konotorFeedbackScreen.conversationViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        
        
        [viewController presentViewController:konotorFeedbackScreen.konotorFeedbackScreenNavigationController animated:YES completion:^{
            if([[KonotorUIParameters sharedInstance] autoShowTextInput])
                [konotorFeedbackScreen.conversationViewController performSelector:@selector(showTextInput) withObject:nil afterDelay:0.0];
        }];
    }
    return YES;
}

+ (BOOL) showFeedbackScreen
{
    KonotorFeedbackScreen* fbScreen=[KonotorFeedbackScreen sharedInstance];
    if(fbScreen.conversationViewController!=nil)
        return NO;
    else{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            konotorFeedbackScreen.conversationViewController=[[KonotorFeedbackScreenViewController alloc] initWithNibName:@"KonotorFeedbackScreenViewController" bundle:nil];
            
            konotorFeedbackScreen.konotorFeedbackScreenNavigationController=[[UINavigationController alloc] initWithRootViewController:konotorFeedbackScreen.conversationViewController];
            
            [konotorFeedbackScreen.conversationViewController setupNavigationController];

            if(KONOTOR_PUSH_ON_NAVIGATIONCONTROLLER){
                if([[[[[UIApplication sharedApplication] delegate] window] rootViewController] isMemberOfClass:[UINavigationController class]]){
                    [(UINavigationController*)[[[[UIApplication sharedApplication] delegate] window] rootViewController] pushViewController:konotorFeedbackScreen.konotorFeedbackScreenNavigationController animated:YES];
                    
                    konotorFeedbackScreen.konotorFeedbackScreenNavigationController=nil;
                    return;
                }
            }
            [konotorFeedbackScreen.conversationViewController setModalPresentationStyle:UIModalPresentationFullScreen];
            [konotorFeedbackScreen.conversationViewController setModalTransitionStyle:[KonotorUIParameters sharedInstance].overlayTransitionStyle];
            
            UIViewController *rootViewController=[[[[UIApplication sharedApplication] delegate] window] rootViewController];
            if([rootViewController isKindOfClass:[UINavigationController class]])
                rootViewController=[((UINavigationController*)rootViewController) topViewController];
            UIViewController *presentedViewController=[rootViewController presentedViewController];
            while(presentedViewController!=nil){
                rootViewController=presentedViewController;
                presentedViewController=[rootViewController presentedViewController];
            }
            
            [rootViewController presentViewController:konotorFeedbackScreen.konotorFeedbackScreenNavigationController animated:YES completion:^{
                if([[KonotorUIParameters sharedInstance] autoShowTextInput])
                    [konotorFeedbackScreen.conversationViewController performSelector:@selector(showTextInput) withObject:nil afterDelay:0.0];
            }];
        });
    }
    
    return YES;
}



+ (void) refreshMessages
{
    [konotorFeedbackScreen.conversationViewController refreshView];
}

+ (void) dismissScreen
{
    [KonotorTextInputOverlay dismissInput];
    [KonotorVoiceInputOverlay dismissVoiceInput];
    [konotorFeedbackScreen.conversationViewController dismissViewControllerAnimated:YES completion:^{
        konotorFeedbackScreen.conversationViewController=nil;
        konotorFeedbackScreen.window=nil;
        konotorFeedbackScreen=nil;
        konotorFeedbackScreen.konotorFeedbackScreenNavigationController=nil;
        [Konotor setDelegate:[KonotorEventHandler sharedInstance]];
        [Konotor StopPlayback];

    }];
 
}

+ (BOOL) forceShowFeedbackScreen
{
    if([KonotorFeedbackScreen isShowingFeedbackScreen]){
        [KonotorFeedbackScreen dismissScreen];
        [KonotorFeedbackScreen showFeedbackScreen];

    }
    return YES;
}


@end
