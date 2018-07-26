//
//  KonotorConversation.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FCChannels.h"
#import "FCCsat.h"

@class FCCsat;

@interface FCConversations : NSManagedObject

NS_ASSUME_NONNULL_BEGIN

@property (nullable, nonatomic, retain) NSString *conversationAlias;
@property (nullable, nonatomic, retain) NSNumber *hasPendingCsat;
@property (nullable, nonatomic, retain) NSString *conversationHostUserAlias;
@property (nullable, nonatomic, retain) NSString *conversationHostUserId;
@property (nullable, nonatomic, retain) NSNumber *createdMillis;
@property (nullable, nonatomic, retain) NSNumber *status;
@property (nullable, nonatomic, retain) NSNumber *unreadMessagesCount;
@property (nullable, nonatomic, retain) NSNumber *updatedMillis;
@property (nullable, nonatomic, retain) FCChannels *belongsToChannel;
@property (nullable, nonatomic, retain) NSSet<FCMessages *> *hasMessages;
@property (nullable, nonatomic, retain) NSSet<FCCsat *> *hasCsat;

+(FCConversations *)createConversationWithID:(NSString *)conversationID ForChannel:(FCChannels *)channel;
+(FCConversations *) RetriveConversationForConversationId: (NSString *)conversationId;

@end

@interface FCConversations (CoreDataGeneratedAccessors)

- (void)addHasMessagesObject:(FCMessages *)value;
- (void)removeHasMessagesObject:(FCMessages *)value;
- (void)addHasMessages:(NSSet<FCMessages *> *)values;
- (void)removeHasMessages:(NSSet<FCMessages *> *)values;
- (BOOL)isCSATResponsePending;


@end

@interface KonotorConversationData : NSObject

@property (nullable, strong, nonatomic) NSString *conversationAlias;
@property (nullable, strong, nonatomic) NSNumber *lastUpdated;
@property (nullable, strong, nonatomic) NSNumber *unreadMessagesCount;

@end

NS_ASSUME_NONNULL_END
