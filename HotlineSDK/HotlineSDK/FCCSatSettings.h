//
//  FCCSatSettings.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 20/06/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCCSatSettings : NSObject

@property (nonatomic, assign) long maximumUserSurveyViewMillis;
@property (nonatomic, assign) BOOL isUserCsatViewTimerEnabled;

- (void) updateCSatConfig : (NSDictionary *) info;

@end
