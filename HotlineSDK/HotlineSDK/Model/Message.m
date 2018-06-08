//
//  Message.m
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "Message.h"

@implementation Message

    @dynamic channelId;
    @dynamic conversationId;
    @dynamic createdMillis;
    @dynamic marketingId;
    @dynamic messageAlias;
    @dynamic messageUserAlias;
    @dynamic messageUserType;
    @dynamic isMarkedForUpload;
    @dynamic isWelcomeMessage;
    @dynamic isRead;
    @dynamic belongsToChannel;
    @dynamic belongsToConversation;
    @dynamic uploadStatus;
    @dynamic isDownloading;

    static BOOL messageExistsDirty = YES;
    static BOOL messageTimeDirty = YES;

+(NSString *) generateMessageID {
    NSTimeInterval  today = [[NSDate date] timeIntervalSince1970];
    NSString *userAlias = [FDUtilities getUserAliasWithCreate];
    NSString *intervalString = [NSString stringWithFormat:@"%.0f", today*1000];
    NSString *messageID  =[NSString stringWithFormat:@"%@%@%@",userAlias,@"_",intervalString];
    return messageID;
}

+(Message *)saveMessageInCoreData:(NSArray *)fragmentsInfo onConversation:(KonotorConversation *)conversation{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_MESSAGE_ENTITY inManagedObjectContext:context];
    [message setMessageAlias:[Message generateMessageID]];
    [message setMessageUserType:USER_TYPE_MOBILE];
    [message setIsRead:YES];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    message.belongsToConversation = conversation;
    message.isWelcomeMessage = NO;
    message.isMarkedForUpload = YES;
    for(int i=0;i<fragmentsInfo.count;i++) {
        NSDictionary *fragmentInfo = fragmentsInfo[i];
        [Fragment createUploadFragment:fragmentInfo toMessage:message];
    }
    [datamanager save]; //Saves the fragment and message
    [Message markDirty];
    return message;
}

+(void) markDirty{
    messageExistsDirty = YES;
    messageTimeDirty = YES;
}

+(NSInteger)getUnreadMessagesCountForChannel:(NSNumber *)channelID{
    HLChannel *channel = [HLChannel getWithID:channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    return [channel unreadCount];
}

+(void)markAllMessagesAsReadForChannel:(HLChannel *)channel{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isRead == NO AND belongsToChannel == %@",channel];
        request.predicate = predicate;
        NSArray *messages = [context executeFetchRequest:request error:&pError];
        if (messages.count>0) {
            for(int i=0;i<messages.count;i++){
                Message *message = messages[i];
                if(message){
                    if(![[message marketingId] isEqualToNumber:@0]){
                        [HLMessageServices markMarketingMessageAsRead:message context:context];
                    }else{
                        [message markAsRead];
                    }
                }
            }
            [HLCoreServices sendLatestUserActivity:channel];
        }
        [FDUtilities postUnreadCountNotification];
        [context save:nil];
    }];
}

+(void)uploadAllUnuploadedMessages{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:HOTLINE_MESSAGE_ENTITY inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isMarkedForUpload == 1 AND uploadStatus == 0"];
        [request setPredicate:predicate];
        NSArray *array = [context executeFetchRequest:request error:&pError];
        NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
        NSArray *sortedArr = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
        if([sortedArr count]==0){
            return;
        }else{
            FDLog(@"There are %d unuploaded messages", (int)array.count);
            [HLMessageServices uploadAllUnuploadedMessages:sortedArr index:0];
        }
    }];
}

+(Message *)retriveMessageForMessageId: (NSString *)messageId{

    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:HOTLINE_MESSAGE_ENTITY inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"messageAlias == %@",messageId];
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:&pError];
    if([array count]==0){
        return nil;
    }
    
    if([array count] >1){
        return array[0];
        FDLog(@"%@", @"Multiple Messages stored with the same message Id");
    }else if([array count]==1){
        Message *message = [array objectAtIndex:0];
        if(message){
            return message;
        }
    }
    return nil;
}

-(void)associateMessageToConversation: (KonotorConversation *)conversation{
    if(conversation){
        NSMutableSet *mutableSetOfExistingConversationsOnDisk = [conversation  mutableSetValueForKey:@"hasMessages"];
        [mutableSetOfExistingConversationsOnDisk addObject:self];
        self.belongsToConversation = conversation;
        [[KonotorDataManager sharedInstance]save];
    }
}

-(NSString *)getJSON {
    NSMutableDictionary *messageDict = [[NSMutableDictionary alloc]init];
//    [messageDict setObject:[self messageType] forKey:@"messageType"];
//    if([[self messageType] intValue ]== 1)
//        [messageDict setObject:[self text] forKey:@"text"];
//    else if([[self messageType] intValue ]== 2)
//        [messageDict setObject:[self durationInSecs] forKey:@"durationInSecs"];
//    else if([[self messageType] intValue ]== 3)
//    {
//        [messageDict setObject:[self picThumbWidth] forKey:@"picThumbWidth"];
//        [messageDict setObject:[self picThumbHeight] forKey:@"picThumbHeight"];
//        [messageDict setObject:[self picHeight] forKey:@"picHeight"];
//        [messageDict setObject:[self picWidth] forKey:@"picWidth"];
//        
//        if([self picCaption])
//            [messageDict setObject:[self picCaption] forKey:@"picCaption"];
//    }
    NSError *error;
    NSData *pJsonString = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:&error];
    return [[NSString alloc ]initWithData:pJsonString encoding:NSUTF8StringEncoding];
}

-(void)markAsRead{
    [self setIsRead:YES];
}

-(void)markAsUnread{
    BOOL wasRead = [self isRead];
    if(!wasRead) return
        [self setIsRead:NO];
}

+(Message *)createNewMessage:(NSDictionary *)message toChannelID:(NSNumber *)channelId {
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    Message *newMessage = (Message *)[NSEntityDescription insertNewObjectForEntityForName:HOTLINE_MESSAGE_ENTITY inManagedObjectContext:context];
    
    if([message valueForKey:@"alias"]) {
        newMessage.isWelcomeMessage = NO;
        newMessage.messageAlias = [message valueForKey:@"alias"];
        [newMessage setMessageUserType:USER_TYPE_AGENT];
        if([message[@"readByUser"] boolValue]) {
            newMessage.isRead = YES;
        } else {
            newMessage.isRead = NO;
        }
    } else {
        newMessage.isWelcomeMessage = YES;
        newMessage.messageAlias = [NSString stringWithFormat:@"%d_welcomemessage",[channelId intValue]];
        newMessage.isRead = YES;
    }
    [newMessage setMessageUserType:[message valueForKey:@"messageUserType"]];
    [newMessage setCreatedMillis:[message valueForKey:@"createdMillis"]];
    [newMessage setMarketingId:[message valueForKey:@"marketingId"]];
    [newMessage setMessageUserAlias:[message valueForKey:@"messageUserAlias"]];
    [Fragment createFragments:[message valueForKey:@"messageFragments"] toMessage:newMessage];
    [[KonotorDataManager sharedInstance]save];
    
    [Message markDirty];
    return newMessage;
}

-(MessageData *) ReturnMessageDataFromManagedObject{
    MessageData *message = [[MessageData alloc]init];
    message.createdMillis = [self createdMillis];
    message.messageAlias =[self messageAlias];
    message.isRead = [self isRead];
    message.uploadStatus = [self uploadStatus];
    message.messageUserType = [self messageUserType];
    message.isMarketingMessage = [self isMarketingMessage];
    message.marketingId = self.marketingId;
    message.isWelcomeMessage = self.isWelcomeMessage;
    message.messageUserAlias = self.messageUserAlias;
    message.fragments = [Fragment getAllFragments:self];
    return message;
}


- (BOOL) isMarketingMessage{
    if(([[self marketingId] intValue]<=0)||(![self marketingId]))
        return NO;
    else
        return YES;
}

+(NSArray *)getAllMesssageForChannel:(HLChannel *)channel{
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    NSArray *matches = channel.messages.allObjects;
    for (int i=0; i<matches.count; i++) {
        MessageData *message = [matches[i] ReturnMessageDataFromManagedObject];
        if (message) {
            [messages addObject:message];
        }
    }  
    return messages;
}

+(Message *)getWelcomeMessageForChannel:(HLChannel *)channel{
    Message *message = nil;
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"belongsToChannel == %@ AND isWelcomeMessage == 1",channel];
    NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        message = matches.firstObject;
    }
    
    if (matches.count > 1) {
        FDLog(@"Duplicate welcome messages found for a channel");
    }
    
    return message;
}

+(void)removeWelcomeMessage:(HLChannel *)channel{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"belongsToChannel == %@ AND isWelcomeMessage == 1",channel];
    NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
    for (int i=0; i<matches.count; i++) {
        Message *message = matches[i];
        [Message removeFragmentsInMessage:message];
        [context deleteObject:message];
    }   
}

+(void) removeFragmentsInMessage:(Message *) message {
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_FRAGMENT_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"message == %@",message];
    NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
    for (int i=0; i<matches.count; i++) {
        Fragment *fragment = matches[i];
        [context deleteObject:fragment];
    }
}


+(bool) hasUserMessageInContext:(NSManagedObjectContext *)context {
    static BOOL messageExists = NO;
    if(messageExistsDirty){
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isWelcomeMessage <> 1"];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(!error){
            messageExists =  matches.count > 0;
            messageExistsDirty = NO;
        }
    }
    return messageExists;
}

+(long long) lastMessageTimeInContext:(NSManagedObjectContext *)context {
    static long long lastMessageTime = 0;
    if(messageTimeDirty){
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isWelcomeMessage <> 1"];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(!error){
            for(Message *message in matches){
                NSNumber *createdMillis = message.createdMillis;
                if( lastMessageTime < [createdMillis longLongValue] ){
                    lastMessageTime = [createdMillis longLongValue];
                }
            }
            messageTimeDirty = NO;
        }
    }
    return lastMessageTime;
}

+(long) daysSinceLastMessageInContext:(NSManagedObjectContext *)context{
    long long lastMessageTime = [Message lastMessageTimeInContext:context];
    return ([[NSDate date] timeIntervalSince1970] - (lastMessageTime/1000))/86400;
}

-(NSMutableDictionary *) convertMessageToDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"messageUserType"] = [self messageUserType];
    dict[@"createdMillis"] = [self createdMillis];
    dict[@"messageFragments"] = [Fragment getAllFragmentsInDictionary:self];
    return dict;
}

-(NSString *)getDetailDescriptionForMessage {
    NSString *description = nil;
    Fragment *fragment = [Fragment getAllFragments:self].lastObject;
    if([fragment.type isEqualToString:@"2"]) {
        description = @"📷";
    } else if([fragment.type isEqualToString:@"1"]) {
        description = fragment.content;
    } else if ([fragment.type isEqualToString:@"5"]) {
        NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
        description = extraJSONDict[@"label"];
    }
    return description;
}



@end


