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

NSMutableDictionary* gkConversationIdConversationMap;

-(void) incrementUnreadCount
{
    int unread = [[self unreadMessagesCount]intValue];
    unread++;
    
    [self setUnreadMessagesCount:[NSNumber numberWithInt:unread]];
    [KonotorUtil PostNotificationWithName:@"KonotorUnreadMessagesCount" withObject:[NSNumber numberWithInt:unread]];

    [[KonotorDataManager sharedInstance]save];
}
-(void) decrementUnreadCount
{
    int unread = [[self unreadMessagesCount]intValue];
    if(unread > 0)
    {
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
    //NSLog(@"%@",[predicate description]);
    
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
    NSString *pBasePath = [KonotorUtil GetBaseURL];
    
    if(![KonotorUser isUserCreatedOnServer]){
        [KonotorUser CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:@selector(DownloadAllMessages) withObject:[KonotorConversation class] withSuccessParameter:nil ifFailure:nil withObject:nil withFailureParameter:nil];
        return;
    }
    
    if([KonotorApp areConversationsDownloading]){
        return;
    }
    
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];
    
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
    
    NSNumber* timestamp = [KonotorApp getLastUpdatedConversationsTimeStamp];

    NSString *getPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",pBasePath,@"services/app/",app,@"/user/",user,@"/conversation/v2?t=",token,@"&messageAfter=",timestamp];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:getPath parameters:nil];
    
    [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
    [KonotorApp updateConversationsDownloading:YES];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
         int statusCode = (int)[httpResponse statusCode];
         
         if(error || statusCode >= 400){
             [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
             [KonotorApp updateConversationsDownloading:NO];
             [Konotor performSelector:@selector(conversationsDownloadFailed)];
             return;
             
         }
         else {
             KonotorUser *pUser = [KonotorUser GetCurrentlyLoggedInUser];
             
             [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
             
             NSMutableArray *pArrayOfConversations;
             
             id JSON  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&error];
             
             NSDictionary *toplevel = [NSDictionary dictionaryWithDictionary:JSON];
             
             if(!toplevel){
                 [KonotorApp updateConversationsDownloading:NO];
                 [Konotor performSelector:@selector(conversationsDownloaded)];
                 return;
             }
             
             pArrayOfConversations = [NSMutableArray arrayWithArray:[toplevel valueForKey:@"conversations"]];
             
             NSNumber *lastmsgts = [KonotorConversation getLastMessageTimeStampOfTheseConversations:pArrayOfConversations];
             
             if(lastmsgts){
                 [KonotorApp updateLastUpdatedConversations:lastmsgts];
             }
                          
             if(!pArrayOfConversations){
                 [KonotorApp updateConversationsDownloading:NO];
                 [Konotor performSelector:@selector(conversationsDownloaded)];
                 return;
             }
             
             NSMutableArray *ConversationArray;
             NSSet *ConversationCollectionSet =[NSSet setWithSet:[pUser valueForKeyPath:@"hasConversations"]];
             
             if(ConversationCollectionSet){
                 ConversationArray = [NSMutableArray arrayWithArray:[ConversationCollectionSet allObjects]];
             }
             
             NSMutableSet *SetToWhichConversationsAreToBeAdded = [pUser mutableSetValueForKey:@"hasConversations"];
             
             for(KonotorConversation* conversationFromJSON in pArrayOfConversations){
                 
                 BOOL conversationFoundOnDisk = NO;
                 
                 for(KonotorConversation *conversationFromDisk in ConversationArray){
                     if([[conversationFromJSON valueForKey:@"alias"] isEqualToString: conversationFromDisk.conversationAlias]){
                         
                         conversationFoundOnDisk = YES;
                             
                         NSMutableSet *mutableSetOfExistingConversationsOnDisk = [conversationFromDisk  mutableSetValueForKey:@"hasMessages"];
                      
                         NSSet *setOfExistingMessagesOnDisk =[NSSet setWithSet:[conversationFromDisk  valueForKeyPath:@"hasMessages"]];
                         NSArray *ExistingMessagesOnDisk = [setOfExistingMessagesOnDisk allObjects];
                         
                         NSMutableArray *messagesFromJSON = [conversationFromJSON valueForKey:@"messages"];
                         
                         for(KonotorMessage *JSONMessage in messagesFromJSON){
                             BOOL messageFoundOnDisk = NO;
                             
                             for(KonotorMessage *DiskMessage in ExistingMessagesOnDisk){
                                 if([DiskMessage.messageAlias isEqualToString:[JSONMessage valueForKey:@"alias"]]){
                                     messageFoundOnDisk = YES;
                                    break;
                                 }
                             }
                             
                             if(!messageFoundOnDisk){
                                 
                                 //message not found on disk its a new message  add it to the conversation.
                                 KonotorMessage *messageToBeAdded = [KonotorMessage createNewMessage:JSONMessage];
                                 [conversationFromDisk incrementUnreadCount];
                                 [messageToBeAdded setUploadStatus:[NSNumber numberWithInt:2]];

                                 [mutableSetOfExistingConversationsOnDisk addObject:messageToBeAdded];
                                 [messageToBeAdded setValue:conversationFromDisk forKey:@"belongsToConversation"];
                             }
                         }
                         
                         break;
                     } // end of block if the sticker id matches
                     
                 }// end of loop iterating thru all collections from disk
                 
                 if(!conversationFoundOnDisk) //collection not found on disk, add to disk.
                 {
                     KonotorConversation *newConversation = [KonotorConversation CreateNewConversation:conversationFromJSON];

                     NSMutableSet *ConversationtoWhichToBeAdded = [ newConversation mutableSetValueForKey:@"hasMessages"];
                     
                     for( KonotorMessage *newMessage in [conversationFromJSON valueForKey:@"messages"]){
                         KonotorMessage *messageToBeAdded = [KonotorMessage createNewMessage:newMessage];
                         [messageToBeAdded setUploadStatus:[NSNumber numberWithInt:2]];
                         [newConversation incrementUnreadCount];

                         [ConversationtoWhichToBeAdded addObject:messageToBeAdded];
                         [messageToBeAdded setValue:newConversation forKey:@"belongsToConversation"];
                     }
                     [SetToWhichConversationsAreToBeAdded addObject:newConversation];
                 }
                 
             }//end of loop iterating through the json of collections
             [KonotorApp updateConversationsDownloading:NO];
             [Konotor performSelector:@selector(conversationsDownloaded)];
         }//end of block of successful download of json of collections
         [[KonotorDataManager sharedInstance]save];
     }];
}


+(NSNumber *) getLastMessageTimeStampOfTheseConversations:(NSArray *) pConversations
{
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
        
        //NSLog(@"%@",[timestamp description]);
        
        double existingValue = [[KonotorApp getLastUpdatedConversationsTimeStamp]doubleValue];
        double newValue = [timestamp doubleValue];
        
        if(newValue > existingValue)
            return timestamp;
        
        else
            return [NSNumber numberWithDouble:existingValue];
    }
    
    return nil;

    
    
}

+(KonotorConversation *)CreateNewConversation:(KonotorConversation *)conversation
{
    KonotorConversation *newConversation = (KonotorConversation *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorConversation" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
    
    newConversation.conversationAlias = [conversation valueForKey:@"alias"];
    
    KonotorUser *pUser = [KonotorUser GetCurrentlyLoggedInUser];

    NSMutableSet *SetToWhichConversationsAreToBeAdded = [pUser mutableSetValueForKey:@"hasConversations"];

    [SetToWhichConversationsAreToBeAdded addObject:newConversation];

    [[KonotorDataManager sharedInstance]save];
    return newConversation;
    
    

}


+(NSArray *) ReturnAllConversations
{
    
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
    KonotorConversation *newConversation = (KonotorConversation *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorConversation" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
    newConversation.conversationAlias = conversationID;
    newConversation.belongsToChannel = channel;    
    [[KonotorDataManager sharedInstance]save];
    return newConversation;
}


@end
