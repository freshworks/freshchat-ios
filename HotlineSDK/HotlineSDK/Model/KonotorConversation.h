//
//  KonotorConversation.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "HLChannel.h"
#import "HLCsat.h"

@class HLCsat;

@interface KonotorConversation : NSManagedObject

NS_ASSUME_NONNULL_BEGIN

@property (nullable, nonatomic, retain) NSString *conversationAlias;
@property (nullable, nonatomic, retain) NSNumber *hasPendingCsat;
@property (nullable, nonatomic, retain) NSString *conversationHostUserAlias;
@property (nullable, nonatomic, retain) NSString *conversationHostUserId;
@property (nullable, nonatomic, retain) NSNumber *createdMillis;
@property (nullable, nonatomic, retain) NSNumber *status;
@property (nullable, nonatomic, retain) NSNumber *unreadMessagesCount;
@property (nullable, nonatomic, retain) NSNumber *updatedMillis;
@property (nullable, nonatomic, retain) HLChannel *belongsToChannel;
@property (nullable, nonatomic, retain) NSSet<KonotorMessage *> *hasMessages;
@property (nullable, nonatomic, retain) NSSet<HLCsat *> *hasCsat;

+(KonotorConversation *)createConversationWithID:(NSString *)conversationID ForChannel:(HLChannel *)channel;
+(KonotorConversation *) RetriveConversationForConversationId: (NSString *)conversationId;

@end

@interface KonotorConversation (CoreDataGeneratedAccessors)

- (void)addHasMessagesObject:(KonotorMessage *)value;
- (void)removeHasMessagesObject:(KonotorMessage *)value;
- (void)addHasMessages:(NSSet<KonotorMessage *> *)values;
- (void)removeHasMessages:(NSSet<KonotorMessage *> *)values;
- (BOOL)isCSATResponsePending;


@end

@interface KonotorConversationData : NSObject

@property (nullable, strong, nonatomic) NSString *conversationAlias;
@property (nullable, strong, nonatomic) NSNumber *lastUpdated;
@property (nullable, strong, nonatomic) NSNumber *unreadMessagesCount;

@end

NS_ASSUME_NONNULL_END
