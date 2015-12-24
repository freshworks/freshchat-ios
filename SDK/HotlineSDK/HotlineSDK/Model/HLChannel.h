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

NS_ASSUME_NONNULL_BEGIN

@interface HLChannel : NSManagedObject

@property (nullable, nonatomic, retain) NSNumber *channelID;
@property (nullable, nonatomic, retain) NSDate *created;
@property (nullable, nonatomic, retain) NSData *icon;
@property (nullable, nonatomic, retain) NSString *iconURL;
@property (nullable, nonatomic, retain) NSNumber *isHidden;
@property (nullable, nonatomic, retain) NSDate *lastUpdated;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *position;
@property (nullable, nonatomic, retain) NSSet<KonotorConversation *> *conversations;
@property (nullable, nonatomic, retain) NSSet<KonotorMessage *> *messages;

+(HLChannel *)getWithID:(NSNumber *)channelID inContext:(NSManagedObjectContext *)context;
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

@end

NS_ASSUME_NONNULL_END
