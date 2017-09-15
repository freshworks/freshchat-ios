//
//  FCMiscFeatures.h
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCConversationConfig : NSObject

@property (nonatomic, assign) BOOL showAgentAvatars;
@property (nonatomic, assign) float activeConvFetchBackoffRatio;
@property (nonatomic, assign) BOOL launchDeeplinkFromNotification;
@property (nonatomic, assign) long activeConvWindow;

-(id) init;

@end
