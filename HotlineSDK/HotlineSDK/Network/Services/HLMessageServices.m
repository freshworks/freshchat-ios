//
//  HLMessageServices.m
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLMessageServices.h"
#import "HLAPIClient.h"
#import "HLServiceRequest.h"
#import "HLMacros.h"
#import "FDSecureStore.h"
#import "KonotorDataManager.h"
#import "HLAPI.h"
#import "FDLocalNotification.h"
#import "KonotorConversation.h"
#import "FDUtilities.h"
#import "Konotor.h"
#import "KonotorMessage.h"
#import "FDResponseInfo.h"
#import "FDBackgroundTaskManager.h"
#import "FDDateUtil.h"
#import "HLNotificationHandler.h"
#import "FDChannelUpdater.h"
#import "FDMessagesUpdater.h"
#import "FDMemLogger.h"
#import "FDLocalNotification.h"
#import "HLTags.h"
#import "HLEventManager.h"
#import "HLCoreServices.h"

#define ERROR_CODE_USER_NOT_CREATED -1

static HLNotificationHandler *handleUpdateNotification;

@implementation HLMessageServices

+(void)fetchChannelsAndMessages:(void (^)(NSError *))handler{

    static BOOL MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
    
    if (MESSAGES_DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download message in progress, so skip");
        if(handler){
            handler(nil);
        }
        return;
    }
    
    ShowNetworkActivityIndicator();
    MESSAGES_DOWNLOAD_IN_PROGRESS = YES;
    
    [[FDChannelUpdater new]fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
        if (!error) {
            [[FDMessagesUpdater new]fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
                if(handler) handler(error);
                HideNetworkActivityIndicator();
                MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
            }];
        }else{
            if (handler) handler(error);
            HideNetworkActivityIndicator();
            MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
        }
    }];
    
}


+(void)fetchMessages:(void(^)(NSError *error))handler{
        FDSecureStore *store = [FDSecureStore sharedInstance];
        NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
        NSString *userAlias = [FDUtilities getUserAlias];
        NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
        HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
        __block NSNumber *lastUpdateTime = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_SERVER_TIME];
        NSString *path = [NSString stringWithFormat:HOTLINE_API_DOWNLOAD_ALL_MESSAGES_API, appID,userAlias];
        NSString *afterTime = [NSString stringWithFormat:@"messageAfter=%@",lastUpdateTime];
        [request setRelativePath:path andURLParams:@[appKey, @"tags=true", afterTime]];
        
        [[HLAPIClient sharedInstance] request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
            dispatch_async(dispatch_get_main_queue(),^{
            if (!error) {
                NSDictionary *response = responseInfo.responseAsDictionary;
                NSArray *conversations = response[@"conversations"];
                
                if(!response || !conversations){
                    FDMemLogger *memLogger = [[FDMemLogger alloc]init];
                    [memLogger addMessage:@"Empty response from server when fetching messages"
                           withMethodName:NSStringFromSelector(_cmd)];
                    [memLogger upload];
                    handler([NSError errorWithDomain:@"HOTLINE_ERROR_DOMAIN" code:1000 userInfo:@{@"Reason" : @"Empty response !!!"}]);
                    return;
                }
                
                FDLog(@"%lu Conversations created locally", (unsigned long)conversations.count);
                
                NSNumber *channelId;
                
                //Check if we have all the channels locally
                BOOL channelPresent=YES;
                for (int i=0; i<conversations.count; i++) {
                    NSDictionary *conversationInfo = conversations[i];
                    channelId = conversationInfo[@"channelId"];
                    HLChannel *channel = [HLChannel getWithID:channelId inContext:[KonotorDataManager sharedInstance].mainObjectContext];
                    
                    if (!channel) {
                        // Channel does not exist; reset channel interval key to force fetch channels
                        // skipping fetched msg import to DB in the current run.
                        [[FDChannelUpdater new]resetTime];
                        channelPresent = NO;
                        break;
                    }
                }
                
                
                if(!channelPresent){
                    [[[FDChannelUpdater alloc]init]fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
                        if(!error){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self processMessageResponse:response];
                                if(handler) handler(nil);
                            });
                        }
                        else {
                            if(handler)handler(error);
                        }
                    }];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self processMessageResponse:response];
                        if(handler) handler(nil);
                    });
                }
            }else{
                [Konotor performSelectorOnMainThread:@selector(conversationsDownloadFailed) withObject: nil waitUntilDone:NO];
                if(handler) handler(error);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self postUnreadCountNotification];
            });
        });
    }];
}

+(BOOL)processMessageResponse:(NSDictionary *)response{
    NSNumber *channelId;
    NSString *messageText;
    BOOL isRestore = [[FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_INTERVAL_TIME] isEqualToNumber:@0];
    __block NSNumber *lastUpdateTime = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_SERVER_TIME];
    NSArray *conversations = response[@"conversations"];
    for (int i=0; i<conversations.count; i++) {
        NSDictionary *conversationInfo = conversations[i];
        channelId = conversationInfo[@"channelId"];
        HLChannel *channel = [HLChannel getWithID:channelId inContext:[KonotorDataManager sharedInstance].mainObjectContext];
        
        NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
        
        KonotorConversation *conversation = [KonotorConversation RetriveConversationForConversationId:conversationID];
        
        [self processCSATForConversation:conversation withInfo:conversationInfo];
        
        NSArray *messages = conversationInfo[@"messages"];
        for (int j=0; j<messages.count; j++) {
            __block NSDictionary *messageInfo = messages[j];
            KonotorMessage *message = [KonotorMessage retriveMessageForMessageId:messageInfo[@"alias"]];
            lastUpdateTime = [FDDateUtil maxDateOfNumber:lastUpdateTime andStr:messageInfo[@"createdMillis"]];
            if (!message) {
                KonotorMessage *newMessage = [KonotorMessage createNewMessage:messageInfo];
                newMessage.uploadStatus = @2;
                
                if (channel) {
                    newMessage.belongsToChannel = channel;
                }
                
                if (!conversation) {
                    conversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
                }
                
                if(conversation){
                    newMessage.belongsToConversation = conversation;
                }
                
                //Do not mark restored mesages as unread
                if (isRestore) {
                    newMessage.messageRead = YES;
                }else {
                    if([newMessage.messageType intValue] == KonotorMessageTypeText){
                        messageText = newMessage.text;
                    }
                }
            }
        }
        
        if(!isRestore && ![HLNotificationHandler areNotificationsEnabled] && messageText){
            handleUpdateNotification = [[HLNotificationHandler alloc] init];
            [handleUpdateNotification showActiveStateNotificationBanner:channel withMessage:messageText];
        }
        
    }
    
    [[KonotorDataManager sharedInstance]save];
    [[FDSecureStore sharedInstance] setObject:lastUpdateTime forKey:HOTLINE_DEFAULTS_CONVERSATIONS_LAST_UPDATED_SERVER_TIME];
    [FDLocalNotification post:HOTLINE_MESSAGES_DOWNLOADED];
    [Konotor performSelectorOnMainThread:@selector(conversationsDownloaded) withObject: nil waitUntilDone:NO];
    return true;
}

+(void)processCSATForConversation:(KonotorConversation *)conversation withInfo:(NSDictionary *)conversationInfo{
    if ([conversationInfo objectForKey:@"hasPendingCsat"]) {
        conversation.hasPendingCsat = @([conversationInfo[@"hasPendingCsat"] boolValue]);
        if ([conversationInfo objectForKey:@"csat"]) {
            
            if ([conversationInfo[@"hasPendingCsat"] boolValue]) {
                FDLog(@"*** CSAT for Conversation ID :%@ is pending ***", conversationInfo[@"conversationId"]);
            }

            NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
            NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
            HLCsat *csat = [HLCsat getWithID:conversationID inContext:context];
            
            FDLog(@"Conversation : %@", conversationInfo);
            
            if (!csat) {
                csat = [HLCsat createWithInfo:conversationInfo inContext:context];
                FDLog(@"Added a new CSAT entry\n %@", conversationInfo[@"csat"]);
                if(![HLNotificationHandler areNotificationsEnabled]) {
                    handleUpdateNotification = [[HLNotificationHandler alloc] init];
                    HLChannel *channel = [HLChannel getWithID:conversationInfo[@"channelId"] inContext:[KonotorDataManager sharedInstance].mainObjectContext];
                    [handleUpdateNotification showActiveStateNotificationBanner:channel withMessage:[conversationInfo valueForKeyPath:@"csat.question"]];
                }
            }else{
                csat = [HLCsat updateCSAT:csat withInfo:conversationInfo];
            }
            
            csat.belongToConversation = conversation;
        }
    }
}

+(void)postUnreadCountNotification{
    NSInteger unreadCount = [[Hotline sharedInstance]unreadCount];
    [FDLocalNotification post:HOTLINE_UNREAD_MESSAGE_COUNT info:@{ @"count" : @(unreadCount)}];
}

/* fetches channel list, updates existing channels including hidden channels */
+(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<HLChannel *> *channels, NSError *error))handler{
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    //TODO: This is repeated multitimes. Needs refactor.
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CHANNELS_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    NSNumber *lastUpdateTime = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_SERVER_TIME];
    NSString *afterTime = [NSString stringWithFormat:@"after=%@",lastUpdateTime];
    BOOL isRestore = [lastUpdateTime isEqualToNumber:@0];
    [request setRelativePath:path andURLParams:@[token, @"tags=true", afterTime]];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            /* This check is added to delete all messages that are migrated from konotor SDK,
               but this is also performed for new installs as well (a harmless side-effect). */
            
            if (isRestore) {
                [[KonotorDataManager sharedInstance]deleteAllMessages:^(NSError *error) {
                    [self importChannels:[responseInfo responseAsArray] handler:handler];
                }];
            }else{
                [self importChannels:[responseInfo responseAsArray] handler:handler];
            }
        }else{
            if (handler) handler(nil, error);
            FDLog(@"channel fetch failed :%@ \n response : %@",error, responseInfo.response);
        }
    }];
    return task;
}

+(void)importChannels:(NSArray *)channels handler:(void (^)(NSArray *channels, NSError *error))handler;{
    NSMutableArray *channelList = [NSMutableArray new];
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSNumber *lastUpdatedTime = [FDUtilities getLastUpdatedTimeForKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_SERVER_TIME];
        NSInteger channelCount = [channels count];
        HLChannel *channel = nil;
        if (channelCount!=0) {
            for(int i=0; i<channels.count; i++){
                NSDictionary *channelInfo = channels[i];
                channel = [HLChannel getWithID:channelInfo[@"channelId"] inContext:context];
                [HLTags removeTagsForTaggableId:channelInfo[@"channelId"] andType:[NSNumber numberWithInt: HLTagTypeChannel] inContext:context];
                NSArray *tags = channelInfo[@"tags"];
                if(tags.count >0){
                    if(!([channelInfo[@"hidden"] boolValue])){
                        for(NSString *tagName in tags){
                            [HLTags createTagWithInfo:[HLTags createDictWithTagName:tagName type:[NSNumber numberWithInt: HLTagTypeChannel] andIdvalue:channelInfo[@"channelId"]] inContext:context];
                        }
                    }
                }
                
                if (channel) {
                    [HLChannel updateChannel:channel withInfo:channelInfo];
                    FDLog(@"Channel updated ID:%@ name:%@", channel.channelID , channel.name);
                }else{
                    channel = [HLChannel createWithInfo:channelInfo inContext:context];
                    FDLog(@"Channel created ID:%@ name:%@", channel.channelID , channel.name);
                }
                
                if (channel) {
                    [channelList addObject:channel];
                }
                
                if(channelInfo[@"updated"]){
                    lastUpdatedTime = [FDDateUtil maxDateOfNumber:lastUpdatedTime andStr:channelInfo[@"updated"]];
                }
            }
        }
        [[FDSecureStore sharedInstance] setObject:lastUpdatedTime forKey:HOTLINE_DEFAULTS_CHANNELS_LAST_UPDATED_SERVER_TIME];
        [context save:nil];
        if (handler) handler(channelList,nil);
        [FDLocalNotification post:HOTLINE_CHANNELS_UPDATED];
    }];
}

//TODO: Temproary hack to avoid user registration occuring parallely

+(void)uploadMessage:(KonotorMessage *)pMessage toConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel{
    
    //Added this to simulate sending unregistered user alias for message create call
//    [[FDSecureStore sharedInstance] setObject:@"asdf-adf-asdf-asdf" forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    
    if(![pMessage isMarkedForUpload]){
        pMessage.isMarkedForUpload = YES;
        [[KonotorDataManager sharedInstance]save];
    }
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];

    __block NSString *messageAlias = pMessage.messageAlias;
    
    if([[pMessage uploadStatus]intValue] == MESSAGE_UPLOADED || [[pMessage uploadStatus]intValue] == MESSAGE_UPLOADING){
        return;
    }else{
        pMessage.uploadStatus = @(MESSAGE_UPLOADING);
        [[KonotorDataManager sharedInstance]save];
    }
        
    HLServiceRequest *request = [[HLServiceRequest alloc]initMultipartFormRequestWithBody:^(id<HLMultipartFormData> formData) {
        [formData addPart:[[pMessage getJSON] dataUsingEncoding:NSUTF8StringEncoding] name:@"message"];
        
        if (channel.channelID) {
            [formData addTextPart:channel.channelID.stringValue name:@"channelId"];
        }else{
            FDLog(@"Message sending without channel ID");
        }
        
        if (conversation.conversationAlias) {
            [formData addTextPart:conversation.conversationAlias name:@"conversationId"];
        }else{
            FDLog(@"Message sending without conversation ID");
        }
        
        //Audio message
        if([[pMessage messageType]intValue]== 2){
            KonotorMessageBinary *pBinary = (KonotorMessageBinary*)[pMessage valueForKeyPath:@"hasMessageBinary"];
            
            if(pBinary){
                [formData addFilePart:[pBinary binaryAudio] name:@"file" fileName:@"file2" mimeType:@"application/octet-stream"];
            }
        }
        
        //Picture message
        if([[pMessage messageType]intValue]== 3) {
            KonotorMessageBinary *pBinary = (KonotorMessageBinary*)[pMessage valueForKeyPath:@"hasMessageBinary"];
            
            if(pBinary){
                [formData addFilePart:[pBinary binaryImage] name:@"picFile" fileName:@".jpg" mimeType:@"image/jpeg"];
                
                if([pBinary binaryThumbnail]){
                    [formData addFilePart:[pBinary binaryThumbnail] name:@"picThumbFile" fileName:@".jpg" mimeType:@"image/jpeg"];
                }
            }
        }
        
    }];
    
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPLOAD_MESSAGE, appID,userAlias];
    
    [request setRelativePath:path andURLParams:@[token]];
    
    ShowNetworkActivityIndicator();
    UIBackgroundTaskIdentifier taskID = [[FDBackgroundTaskManager sharedInstance]beginTask];

    [[HLAPIClient sharedInstance]request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        
        NSDictionary* messageInfo = responseInfo.responseAsDictionary;
        
        [[KonotorDataManager sharedInstance].mainObjectContext performBlock:^{
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if (!error && statusCode == 201) {
                NSString *conversationID = [messageInfo[@"hostConversationId"] stringValue];
                if (!conversation || ![conversationID isEqualToString:conversation.conversationAlias]) {
                    KonotorConversation *newConversation = [KonotorConversation createConversationWithID:conversationID ForChannel:channel];
                    if(newConversation){
                        pMessage.belongsToConversation = newConversation;
                    }
                }else{
                    pMessage.belongsToConversation = conversation;
                }
                
                pMessage.uploadStatus = @(MESSAGE_UPLOADED);
                pMessage.messageAlias = messageInfo[@"alias"];
                pMessage.createdMillis = messageInfo[@"createdMillis"];
                [channel addMessagesObject:pMessage];
                [self addSentMessageEventWithChannel:channel messageAlias:pMessage.messageAlias andType:[[pMessage messageType]intValue]];
                [Konotor performSelector:@selector(UploadFinishedNotification:) withObject:messageAlias];
            }else{
                if ( error && error.code == -1009 ) {
                    [Konotor UploadFailedNotification:messageAlias];
                }
                else if( [self isUserNotCreated:responseInfo] ) {
                    [self retryUserRegistration];
                }
                else {
                    [Konotor NotifyServerError];
                }
                pMessage.uploadStatus = @(MESSAGE_NOT_UPLOADED);
                [channel addMessagesObject:pMessage];
            }
            
            [[KonotorDataManager sharedInstance]save];
            [[FDBackgroundTaskManager sharedInstance]endTask:taskID];
            HideNetworkActivityIndicator();

        }];
    }];
}

+(BOOL) isUserNotCreated : (FDResponseInfo *)responseInfo {
    return (responseInfo && [responseInfo isDict]
            && [[responseInfo responseAsDictionary][@"errorCode"] integerValue] == ERROR_CODE_USER_NOT_CREATED);
}

+(void)retryUserRegistration{
    [[FDSecureStore sharedInstance] setObject:nil forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    [[FDSecureStore sharedInstance] setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
    [FDUtilities registerUser:nil];
}

+(void) addSentMessageEventWithChannel :(HLChannel *)channel messageAlias:(NSString *)messageId andType :(int) type {
    [[HLEventManager sharedInstance] submitSDKEvent:HLEVENT_CONVERSATION_SEND_MESSAGE withBlock:^(HLEvent *event) {
        [event propKey:HLEVENT_PARAM_CHANNEL_ID andVal:[channel.channelID stringValue]];
        [event propKey:HLEVENT_PARAM_CHANNEL_NAME andVal:channel.name];
        [event propKey:HLEVENT_PARAM_MESSAGE_ALIAS andVal:messageId];
        NSString *messageType;
        switch(type){
            case 1 : messageType = HLEVENT_MESSAGE_TYPE_TEXT; break;
            case 2 : messageType = HLEVENT_MESSAGE_TYPE_AUDIO; break;
            case 3 : messageType = HLEVENT_MESSAGE_TYPE_IMAGE; break;
            default: messageType = HLEVENT_MESSAGE_TYPE_TEXT; break;
        }
        
        [event propKey:HLEVENT_PARAM_MESSAGE_TYPE andVal:messageType];
    }];
}


//TODO: Skip messages that are clicked before
+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId{
    if((marketingId == nil) || ([marketingId intValue] ==0)) return;

    FDSecureStore *store = [FDSecureStore sharedInstance];
    
    NSString *userAlias = [FDUtilities getUserAlias];
    
    if (!userAlias) return;

    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_MARKETING_MESSAGE_STATUS_UPDATE_PATH, appID,userAlias,marketingId.stringValue];
    [request setRelativePath:path andURLParams:@[@"clicked=1",appKey]];
    [[HLAPIClient sharedInstance] request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"*** Marked as Clicked *** Marketing campaign message with ID  %@", marketingId);
        }else{
            FDLog(@"Failed to register marketing message click event to server : %@", error);
        }
    }];
}

+(void)markMarketingMessageAsRead:(KonotorMessage *)message context:(NSManagedObjectContext *)context{
    if (message.messageRead == YES) return;
    
    NSNumber *marketingId = message.marketingId;
    
    if((marketingId == nil) || ([marketingId intValue] ==0)) return;
    
    message.messageRead = YES;
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];

    if (!userAlias) return;

    HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_MARKETING_MESSAGE_STATUS_UPDATE_PATH, appID,userAlias,marketingId.stringValue];
    [request setRelativePath:path andURLParams:@[@"seen=1",appKey]];
    [[HLAPIClient sharedInstance] request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
        [context performBlock:^{
            if (!error) {
                FDLog(@"*** Marked as Seen *** Marketing campaign message with ID : %@ ", marketingId);
            }else{
                FDLog(@"Failed to mark marketing msg with ID : %@ as read", marketingId);
                [message markAsUnread];
            }
            [context save:nil];
        }];
    }];
}


+(void)postCSATWithID:(NSManagedObjectID *)csatObjectID completion:(void (^)(NSError *))handler{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        
        NSError *error;
        HLCsat *csat = nil;

        if (csatObjectID) {
            csat = [context existingObjectWithID:csatObjectID error:&error];
            if (error){
                if(handler) handler([NSError new]);
                return;
            }
        }else{
            FDLog(@"CSAT Error, Nil object ID");
            if(handler) handler([NSError new]);
            return;
        }
        
        NSMutableDictionary *response = [[NSMutableDictionary alloc]init];
        
        NSString *conversationID = csat.belongToConversation.conversationAlias;
        
        NSString *csatID = csat.csatID;
        
        if (conversationID == nil || csatID == nil || conversationID.length == 0  || csatID.length == 0) {
            FDLog(@"CSAT error: Something went wrong");
            if(handler) handler([NSError new]);
            return;
        }

        response[@"csatId"] = csatID;
        
        response[@"conversationId"] = conversationID;
        
        if (csat.userRatingCount) {
            response[@"stars"] = csat.userRatingCount.stringValue;
        }
        
        if (csat.isIssueResolved) {
            response[@"issueResolved"] = csat.isIssueResolved;
        }
        
        if (csat.userComments && csat.userComments.length > 0){
            response[@"response"] = csat.userComments;
        }
        
        HLServiceRequest *request = [[HLServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
        NSString *appID = [[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_APP_ID];
        NSString *userAlias = [FDUtilities getUserAlias];
        NSString *appKey = [NSString stringWithFormat:@"t=%@",[[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
        NSString *path = [NSString stringWithFormat:HOTLINE_API_CSAT_PATH, appID, userAlias, conversationID, csatID];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"csatResponse": response} options:NSJSONWritingPrettyPrinted error:nil];
        [request setRelativePath:path andURLParams:@[appKey]];
        [[HLAPIClient sharedInstance] request:request withHandler:^(FDResponseInfo *responseInfo, NSError *error) {
            [context performBlock:^{
                NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
                if (!error && statusCode == 201) {
                    [context deleteObject:csat];
                    [context save:nil];
                    FDLog(@"*** CSAT submitted *** \n %@", response);
                }else{
                    FDLog(@"CSAT submission failed");
                }
                
                if (handler) handler(error);
            }];
        }];

    }];
}

+(void)uploadUnuploadedCSAT{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CSAT_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"csatStatus == %d", CSAT_RATED];
        NSArray *results = [context executeFetchRequest:fetchRequest error:nil];
        FDLog(@"There are %d unuploaded CSATs", (int)results.count);
        for (HLCsat *csat in results) {
            [HLMessageServices postCSATWithID:csat.objectID completion:nil];
        }

    }];
}

@end
