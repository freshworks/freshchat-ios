//
//  KonotorConversation.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KonotorUser.h"


@interface KonotorConversation : NSManagedObject

@property (nonatomic, retain) NSSet *hasMessages;
@property (nonatomic, retain) NSString * conversationAlias;
@property (nonatomic, retain) NSNumber *createdMillis;
@property (nonatomic, retain) NSNumber *updatedMillis;
@property (nonatomic, retain) NSNumber *unreadMessagesCount;

+(void) CreateDefaultConversation;
+(void) DownloadAllMessages;
+(NSArray *) ReturnAllConversations;
+(KonotorConversation *) RetriveConversationForConversationId: (NSString *)conversationId;
@end

@interface KonotorConversation (CoreDataGeneratedAccessors)


- (void)addHasMessagesObject:(NSManagedObject *)value;
- (void)removeHasMessagesObject:(NSManagedObject *)value;
- (void)addHasMessages:(NSSet *)values;
- (void)removeHasMessages:(NSSet *)values;
-(void) incrementUnreadCount;
-(void) decrementUnreadCount;

@end
