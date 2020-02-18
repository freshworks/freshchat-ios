//
//  KonotorConversation.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "FCConversations.h"
#import "FCDataManager.h"
#import "FCMessages.h"
#import "FCMessageHelper.h"
#import "FCMessageServices.h"
#import "FCMacros.h"
#import "FCSecureStore.h"
#import "FCUtilities.h"
#import "FCLocalNotification.h"

@class KonotorConversationData;
@class KonotorMessageData;

@implementation FCConversations

@dynamic conversationAlias;
@dynamic conversationHostUserAlias;
@dynamic conversationHostUserId;
@dynamic createdMillis;
@dynamic status;
@dynamic unreadMessagesCount;
@dynamic updatedMillis;
@dynamic belongsToChannel;
@dynamic hasMessages;
@dynamic hasCsat;
@dynamic hasPendingCsat;

+(FCConversations *) RetriveConversationForConversationId: (NSString *)conversationId{
    NSError *pError;
    FCConversations *conversation = nil;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    @try {
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_CONVERSATIONS_ENTITY inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
        [request setEntity:entityDescription];
        
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"conversationAlias == %@",conversationId];
        
        [request setPredicate:predicate];
        
        NSArray *array = [context executeFetchRequest:request error:&pError];
        if(!pError){
            if([array count]==0) return nil;
            
            if([array count] >1){
                FDLog(@"%@", @"Multiple conversations stored with the same ID");
            } else if([array count]==1){
                conversation = [array objectAtIndex:0];
            }
        }
        else {
            FDLog(@"Failed to fetch conversation %@",pError);
        }
    } @catch (NSException *exception) {
        NSString *exceptionDesc = [NSString stringWithFormat:@"COREDATA_EXCEPTION: %@", exception.description];
        FDLog(@"Error in retrieving properties from table : %@ %@", FRESHCHAT_CONVERSATIONS_ENTITY, exceptionDesc);
    }
    return conversation;
}

-(KonotorConversationData *) ReturnConversationDataFromManagedObject
{
    KonotorConversationData *conversation = [[KonotorConversationData alloc]init];
    conversation.conversationAlias = [self conversationAlias];
    conversation.lastUpdated = [self updatedMillis];
    conversation.unreadMessagesCount = [self unreadMessagesCount];
    return conversation;
    
}

+(FCConversations *)createConversationWithID:(NSString *)conversationID ForChannel:(FCChannels *)channel{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    FCConversations *newConversation = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_CONVERSATIONS_ENTITY inManagedObjectContext:context];

    newConversation.conversationAlias = conversationID;

    if (channel) {
        newConversation.belongsToChannel = channel;
    }
    
    return newConversation;
}

-(BOOL)isCSATResponsePending{
    FCCsat *csat = self.hasCsat.allObjects.firstObject;
    return (self.hasPendingCsat.boolValue && csat &&
            csat.csatStatus.integerValue == CSAT_NOT_RATED);
}

@end

@implementation KonotorConversationData

@end
