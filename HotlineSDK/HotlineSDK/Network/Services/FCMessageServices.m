//
//  HLMessageServices.m
//  HotlineSDK
//
//  Created by user on 03/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCMessageServices.h"
#import "FCAPIClient.h"
#import "FCServiceRequest.h"
#import "FCMacros.h"
#import "FCSecureStore.h"
#import "FCDataManager.h"
#import "FCAPI.h"
#import "FCLocalNotification.h"
#import "FCConversations.h"
#import "FCUtilities.h"
#import "FCMessageHelper.h"
#import "FCResponseInfo.h"
#import "FCBackgroundTaskManager.h"
#import "FCDateUtil.h"
#import "FCNotificationHandler.h"
#import "FCChannelUpdater.h"
#import "FCMessagesUpdater.h"
#import "FCMemLogger.h"
#import "FCTags.h"
#import "FCCoreServices.h"
#import "FCConstants.h"
#import "FCAgentMessageCell.h"
#import "FCMessages.h"
#import "FCMessageFragments.h"
#import "FCRemoteConfig.h"
#import "FCLocaleUtil.h"
#import "FCLocaleConstants.h"
#import "FCUserDefaults.h"
#import "FCUserUtil.h"
#import "FCParticipants.h"
#import "FCCSATUtil.h"

#define ERROR_CODE_USER_NOT_CREATED 1

static FCNotificationHandler *handleUpdateNotification;

@implementation FCMessageServices
    
+(void)fetchChannelsAndMessagesWithFetchType:(enum MessageFetchType) priority
                                     source :(enum MessageRequestSource ) requestSource
                                  andHandler:(void (^)(NSError *))handler{
    static BOOL MESSAGES_DOWNLOAD_IN_PROGRESS = NO;    
    
    if(priority == OffScreenPollFetch){
        if (!([[FCRemoteConfig sharedInstance] isActiveInboxAndAccount]
              && [FCUserUtil isUserRegistered]
              && ([[FCSecureStore sharedInstance] objectForKey:FRESHCHAT_CONFIG_RC_MANUAL_CAMPAIGNS_ENABLED] || [[FCRemoteConfig sharedInstance] isActiveConvAvailable]))){
            if(handler) {
                NSError *error = [NSError errorWithDomain:@"USER_NOT_CREATED" code:1 userInfo:@{ @"Reason" : @"User not created/registered" }];
                handler(error);
            }
            return;
        }
    }
    
    if (MESSAGES_DOWNLOAD_IN_PROGRESS) {
        FDLog(@"download message in progress, so skip");
        if(handler){
            handler(nil);
        }
        return;
    }
    
    ShowNetworkActivityIndicator();
    MESSAGES_DOWNLOAD_IN_PROGRESS = YES;
    FCChannelUpdater *channelsUpdater = [FCChannelUpdater new];
    FCMessagesUpdater *messageUpdater = [FCMessagesUpdater new];
    
    switch (priority) {
        case OffScreenPollFetch:
            [messageUpdater useInterval:MESSAGES_FETCH_INTERVAL_OFF_SCREEN_POLL];
            break;
            
        case OnscreenPollFetch:
            [messageUpdater useInterval:MESSAGES_FETCH_INTERVAL_ON_SCREEN_POLL];
            break;
            
        case FetchAll:
            [channelsUpdater resetTime];
            [messageUpdater resetTime];
            break;
            
        case FetchMessages:
            [messageUpdater resetTime];
            break;
        
        case ScreenLaunchFetch:
            [messageUpdater useInterval:[FCRemoteConfig sharedInstance].refreshIntervals.msgFetchIntervalNormal];
            [channelsUpdater useInterval:[FCRemoteConfig sharedInstance].refreshIntervals.channelsFetchIntervalNormal];
            //[messageUpdater useInterval:MESSAGES_FETCH_INTERVAL_ON_SCREEN_LAUNCH];
            //[channelsUpdater useInterval:CHANNELS_FETCH_INTERVAL_ON_SCREEN_LAUNCH];            
            break;
        default:
            break;
    }
    
    messageUpdater.requestSource = requestSource;
    
    [channelsUpdater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
        if( [FCRemoteConfig sharedInstance].accountActive
           && [FCRemoteConfig sharedInstance].enabledFeatures.inboxEnabled
           && [FCUserUtil isUserRegistered] && !error) {
                [messageUpdater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
                    if(handler) handler(error);
                    HideNetworkActivityIndicator();
                    MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
                    [FreshchatUser sharedInstance].isRestoring = false;
                    [FCLocalNotification post:FRESHCHAT_USER_RESTORE_STATE info:@{@"state":@1}];
                }];
        } else {
            if (handler) handler(error);
            HideNetworkActivityIndicator();
            MESSAGES_DOWNLOAD_IN_PROGRESS = NO;
            [FreshchatUser sharedInstance].isRestoring = false;
            [FCLocalNotification post:FRESHCHAT_USER_RESTORE_STATE info:@{@"state":@1}];
        }
    }];
    
}


+(void)fetchMessagesForSrc:(enum MessageRequestSource) requestSource andCompletion:(void(^)(NSError *error))handler{
        FCSecureStore *store = [FCSecureStore sharedInstance];
        NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
        NSString *userAlias = [FCUtilities currentUserAlias];
        NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
        FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
        NSNumber *lastUpdateTime = [FCUtilities getLastUpdatedTimeForKey:FC_CONVERSATIONS_LAST_MODIFIED_AT_V2];
        NSString *path = [NSString stringWithFormat:HOTLINE_API_DOWNLOAD_ALL_MESSAGES_API, appID,userAlias];
        NSString *afterTime = [NSString stringWithFormat:@"messageAfter=%@",lastUpdateTime];
        NSString *source = [NSString stringWithFormat:@"src=%d",requestSource];

        [request setRelativePath:path andURLParams:@[appKey, afterTime, source]];
        
        [[FCAPIClient sharedInstance] request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
            dispatch_async(dispatch_get_main_queue(),^{
            if (!error) {
                NSDictionary *response = responseInfo.responseAsDictionary;
                NSArray *conversations = response[@"conversations"];
                
                if(!response || !conversations){
                    FCMemLogger *memLogger = [[FCMemLogger alloc]init];
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
                    FCChannels *channel = [FCChannels getWithID:channelId inContext:[FCDataManager sharedInstance].mainObjectContext];
                    NSArray *participants = conversationInfo[@"participants"];
                    if(participants > 0){
                        for(NSDictionary *participant in participants) {
                            [FCParticipants addParticipantWithInfo:participant inContext:[FCDataManager sharedInstance].mainObjectContext];
                        }
                    }
                    
                    if (!channel) {
                        channelPresent = NO;
                        break;
                    }
                }
                
                
                if(!channelPresent){
                    // Channel does not exist; reset channel interval key to force fetch channels
                    // skipping fetched msg import to DB in the current run.
                    FCChannelUpdater *channelUpdater = [FCChannelUpdater new];
                    [channelUpdater resetTime];
                    [channelUpdater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
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
                [FCMessageHelper performSelectorOnMainThread:@selector(conversationsDownloadFailed) withObject: nil waitUntilDone:NO];
                if(handler) handler(error);
            }            
        });
    }];
}

+(BOOL)processMessageResponse:(NSDictionary *)response{
    NSNumber *channelId;
    NSString *messageText;
    BOOL isRestore = [[FCUtilities getLastUpdatedTimeForKey:FC_CONVERSATIONS_LAST_REQUESTED_TIME] isEqualToNumber:@0];
    __block NSNumber *lastUpdateTime = [FCUtilities getLastUpdatedTimeForKey:FC_CONVERSATIONS_LAST_MODIFIED_AT_V2];
    NSArray *conversations = response[@"conversations"];
    for (int i=0; i<conversations.count; i++) {
        NSDictionary *conversationInfo = conversations[i];
        channelId = conversationInfo[@"channelId"];
        FCChannels *channel = [FCChannels getWithID:channelId inContext:[FCDataManager sharedInstance].mainObjectContext];
        NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
        FCConversations *conversation = [FCConversations RetriveConversationForConversationId:conversationID];
        
        if(!conversation) { //Create new conversation
            conversation = [FCConversations createConversationWithID:conversationID ForChannel:channel];
        }
        
        if(conversation) {
            [self processCSATForConversation:conversation withInfo:conversationInfo isRestore:isRestore];
        } else {
            return false;
        }
        
        NSArray *messages = conversationInfo[@"messages"];
        for (int j=0; j<messages.count; j++) {
            __block NSDictionary *messageInfo = messages[j];
            FCMessages *message = [FCMessages retriveMessageForMessageId:messageInfo[@"alias"]];
            lastUpdateTime = [FCDateUtil maxDateOfNumber:lastUpdateTime andStr:messageInfo[@"createdMillis"]];
            if (!message) {
                FCMessages *newMessage = [FCMessages createNewMessage:messageInfo toChannelID:channel.channelID];                
                if (channel) {
                    newMessage.belongsToChannel = channel;
                }
                
                newMessage.uploadStatus = @2;
                newMessage.belongsToConversation = conversation;
                newMessage.isRead = [messageInfo[@"readByUser"] boolValue];
                
                if (isRestore) {
                    if([messageInfo[@"marketingId"] integerValue] != 0 ) { //Set mark as read for marketing messages
                        newMessage.isRead = YES;
                    }
                }else {
                    messageText = [newMessage getDetailDescriptionForMessage];
                }
                
                if([newMessage.messageUserType integerValue] == 0) { //Set user messages from other devices/os
                     newMessage.isRead = YES;
                } else {
                    [FCLocalNotification post:FRESHCHAT_ACTION_USER_ACTIONS info:@{@"user_action" :@"NEW_MESSAGE"}];

                }                
            }
        }
        
        if(!isRestore && ![FCNotificationHandler areNotificationsEnabled] && messageText){
            handleUpdateNotification = [[FCNotificationHandler alloc] init];
            [handleUpdateNotification showActiveStateNotificationBanner:channel withMessage:messageText];
        }
    }
    
    [[FCDataManager sharedInstance]save];

    FCSecureStore *secureStore = [FCSecureStore sharedInstance];
    if([lastUpdateTime integerValue] != 0 ){
        [secureStore setObject:lastUpdateTime forKey:FC_CONVERSATIONS_LAST_MODIFIED_AT_V2];
    }else{
        NSNumber *lastUpdatedChannelTime = [secureStore objectForKey:FC_CHANNELS_LAST_MODIFIED_AT];
        [secureStore setObject:lastUpdatedChannelTime forKey:FC_CONVERSATIONS_LAST_MODIFIED_AT_V2];
    }
    if( conversations && conversations.count > 0 ){
        [FCLocalNotification post:HOTLINE_MESSAGES_DOWNLOADED];
    }
    [FCMessageHelper performSelectorOnMainThread:@selector(conversationsDownloaded) withObject:nil waitUntilDone:NO];
    [FCUtilities postUnreadCountNotification];
    return true;
}

+(void)processCSATForConversation:(FCConversations *)conversation withInfo:(NSDictionary *)conversationInfo isRestore:(BOOL) isRestore{
    if ([conversationInfo objectForKey:@"hasPendingCsat"]) {
        conversation.hasPendingCsat = @([conversationInfo[@"hasPendingCsat"] boolValue]);
        NSDictionary *csatInfo = conversationInfo[@"csat"];
        if (csatInfo) {
            if([FCCSATUtil isCSATExpiredForInitiatedTime:[csatInfo[@"initiated"] longValue]]){
                return;
            }
            if ([conversationInfo[@"hasPendingCsat"] boolValue]) {
                FDLog(@"*** CSAT for Conversation ID :%@ is pending ***", conversationInfo[@"conversationId"]);
            }

            NSString *conversationID = [conversationInfo[@"conversationId"] stringValue];
            NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
            FCCsat *csat = [FCCsat getWithID:conversationID inContext:context];
            
            
            if (!csat) {
                csat = [FCCsat createWithInfo:conversationInfo inContext:context];
                FDLog(@"Added a new CSAT entry\n %@", csatInfo);
                if(![FCNotificationHandler areNotificationsEnabled] && !isRestore) {
                    handleUpdateNotification = [[FCNotificationHandler alloc] init];
                    FCChannels *channel = [FCChannels getWithID:conversationInfo[@"channelId"] inContext:[FCDataManager sharedInstance].mainObjectContext];
                    NSString * cSatQues = (trimString([FCUtilities getLocalizedPositiveFeedCSATQues]).length > 0) ? [FCUtilities getLocalizedPositiveFeedCSATQues] : [conversationInfo valueForKeyPath:@"csat.question"];
                    [handleUpdateNotification showActiveStateNotificationBanner:channel withMessage:cSatQues];
                }
            }else{
                csat = [FCCsat updateCSAT:csat withInfo:conversationInfo];
            }
            
            csat.belongToConversation = conversation;
        }
    }
}


/* fetches channel list, updates existing channels including hidden channels */
+(NSURLSessionDataTask *)fetchAllChannels:(void (^)(NSArray<FCChannels *> *channels, NSError *error))handler{
    FCAPIClient *apiClient = [FCAPIClient sharedInstance];
    FCSecureStore *store = [FCSecureStore sharedInstance];
    //TODO: This is repeated multitimes. Needs refactor.
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_GET];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_CHANNELS_PATH,appID];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    NSNumber *lastUpdateTime = [FCUtilities getLastUpdatedTimeForKey:FC_CHANNELS_LAST_MODIFIED_AT];
    NSString *afterTime = [NSString stringWithFormat:PARAM_SINCE,lastUpdateTime];
    NSNumber *requestlocaleId = [FCLocaleUtil getConvLocaleId];
    NSMutableArray *reqParams = [[NSMutableArray alloc]initWithArray:@[token,afterTime]];
    [reqParams addObjectsFromArray:[FCLocaleUtil channelLocaleParams]];
    [request setRelativePath:path andURLParams:reqParams];
    NSURLSessionDataTask *task = [apiClient request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
        if (!error && statusCode == 200) {
            /* This check is added to delete all messages that are migrated from konotor SDK,
               but this is also performed for new installs as well (a harmless side-effect). */
            // TODO : Come up with a better logic to do this migration
            NSMutableDictionary *dictionary = [responseInfo responseAsDictionary][CONTENT_LOCALE];
            NSNumber *responseLocaleId = [dictionary objectForKey:@"localeId"];
            if( ![requestlocaleId isEqualToNumber:responseLocaleId] ) {
                [FCUserDefaults setNumber:responseLocaleId forKey:FC_CHANNELS_LAST_RECEIVED_LOCALE];
            }
            [FCLocaleUtil updateLocale];
            [self hideAllChannelsWithCompletion:^(NSError *error) {
                [self importChannels:[responseInfo responseAsDictionary] handler:handler];
            }];
        }else if(statusCode == 304){
            if (handler) handler(nil, error);
            FDLog(@"No change in channel  data")
            if (handler) handler(nil, error);
        }else{
            if (handler) handler(nil, error);
            NSNumber *messageLastUpdatedTime = [FCUtilities getLastUpdatedTimeForKey:FC_CONVERSATIONS_LAST_MODIFIED_AT_V2];
            if (error.code == -1009 && [messageLastUpdatedTime intValue] == 0) {
                [FCLocalNotification post:HOTLINE_CHANNELS_UPDATED];
            }
            FDLog(@"channel fetch failed :%@ \n response : %@",error, responseInfo.response);
        }
    }]; 
    return task;
}

+(void)hideAllChannelsWithCompletion:(void(^)(NSError *error))completion{
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSManagedObjectContext *ctx = [FCDataManager sharedInstance].mainObjectContext;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isHidden == NO"];
        NSArray *matches             = [ctx executeFetchRequest:fetchRequest error:nil];
        if(matches.count > 0){
            for (FCChannels *channel in matches) {
                [channel setValue:@(1) forKey:@"isHidden"];
                [ctx save:nil];
            }
        }
        if(completion){
            completion(nil);
        }
    }];
}

+(void)importChannels:(NSDictionary *)channelsInfo handler:(void (^)(NSArray *channels, NSError *error))handler;{
    NSArray *channels = channelsInfo[@"channels"];
    NSMutableArray *channelList = [NSMutableArray new];
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSNumber *lastUpdatedTime = [FCUtilities getLastUpdatedTimeForKey:FC_CHANNELS_LAST_MODIFIED_AT];
        NSInteger channelCount = [channels count];
        FCChannels *channel = nil;
        if (channelCount!=0) {
            for(int i=0; i< channels.count; i++){
                NSDictionary *channelInfo = channels[i];
                channel = [FCChannels getWithID:channelInfo[@"channelId"] inContext:context];
                [FCTags removeTagsForTaggableId:channelInfo[@"channelId"] andType:[NSNumber numberWithInt: HLTagTypeChannel] inContext:context];
                
                if (channel) {
                    [FCChannels updateChannel:channel withInfo:channelInfo];
                    FDLog(@"Channel updated ID:%@ name:%@", channel.channelID , channel.name);
                }else{
                    channel = [FCChannels createWithInfo:channelInfo inContext:context];
                    FDLog(@"Channel created ID:%@ name:%@", channel.channelID , channel.name);
                }
                
                if (channel) {
                    [channelList addObject:channel];
                }
                
                NSArray *tags = channelInfo[@"tags"];
                if(tags.count >0){
                        for(NSString *tagName in tags){
                            [FCTags createTagWithInfo:[FCTags createDictWithTagName:tagName type:[NSNumber numberWithInt: HLTagTypeChannel] andIdvalue:channelInfo[@"channelId"]] inContext:context];
                        }
                }
                
                if(channelInfo[@"updated"]){
                    lastUpdatedTime = [FCDateUtil maxDateOfNumber:lastUpdatedTime andStr:channelInfo[@"updated"]];
                }
            }
        }
        [[FCSecureStore sharedInstance] setObject: channelsInfo[LAST_MODIFIED_AT] forKey:FC_CHANNELS_LAST_MODIFIED_AT];
        [context save:nil];
        if (handler) handler(channelList,nil);
        if(channelCount > 0) {
            [FCLocalNotification post:HOTLINE_CHANNELS_UPDATED];
        }
    }];
}

+(void)uploadMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    
    //Added this to simulate sending unregistered user alias for message create call
//    [[FDSecureStore sharedInstance] setObject:@"asdf-adf-asdf-asdf" forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    
    if(![pMessage isMarkedForUpload]){
        pMessage.isMarkedForUpload = YES;
        [[FCDataManager sharedInstance]save];
    }
    
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];

    __block NSString *messageAlias = pMessage.messageAlias;
    
    if([[pMessage uploadStatus]intValue] == MESSAGE_UPLOADED || [[pMessage uploadStatus]intValue] == MESSAGE_UPLOADING){
        return;
    } else{
        pMessage.uploadStatus = @(MESSAGE_UPLOADING);
        [[FCDataManager sharedInstance]save];
    }
        
    FCServiceRequest *request = [[FCServiceRequest alloc]initMultipartFormRequestWithBody:^(id<HLMultipartFormData> formData) {
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
        
        /*//Audio message
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
         */
        //fragments here
        
    }];
    
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPLOAD_MESSAGE, appID,userAlias];
    
    [request setRelativePath:path andURLParams:@[token]];
    
    ShowNetworkActivityIndicator();
    UIBackgroundTaskIdentifier taskID = [[FCBackgroundTaskManager sharedInstance]beginTask];

    [[FCAPIClient sharedInstance]request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        
        NSDictionary* messageInfo = responseInfo.responseAsDictionary;
        
        [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if (!error && statusCode == 201) {
                
                ALog(@"Message sent");
                
                NSString *conversationID = [messageInfo[@"hostConversationId"] stringValue];
                if (!conversation || ![conversationID isEqualToString:conversation.conversationAlias]) {
                    FCConversations *newConversation = [FCConversations createConversationWithID:conversationID ForChannel:channel];
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
                [[FCDataManager sharedInstance]save];
                [FCMessageHelper performSelector:@selector(UploadFinishedNotification:) withObject:messageAlias];
            }else{
                if ( error && error.code == -1009 ) {
                    [FCMessageHelper UploadFailedNotification:messageAlias];
                }
                else if( [self isUserNotCreated:responseInfo] ) {
                    [self retryUserRegistration];
                }
                else {
                    [FCMessageHelper NotifyServerError];
                }
                [self markUploadFailedAndSaveMessage:pMessage inChannel:channel];
            }
            
            [[FCBackgroundTaskManager sharedInstance]endTask:taskID];
            HideNetworkActivityIndicator();

        }];
    }];
}


+(void)uploadNewMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel withCompletion:(void(^)(NSError *error))completion {
    if(![pMessage isMarkedForUpload]){
        pMessage.isMarkedForUpload = YES;
        [[FCDataManager sharedInstance]save];
    }
    
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    
    __block NSString *messageAlias = pMessage.messageAlias;
    
    if([[pMessage uploadStatus]intValue] == MESSAGE_UPLOADED || [[pMessage uploadStatus]intValue] == MESSAGE_UPLOADING){
        if(completion) {
            completion(nil);
        }
        return;
    } else{
        pMessage.uploadStatus = @(MESSAGE_UPLOADING);
        [[FCDataManager sharedInstance]save];
    }
    
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPLOAD_MESSAGE, appID,userAlias];
    NSMutableDictionary *data1 = [pMessage convertMessageToDictionary];
    data1[@"conversationId"] = conversation.conversationAlias;
    data1[@"channelId"] = channel.channelID;
    data1[@"source"] = @2;
    
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
    NSData *userData = [NSJSONSerialization dataWithJSONObject:data1 options:NSJSONWritingPrettyPrinted error:nil];
    [request setBody:userData];
    
    [request setRelativePath:path andURLParams:@[token]];
    
    ShowNetworkActivityIndicator();
    
    UIBackgroundTaskIdentifier taskID = [[FCBackgroundTaskManager sharedInstance]beginTask];
    [[FCAPIClient sharedInstance]request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        
        NSDictionary* messageInfo = responseInfo.responseAsDictionary;
        [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if (!error && statusCode == 201) {
                
                ALog(@"Message sent");
                //If the channel becomes fault since the user called identify user function meanwhile while sending message.
                if(channel.isFault) {
                    return ;
                }

                NSString *conversationID = [messageInfo[@"conversationId"] stringValue];
                if (!conversation || ![conversationID isEqualToString:conversation.conversationAlias]) {

                    FCConversations *existingConversation = [FCConversations RetriveConversationForConversationId:conversationID];
                    if (existingConversation == nil) {
                        existingConversation = [FCConversations createConversationWithID:conversationID ForChannel:channel];
                    }
                    if(existingConversation != nil) {
                        pMessage.belongsToConversation = existingConversation;
                    }
                }else{
                    pMessage.belongsToConversation = conversation;
                }
                
                pMessage.uploadStatus = @(MESSAGE_UPLOADED);
                pMessage.messageAlias = messageInfo[@"alias"];
                pMessage.createdMillis = messageInfo[@"createdMillis"];
                pMessage.isMarkedForUpload = NO;
                [[FCDataManager sharedInstance]save];
                [FCMessageHelper performSelector:@selector(UploadFinishedNotification:) withObject:messageAlias];
            }else{
                if ( error && error.code == -1009 ) {
                    [FCMessageHelper UploadFailedNotification:messageAlias];
                }
                else if( [self isUserNotCreated:responseInfo] ) {
                    [self retryUserRegistration];
                }
                else {
                    [FCMessageHelper NotifyServerError];
                }
                [self markUploadFailedAndSaveMessage:pMessage inChannel:channel];
            }
            [[FCBackgroundTaskManager sharedInstance]endTask:taskID];
            HideNetworkActivityIndicator();
            if(completion) {
                completion(error);
            }
        }];
    }];
}

+(void) markUploadFailedAndSaveMessage:(FCMessages *) message inChannel: (FCChannels*) channel {
    message.uploadStatus = @(MESSAGE_NOT_UPLOADED);
    if (channel != nil) {
        [channel addMessagesObject:message];
    }
    [[FCDataManager sharedInstance]save];
}

+(void)uploadAllUnuploadedMessages:(NSArray *)messages index:(NSInteger)currentIndex {
    if ( currentIndex < messages.count ) {
        FCMessages *message = messages[currentIndex];
        if(message != nil) {
            FCConversations *conversation = message.belongsToConversation;
            [FCMessageServices uploadPictureMessage:message toConversation:conversation withCompletion:^{
                [FCMessageServices uploadNewMessage:message toConversation:conversation onChannel:message.belongsToChannel withCompletion:^(NSError *error) {
                    if (error == nil) {
                        [self uploadAllUnuploadedMessages:messages index:currentIndex+1];
                    } else {
                        FDLog(@"Sequence message not sent properly. Pending messages: %u",(int)(messages.count-currentIndex));
                    }
                }];
            }];
        }
    }
}

+(void)uploadNewMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel{
    [self uploadNewMessage:pMessage toConversation:conversation onChannel:channel withCompletion:nil];
}


+(void)uploadPictureMessage:(FCMessages *)pMessage toConversation:(FCConversations *)conversation withCompletion:(void (^)())completion {
    
    FCMessageFragments *fragment = [FCMessageFragments getImageFragment:pMessage];
    if(!fragment) { //If the fragment doesn't have picture message
        if(completion) {
            completion();
        }
        return;
    }
    
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    NSString *token = [NSString stringWithFormat:HOTLINE_REQUEST_PARAMS,appKey];
    
    FCServiceRequest *request = [[FCServiceRequest alloc]initMultipartFormRequestWithBody:^(id<HLMultipartFormData> formData) {
        [formData addFilePart:fragment.binaryData1 name:@"pic" fileName:@".jpg" mimeType:@"image/jpeg"];
        [formData addTextPart:[NSString stringWithFormat:@"pic_%@.jpg",fragment.index] name:@"name"];
    }];
    
    NSString *path = [NSString stringWithFormat:HOTLINE_API_UPLOAD_IMAGE, appID,userAlias];
    
    [request setRelativePath:path andURLParams:@[token]];
    
    ShowNetworkActivityIndicator();
    UIBackgroundTaskIdentifier taskID = [[FCBackgroundTaskManager sharedInstance]beginTask];
    
    [[FCAPIClient sharedInstance]request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        NSDictionary* messageInfo = responseInfo.responseAsDictionary;
        [[FCDataManager sharedInstance].mainObjectContext performBlock:^{
            NSInteger statusCode = ((NSHTTPURLResponse *)responseInfo.response).statusCode;
            if (!error && statusCode == 201) {
                ALog(@"Fragment Data uploaded and sent");
                [fragment updateWithInfo:messageInfo[@"image"]];
                [[FCDataManager sharedInstance]save];
                if(completion) {
                    completion();
                }
            }
            else{
                FDLog(@"Message upload failed!");
                [self markUploadFailedAndSaveMessage:pMessage inChannel:nil];
            }
            [[FCBackgroundTaskManager sharedInstance]endTask:taskID];
            HideNetworkActivityIndicator();
            
        }];
    }];
}


+(BOOL) isUserNotCreated : (FCResponseInfo *)responseInfo {
    return (responseInfo && [responseInfo isDict]
            && [[responseInfo responseAsDictionary][@"errorCode"] integerValue] == ERROR_CODE_USER_NOT_CREATED);
}

+(void)retryUserRegistration {
    [[FCSecureStore sharedInstance] setObject:nil forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    [[FCSecureStore sharedInstance] setBoolValue:NO forKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
    [FCUserUtil registerUser:nil];
}

//TODO: Skip messages that are clicked before
+(void)markMarketingMessageAsClicked:(NSNumber *)marketingId{
    if((marketingId == nil) || ([marketingId intValue] ==0)) return;

    FCSecureStore *store = [FCSecureStore sharedInstance];
    
    NSString *userAlias = [FCUtilities currentUserAlias];
    
    if (!userAlias) return;

    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    
    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_MARKETING_MESSAGE_STATUS_UPDATE_PATH, appID,userAlias,marketingId.stringValue];
    [request setRelativePath:path andURLParams:@[@"clicked=1",appKey]];
    [[FCAPIClient sharedInstance] request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
        if (!error) {
            FDLog(@"*** Marked as Clicked *** Marketing campaign message with ID  %@", marketingId);
        }else{
            FDLog(@"Failed to register marketing message click event to server : %@", error);
        }
    }];
}

+(void)markMarketingMessageAsRead:(FCMessages *)message context:(NSManagedObjectContext *)context{
    if (message.isRead == YES) return;
    
    NSNumber *marketingId = message.marketingId;
    
    if((marketingId == nil) || ([marketingId intValue] ==0)) return;
    
    message.isRead = YES;
    
    FCSecureStore *store = [FCSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FCUtilities currentUserAlias];
    NSString *appKey = [NSString stringWithFormat:@"t=%@",[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];

    if (!userAlias) return;

    FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_PUT];
    NSString *path = [NSString stringWithFormat:HOTLINE_API_MARKETING_MESSAGE_STATUS_UPDATE_PATH, appID,userAlias,marketingId.stringValue];
    [request setRelativePath:path andURLParams:@[@"seen=1",appKey]];
    [[FCAPIClient sharedInstance] request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
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
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        
        NSError *error;
        FCCsat *csat = nil;

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
        
        FCServiceRequest *request = [[FCServiceRequest alloc]initWithMethod:HTTP_METHOD_POST];
        NSString *appID = [[FCSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_APP_ID];
        NSString *userAlias = [FCUtilities currentUserAlias];
        NSString *appKey = [NSString stringWithFormat:@"t=%@",[[FCSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
        NSString *path = [NSString stringWithFormat:HOTLINE_API_CSAT_PATH, appID, userAlias, conversationID, csatID];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"csatResponse": response} options:NSJSONWritingPrettyPrinted error:nil];
        [request setRelativePath:path andURLParams:@[appKey]];
        
        [[FCAPIClient sharedInstance] request:request withHandler:^(FCResponseInfo *responseInfo, NSError *error) {
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
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CSAT_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"csatStatus == %d", CSAT_RATED];
        NSArray *results = [context executeFetchRequest:fetchRequest error:nil];
        FDLog(@"There are %d unuploaded CSATs", (int)results.count);
        for (FCCsat *csat in results) {
            [FCMessageServices postCSATWithID:csat.objectID completion:nil];
        }

    }];
}

@end
