//
//  HLControllerUtils.h
//  HotlineSDK
//
//  Created by user on 03/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLConversationUtil.h"

@interface HLControllerUtils : NSObject

+(UIViewController *)getConvController:(BOOL)isEmbeded
                           withOptions:(ConversationOptions *)options
                           andChannels:(NSArray *)channels;

+(void) configureBackButtonForController:(UIViewController *) controller
                            withEmbedded:(BOOL) isEmbedded;

+(void) configureGestureDelegate:(UIViewController <UIGestureRecognizerDelegate> *)gestureDelegate
                   forController:(UIViewController *) controller
                    withEmbedded:(BOOL) isEmbedded;


//TODO: Replace other close buttons with this API - Rex 
+(void) configureCloseButton:(UIViewController *) controller
                   forTarget:(id)targetObj
                    selector:(SEL) actionSelector
                       title:(NSString *)title;

@end
