//
//  FCCSATUtil.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 24/07/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCCSATUtil.h"
#import "FCRemoteConfig.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCEventsHelper.h"

@implementation FCCSATUtil

+ (void)deleteExpiredCSAT{
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CSAT_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"csatStatus == %d", CSAT_NOT_RATED];
        NSArray *results = [context executeFetchRequest:fetchRequest error:nil];
        FDLog(@"There are %d unuploaded CSATs", (int)results.count);
        for (FCCsat *csat in results) {
            if([FCCSATUtil isCSATExpiredForInitiatedTime:[csat.initiatedTime longValue]]){
                //expired csat
                NSMutableDictionary *eventsDict = [[NSMutableDictionary alloc] init];
                if(csat.belongToConversation.belongsToChannel.channelAlias){
                    [eventsDict setObject:csat.belongToConversation.belongsToChannel.channelAlias forKey:@(FCPropertyChannelID)];
                }
                [eventsDict setObject:csat.belongToConversation.belongsToChannel.name forKey:@(FCPropertyChannelName)];
                [eventsDict setObject:csat.belongToConversation.conversationAlias forKey:@(FCPropertyConversationID)];
                FCOutboundEvent *outEvent = [[FCOutboundEvent alloc] initOutboundEvent:FCEventCSatExpiry
                                                                           withParams:eventsDict];
                [FCEventsHelper postNotificationForEvent:outEvent];
                [FCCSATUtil deleteCSATAndUpdateConversation:csat];
            }
        }
    }];
}

+ (void) deleteCSATAndUpdateConversation : (FCCsat *) csat {
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        FCConversations *conversation = [FCConversations RetriveConversationForConversationId:csat.belongToConversation.conversationAlias];
        @try {
            conversation.hasPendingCsat = @0;
            [context deleteObject:csat];
            [context save:nil];
        }
        @catch(NSException *exception) {
            FDLog(@"Error in updating csat %@",exception.description);
        }
    }];
}

+(BOOL) isCSATExpiredForInitiatedTime : (long)initiatedTime{
    
    if([FCRemoteConfig sharedInstance].csatSettings.isUserCsatViewTimerEnabled){
        NSTimeInterval currentRequestTime = [FCUtilities getCurrentTimeInMillis];
        long timeInteval = currentRequestTime - initiatedTime;
        long expiryTime = [FCRemoteConfig sharedInstance].csatSettings.maximumUserSurveyViewMillis;
        
        return ((timeInteval > expiryTime) ? TRUE : FALSE);
    }
    return FALSE;
}

@end
