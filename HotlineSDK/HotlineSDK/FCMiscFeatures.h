//
//  FCMiscFeatures.h
//  HotlineSDK
//
//  Created by user on 06/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCMiscFeatures : NSObject

@property (nonatomic, assign) BOOL showAgentAvatars;
@property (nonatomic, assign) BOOL showRealAgentAvatars;
@property (nonatomic, assign) BOOL launchDeeplinkFromNotification;

-(id) init;

@end
