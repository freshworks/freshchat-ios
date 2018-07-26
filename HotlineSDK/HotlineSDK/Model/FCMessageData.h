//
//  MessageData.h
//  HotlineSDK
//
//  Created by user on 13/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCMessageData : NSObject

@property (nullable, nonatomic, retain) NSString * messageId;
@property (nullable, nonatomic, retain) NSNumber *channelId;
@property (nullable, nonatomic, retain) NSString *conversationId;
@property (nullable, nonatomic, retain) NSString *createdMillis;
@property (nullable, nonatomic, retain) NSNumber *marketingId;
@property (nullable, nonatomic, retain) NSString *messageAlias;
@property (nullable, nonatomic, retain) NSString *messageUserAlias;
@property (nullable, nonatomic, retain) NSNumber *messageUserType;
@property (nullable, nonatomic, retain) NSArray *fragments;
@property(nullable, nonatomic, retain) NSNumber *uploadStatus;
@property (nonatomic) BOOL isMarkedForUpload;
@property (nonatomic) BOOL isWelcomeMessage;
@property (nonatomic) BOOL isRead;
@property (nonatomic) BOOL isMarketingMessage;

@end
