//
//  HLChannel.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KonotorConversation, KonotorMessage;

#define CHANNEL_TYPE_AGENT_ONLY @"AGENT_ONLY"
#define CHANNEL_TYPE_USER_ONLY @"USER_ONLY"
#define CHANNEL_TYPE_BOTH @"BOTH"

NS_ASSUME_NONNULL_BEGIN

@interface HLChannel : NSManagedObject

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
@property (nullable, nonatomic, retain) NSSet<KonotorConversation *> *conversations;
@property (nullable, nonatomic, retain) NSSet<KonotorMessage *> *messages;

+(HLChannel *)getWithID:(NSNumber *)channelID inContext:(NSManagedObjectContext *)context;
+(HLChannel *)getWithName:(NSString *)name inContext:(NSManagedObjectContext *)context;
+(HLChannel *)getDefaultChannelInContext:(NSManagedObjectContext *)context;

+(HLChannel *)createWithInfo:(NSDictionary *)channelInfo inContext:(NSManagedObjectContext *)context;
+(HLChannel *)updateChannel:(HLChannel *)channel withInfo:(NSDictionary *)channelInfo;

@end

@interface HLChannel (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(KonotorConversation *)value;
- (void)removeConversationsObject:(KonotorConversation *)value;
- (void)addConversations:(NSSet<KonotorConversation *> *)values;
- (void)removeConversations:(NSSet<KonotorConversation *> *)values;

- (void)addMessagesObject:(KonotorMessage *)value;
- (void)removeMessagesObject:(KonotorMessage *)value;
- (void)addMessages:(NSSet<KonotorMessage *> *)values;
- (void)removeMessages:(NSSet<KonotorMessage *> *)values;
- (KonotorConversation*) primaryConversation;
- (BOOL) isActiveChannel;
- (BOOL)hasAtleastATag:(NSArray *) tags;
- (NSInteger)unreadCount;

@end

@interface HLChannelInfo : NSObject

@property (nonatomic, strong) NSData *icon;
@property (nonatomic, strong) NSString *iconURL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *channelID;
@property (nonatomic) NSInteger unreadMessages;

-(HLChannelInfo *)initWithChannel:(HLChannel *)channel;

@end

NS_ASSUME_NONNULL_END
