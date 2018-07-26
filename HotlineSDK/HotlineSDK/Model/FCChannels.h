//
//  HLChannel.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FCConversations, FCMessageUtil, FCMessages;

#define CHANNEL_TYPE_AGENT_ONLY @"AGENT_ONLY"
#define CHANNEL_TYPE_USER_ONLY @"USER_ONLY"
#define CHANNEL_TYPE_BOTH @"BOTH"

NS_ASSUME_NONNULL_BEGIN

@interface FCChannels : NSManagedObject

@property (nullable, nonatomic, retain) NSNumber *channelID;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSDate *created;
@property (nullable, nonatomic, retain) NSData *icon;
@property (nullable, nonatomic, retain) NSString *iconURL;
@property (nullable, nonatomic, retain) NSNumber *isHidden;
@property (nullable, nonatomic, retain) NSNumber *isRestricted;
@property (nullable, nonatomic, retain) NSNumber *isDefault;
@property (nullable, nonatomic, retain) NSDate *lastUpdated;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *position;
@property (nullable, nonatomic, retain) NSSet<FCConversations *> *conversations;
@property (nullable, nonatomic, retain) NSSet<FCMessages *> *messages;

+(FCChannels *)getWithID:(NSNumber *)channelID inContext:(NSManagedObjectContext *)context;
+(FCChannels *)getWithName:(NSString *)name inContext:(NSManagedObjectContext *)context;
+(FCChannels *)getDefaultChannelInContext:(NSManagedObjectContext *)context;

+(FCChannels *)createWithInfo:(NSDictionary *)channelInfo inContext:(NSManagedObjectContext *)context;
+(FCChannels *)updateChannel:(FCChannels *)channel withInfo:(NSDictionary *)channelInfo;

@end

@interface FCChannels (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(FCConversations *)value;
- (void)removeConversationsObject:(FCConversations *)value;
- (void)addConversations:(NSSet<FCConversations *> *)values;
- (void)removeConversations:(NSSet<FCConversations *> *)values;

- (void)addMessagesObject:(FCMessages *)value;
- (void)removeMessagesObject:(FCMessages *)value;
- (void)addMessages:(NSSet<FCMessages *> *)values;
- (void)removeMessages:(NSSet<FCMessages *> *)values;
- (FCConversations*) primaryConversation;
- (BOOL) isActiveChannel;
- (BOOL)hasAtleastATag:(NSArray *) tags;
- (NSInteger)unreadCount;

@end

@interface FCChannelInfo : NSObject

@property (nonatomic, strong) NSData *icon;
@property (nonatomic, strong) NSString *iconURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *channelID;
@property (nonatomic) NSInteger unreadMessages;

-(FCChannelInfo *)initWithChannel:(FCChannels *)channel;

@end

NS_ASSUME_NONNULL_END
