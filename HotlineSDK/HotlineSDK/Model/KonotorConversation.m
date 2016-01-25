//
//  KonotorConversation.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorConversation.h"
#import "KonotorDataManager.h"
#import "KonotorMessage.h"
#import "Konotor.h"
#import "HLMessageServices.h"
#import "HLMacros.h"
#import "FDSecureStore.h"
#import "FDUtilities.h"
#import "FDLocalNotification.h"

@class KonotorConversationData;
@class KonotorMessageData;

@implementation KonotorConversation

@dynamic conversationAlias;
@dynamic conversationHostUserAlias;
@dynamic conversationHostUserId;
@dynamic createdMillis;
@dynamic status;
@dynamic unreadMessagesCount;
@dynamic updatedMillis;
@dynamic belongsToChannel;
@dynamic hasMessages;

-(void)incrementUnreadCount{
    int unread = self.unreadMessagesCount.intValue;
    unread++;
    self.unreadMessagesCount = @(unread);
    [FDUtilities PostNotificationWithName:HOTLINE_UNREAD_MESSAGE_COUNT withObject:[NSNumber numberWithInt:unread]];
    [[KonotorDataManager sharedInstance]save];
}

-(void)decrementUnreadCount{
    int unread = [[self unreadMessagesCount]intValue];
    if(unread > 0){
        unread--;
    }
    [self setUnreadMessagesCount:[NSNumber numberWithInt:unread]];
    [FDUtilities PostNotificationWithName:HOTLINE_UNREAD_MESSAGE_COUNT withObject:[NSNumber numberWithInt:unread]];
    [[KonotorDataManager sharedInstance]save];
}

+(KonotorConversation *) RetriveConversationForConversationId: (NSString *)conversationId{
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorConversation" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"conversationAlias == %@",conversationId];
    
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    
    if([array count]==0) return nil;
    
    if([array count] >1){
        FDLog(@"%@", @"Multiple conversations stored with the same ID");
    }
    
    else if([array count]==1){
        KonotorConversation *conversation = [array objectAtIndex:0];
        if(conversation){
            return conversation;
        }
    }
    return nil;
}

-(KonotorConversationData *) ReturnConversationDataFromManagedObject
{
    KonotorConversationData *conversation = [[KonotorConversationData alloc]init];
    conversation.conversationAlias = [self conversationAlias];
    conversation.lastUpdated = [self updatedMillis];
    conversation.unreadMessagesCount = [self unreadMessagesCount];
    return conversation;
    
}

+(KonotorConversation *)createConversationWithID:(NSString *)conversationID ForChannel:(HLChannel *)channel{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    KonotorConversation *newConversation = [NSEntityDescription insertNewObjectForEntityForName:@"KonotorConversation" inManagedObjectContext:context];

    newConversation.conversationAlias = conversationID;

    if (channel) {
        newConversation.belongsToChannel = channel;
    }
    
    return newConversation;
}

@end