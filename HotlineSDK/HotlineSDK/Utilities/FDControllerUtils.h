//
//  FDControllerUtils.h
//  HotlineSDK
//
//  Created by user on 03/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLConversationUtil.h"

@interface FDControllerUtils : NSObject

+(UIViewController *)getConvController:(BOOL)isEmbeded
                           withOptions:(ConversationOptions *)options
                           andChannels:(NSArray *)channels;

//+(void(^__strong)())configureBackButtonWithGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate
                                             //forController:(UIViewController *) controller
                                              //withEmbedded:(BOOL) isEmbedded;

+(void) configureBackButtonForController:(UIViewController *) controller
                            withEmbedded:(BOOL) isEmbedded;

+(void) configureGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate
                   forController:(UIViewController *) controller
                    withEmbedded:(BOOL) isEmbedded;

+(void) configureCloseButton:(UIViewController *) controller
                   forTarget:(id)targetObj
                    selector: (SEL) actionSelector;

@end
