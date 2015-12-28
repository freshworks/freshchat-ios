//
//  KonotorConversation.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorConversation.h"
#import "KonotorDataManager.h"
#import "KonotorApp.h"
#import "KonotorUtil.h"
#import "KonotorMessage.h"
#import "Konotor.h"
#import "HLMessageServices.h"
#import "HLMacros.h"

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

static BOOL DOWNLOAD_IN_PROGRESS = NO;

NSMutableDictionary* gkConversationIdConversationMap;

-(void)incrementUnreadCount{
    int unread = self.unreadMessagesCount.intValue;
    unread++;
    self.unreadMessagesCount = @(unread);
    [KonotorUtil PostNotificationWithName:@"KonotorUnreadMessagesCount" withObject:[NSNumber numberWithInt:unread]];
    [[KonotorDataManager sharedInstance]save];
}

-(void)decrementUnreadCount{
    int unread = [[self unreadMessagesCount]intValue];
    if(unread > 0){
        unread--;
    }
    [self setUnreadMessagesCount:[NSNumber numberWithInt:unread]];
    [KonotorUtil PostNotificationWithName:@"KonotorUnreadMessagesCount" withObject:[NSNumber numberWithInt:unread]];
    [[KonotorDataManager sharedInstance]save];
}

+(KonotorConversation *) RetriveConversationForConversationId: (NSString *)conversationId
{
    if(gkConversationIdConversationMap)
    {
        KonotorConversation *conversation = [gkConversationIdConversationMap objectForKey:conversationId];
        if(conversation)
            return conversation;
    }
    
    if(!gkConversationIdConversationMap)
    {
        gkConversationIdConversationMap = [[ NSMutableDictionary alloc]init];
    }
    
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorConversation" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"conversationAlias == %@",conversationId];
    
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    
    if([array count]==0) return nil;
    
    if([array count] >1)
        NSLog(@"%@", @"Multiple Messages stored with the same message Id");
    
    else if([array count]==1)
    {
        KonotorConversation *conversation = [array objectAtIndex:0];
        if(conversation)
        {
            [gkConversationIdConversationMap setObject:conversation forKey:conversationId];
            return conversation;
        }
    }
    return nil;
}

+(void) CreateDefaultConversation
{
    KonotorConversation *pDefaultConvo = (KonotorConversation *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorConversation" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
    

    NSString *convoid = [NSString stringWithFormat:@"%@_%@_%@",[KonotorApp GetAppID],[KonotorUser GetUserAlias],@"feedback"];
    pDefaultConvo.conversationAlias = convoid;
    
    KonotorUser* pUser = [KonotorUser GetCurrentlyLoggedInUser];
    if(pUser)
    {
        [pUser
         setValue:pDefaultConvo forKey:@"defaultConversation"];
        
        NSMutableSet *SetToWhichConversationsAreToBeAdded = [pUser mutableSetValueForKey:@"hasConversations"];
        
        [SetToWhichConversationsAreToBeAdded addObject:pDefaultConvo];
    }
    [[KonotorDataManager sharedInstance]save];
}

+(void) DownloadAllMessages{
    FDLog(@"download message called");
    
    if (DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download message in progress, so skip");
        return;
    }
    
    if(![KonotorUser isUserCreatedOnServer]){
        [KonotorUser CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:@selector(DownloadAllMessages) withObject:[KonotorConversation class] withSuccessParameter:nil ifFailure:nil withObject:nil withFailureParameter:nil];
        return;
    }
    
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    HLMessageServices *messageService = [[HLMessageServices alloc]init];
    [messageService fetchAllChannels:^(NSArray<HLChannel *> *channels, NSError *error) {
        [KonotorConversation fetchAllMessagesInChannel:channels];
    }];
}

+ (void)fetchAllMessagesInChannel:(NSArray *)channels{

    NSString *pBasePath = [KonotorUtil GetBaseURL];
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];
    
    NSNumber* timestamp = [KonotorApp getLastUpdatedConversationsTimeStamp];
    
    NSString *getPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",pBasePath,@"services/app/",app,@"/user/",user,@"/conversation/v2?t=",token,@"&messageAfter=",timestamp];

    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:getPath parameters:nil];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        int statusCode = (int)[httpResponse statusCode];
        
        if(error || statusCode >= 400){
            [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
            [Konotor performSelector:@selector(conversationsDownloadFailed)];
            return;
            
        }else{
            
            [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
            id JSON  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&error];
            NSDictionary *toplevel = [NSDictionary dictionaryWithDictionary:JSON];
            if(!toplevel){
                [Konotor performSelector:@selector(conversationsDownloaded)];
                return;
            }
            
            NSMutableArray *pArrayOfConversations = [NSMutableArray arrayWithArray:[toplevel valueForKey:@"conversations"]];
            NSNumber *lastUpdatedTime = [KonotorConversation getLastMessageTimeStampOfTheseConversations:pArrayOfConversations];
            
            if(lastUpdatedTime){
                [KonotorApp updateLastUpdatedConversations:lastUpdatedTime];
            }
            
            if(!pArrayOfConversations){
                [Konotor performSelector:@selector(conversationsDownloaded)];
                return;
            }
            
            DOWNLOAD_IN_PROGRESS = YES;
            
            for (int i=0; i<pArrayOfConversations.count; i++) {
                NSDictionary *conversationInfo = pArrayOfConversations[i];
                NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
                HLChannel *channel = channels[i];
                KonotorConversation *conversation = [KonotorConversation RetriveConversationForConversationId:conversationID];
                if (conversation) {
                    NSArray *messages = conversationInfo[@"messages"];
                    for (int j=0; j<messages.count; j++) {
                        NSDictionary *messageInfo = messages[j];
                        KonotorMessage *message = [KonotorMessage retriveMessageForMessageId:messageInfo[@"alias"]];
                        if (!message) {
                            KonotorMessage *newMessage = [KonotorMessage createNewMessage:messageInfo];
                            newMessage.uploadStatus = @2;
                            newMessage.belongsToConversation = conversation;
                            [conversation.belongsToChannel addMessagesObject:newMessage];
                            [conversation incrementUnreadCount];
                        }
                    }
                }else{
                    KonotorConversation *newConversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
                    NSArray *messages = conversationInfo[@"messages"];
                    for (int j=0; j<messages.count; j++) {
                        NSDictionary *messageInfo = messages[j];
                        KonotorMessage *newMessage = [KonotorMessage createNewMessage:messageInfo];
                        newMessage.uploadStatus = @2;
                        newMessage.belongsToConversation = newConversation;
                        [newConversation.belongsToChannel addMessagesObject:newMessage];
                        [channel addMessagesObject:newMessage];
                        [newConversation incrementUnreadCount];
                    }
                }
            }
            [Konotor performSelector:@selector(conversationsDownloaded)];
        }
        [[KonotorDataManager sharedInstance]save];
        DOWNLOAD_IN_PROGRESS = NO;
    }];
}

+(NSNumber *) getLastMessageTimeStampOfTheseConversations:(NSArray *) pConversations{
    if(![pConversations count])
        return nil;
    
    NSDictionary *lastConversation = [pConversations objectAtIndex:[pConversations count]-1];
    NSArray *messagesArray = [lastConversation valueForKey:@"messages"];
    if([messagesArray count]== 0)
    {
        return nil;
    }
    
    if(messagesArray)
    {
        NSDictionary *lastMessage = [messagesArray objectAtIndex:[messagesArray count]-1];
        NSNumber *timestamp = [lastMessage valueForKey:@"createdMillis"];
        
        double existingValue = [[KonotorApp getLastUpdatedConversationsTimeStamp]doubleValue];
        double newValue = [timestamp doubleValue];
        
        if(newValue > existingValue)
            return timestamp;
        
        else
            return [NSNumber numberWithDouble:existingValue];
    }
    
    return nil;

    
    
}

+(NSArray *) ReturnAllConversations{
    
    KonotorUser *pUser = [KonotorUser GetCurrentlyLoggedInUser];
    if(pUser)
    {
       
        NSSet *pConvoSet =[NSSet setWithSet:[pUser mutableSetValueForKey:@"hasConversations"]];
        NSMutableArray *pConversations = [NSMutableArray arrayWithArray:[pConvoSet allObjects]];

        if (!pConversations) {
        return nil;
        }
        
        NSMutableArray *pConversationArrayToReturn = [[NSMutableArray alloc]init];

        for(int i =0;i<[pConversations count];i++)
        {
            KonotorConversationData *conversation = [[pConversations objectAtIndex:i] ReturnConversationDataFromManagedObject] ;
            [pConversationArrayToReturn addObject:conversation];
        }

        return pConversationArrayToReturn;
        
        
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