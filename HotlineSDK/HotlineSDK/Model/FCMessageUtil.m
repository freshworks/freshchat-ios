//
//  KonotorMessage.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "FCMessageUtil.h"
#import "FCConversations.h"
#import "FCMessageHelper.h"
#import "FCMessageBinaries.h"
#import "FCDataManager.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"
#import "FCMessageServices.h"
#import "FCLocalNotification.h"
#import "FCCoreServices.h"

#define KONOTOR_IMG_COMPRESSION YES

@class KonotorConversationData;
@class KonotorMessageData;

@implementation FCMessageUtil

@dynamic articleID;
@dynamic actionLabel;
@dynamic actionURL;
@dynamic audioURL;
@dynamic bytes;
@dynamic createdMillis;
@dynamic durationInSecs;
@dynamic isDownloading;
@dynamic isWelcomeMessage;
@dynamic isMarkedForUpload;
@dynamic marketingId;
@dynamic messageAlias;
@dynamic messageRead;
@dynamic messageType;
@dynamic messageUserId;
@dynamic picCaption;
@dynamic picHeight;
@dynamic picThumbHeight;
@dynamic picThumbUrl;
@dynamic picThumbWidth;
@dynamic picUrl;
@dynamic picWidth;
@dynamic read;
@dynamic text;
@dynamic uploadStatus;
@dynamic belongsToChannel;
@dynamic belongsToConversation;
@dynamic hasMessageBinary;

NSMutableDictionary *gkMessageIdMessageMap_old;

static BOOL messageExistsDirty = YES;
static BOOL messageTimeDirty = YES;

+(NSString *)generateMessageID{
    NSTimeInterval  today = [[NSDate date] timeIntervalSince1970];
    NSString *userAlias = [FCUtilities getUserAliasWithCreate];
    NSString *intervalString = [NSString stringWithFormat:@"%.0f", today*1000];
    NSString *messageID  =[NSString stringWithFormat:@"%@%@%@",userAlias,@"_",intervalString];
    return messageID;
}

+(FCMessageUtil *)saveTextMessageInCoreData:(NSString *)text onConversation:(FCConversations *)conversation{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil *message = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    [message setMessageUserId:[USER_TYPE_MOBILE stringValue]];
    [message setMessageType:@1];
    [message setMessageRead:YES];
    [message setText:text];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    message.belongsToConversation = conversation;
    message.isWelcomeMessage = NO;
    [datamanager save];
    [FCMessageUtil markDirty];
    return message;
}

+(void) markDirty{
    messageExistsDirty = YES;
    messageTimeDirty = YES;
}

+(FCMessageUtil* )savePictureMessageInCoreData:(UIImage *)image withCaption:(NSString *)caption onConversation:(nonnull FCConversations *)conversation{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil *message = (FCMessageUtil *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    
    [message setMessageUserId:[USER_TYPE_MOBILE stringValue]];
    [message setMessageAlias:[FCMessageUtil generateMessageID]];
    [message setMessageType:@3];
    [message setMessageRead:YES];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    [message setPicCaption:caption];
    FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
    NSData *imageData, *thumbnailData;
  
    if(image){
        imageData = UIImageJPEGRepresentation(image, 0.5);
        CGImageSourceRef src = CGImageSourceCreateWithData( (__bridge CFDataRef)(imageData), NULL);
        NSDictionary *osptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways, [NSNumber numberWithDouble:300], kCGImageSourceThumbnailMaxPixelSize, nil];
#if KONOTOR_IMG_COMPRESSION
        NSDictionary *compressionOptions = [[NSDictionary alloc] initWithObjectsAndKeys:(id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform, kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways, [NSNumber numberWithDouble:1000], kCGImageSourceThumbnailMaxPixelSize, nil];
#endif
        
        CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)osptions); // Create scaled image
        
#if KONOTOR_IMG_COMPRESSION
        CGImageRef compressedImage = CGImageSourceCreateThumbnailAtIndex(src, 0, (__bridge CFDictionaryRef)compressionOptions);
#endif
        
        UIImage *imgthumb = [[UIImage alloc] initWithCGImage:thumbnail];
        int h = imgthumb.size.height;
        int w = imgthumb.size.width;
        
#if KONOTOR_IMG_COMPRESSION
        UIImage *imgCompressed = [[UIImage alloc] initWithCGImage:compressedImage];
#endif

        thumbnailData = UIImageJPEGRepresentation(imgthumb,0.5);
        
#if KONOTOR_IMG_COMPRESSION
        imageData=UIImageJPEGRepresentation(imgCompressed, 0.5);
        [message setPicHeight:[NSNumber numberWithInt:imgCompressed.size.height]];
        [message setPicWidth:[NSNumber numberWithInt:imgCompressed.size.width]];
#else
        [message setPicHeight:[NSNumber numberWithInt:image.size.height]];
        [message setPicWidth:[NSNumber numberWithInt:image.size.width]];
        
#endif
        [message setPicThumbHeight:[NSNumber numberWithInt:h]];
        [message setPicThumbWidth:[NSNumber numberWithInt:w]];
        
        CFRelease(src);
        CFRelease(thumbnail);
    }
    
    [messageBinary setBinaryImage:imageData];
    [messageBinary setBinaryThumbnail:thumbnailData];
    [messageBinary setValue:message forKey:@"belongsToMessage"];
    [message setValue:messageBinary forKey:@"hasMessageBinary"];
    message.belongsToConversation = conversation;
    message.isWelcomeMessage = NO;
    [datamanager save];
    [FCMessageUtil markDirty];
    return message;
}

+(NSInteger)getUnreadMessagesCountForChannel:(NSNumber *)channelID{
    FCChannels *channel = [FCChannels getWithID:channelID inContext:[FCDataManager sharedInstance].mainObjectContext];
    return [channel unreadCount];
}

+(void)markAllMessagesAsReadForChannel:(FCChannels *)channel{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"messageRead == NO AND belongsToChannel == %@",channel];
        request.predicate = predicate;
        NSArray *messages = [context executeFetchRequest:request error:&pError];
        if (messages.count>0) {
            for(int i=0;i<messages.count;i++){
                FCMessageUtil *message = messages[i];
                if(message){
                    if(![[message marketingId] isEqualToNumber:@0]){
                        [FCMessageServices markMarketingMessageAsRead:message context:context];
                    }else{
                        [message markAsRead];
                    }
                }
            }
            [FCCoreServices sendLatestUserActivity:channel];
        }
        [context save:nil];
    }];
}

+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil* messageObject = [FCMessageUtil retriveMessageForMessageId:messageId];
    if(!messageObject) return NO;
    
    FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    if(!pMessageBinary){
        FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
        [pMessageBinary setBinaryImage:imageData];
        [messageBinary setValue:messageObject forKey:@"belongsToMessage"];
        [messageObject setValue:messageBinary forKey:@"hasMessageBinary"];
        [datamanager save];
        return YES;
    }else{
        [pMessageBinary setBinaryImage:imageData];
        [datamanager save];
        return YES;
    }
    return NO;
}


+(BOOL) setBinaryImageThumbnail:(NSData *)imageData forMessageId:(NSString *)messageId{
    FCDataManager *datamanager = [FCDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    FCMessageUtil* messageObject = [FCMessageUtil retriveMessageForMessageId:messageId];
    if(!messageObject){
        return NO;
    }
    FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    if(!pMessageBinary){
        FCMessageBinaries *messageBinary = (FCMessageBinaries *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGE_BINARIES_ENTITY inManagedObjectContext:context];
        [pMessageBinary setBinaryThumbnail:imageData];
        [messageBinary setValue:messageObject forKey:@"belongsToMessage"];
        [messageObject setValue:messageBinary forKey:@"hasMessageBinary"];
        [datamanager save];
        return YES;
    }else{
        [pMessageBinary setBinaryThumbnail:imageData];
        [datamanager save];
        return YES;
    }
    return NO;
}

+(void)uploadAllUnuploadedMessages{
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isMarkedForUpload == YES AND uploadStatus == 0"];
        [request setPredicate:predicate];
        NSArray *array = [context executeFetchRequest:request error:&pError];
        if([array count]==0){
            return;
        }else{
            FDLog(@"There are %d unuploaded messages", (int)array.count);
            for(int i=0;i<[array count];i++){
                FCMessageUtil *message = array[i];
                FCConversations *convo = message.belongsToConversation;
                [FCMessageServices uploadMessage:message toConversation:convo onChannel:message.belongsToChannel];
            }
        }
    }];
}

+(FCMessageUtil *)retriveMessageForMessageId: (NSString *)messageId{
    if(gkMessageIdMessageMap_old){
        FCMessageUtil *message = [gkMessageIdMessageMap_old objectForKey:messageId];
        if(message) return message;
    }
    
    if(!gkMessageIdMessageMap_old){
        gkMessageIdMessageMap_old = [[ NSMutableDictionary alloc]init];
    }
    
    NSError *pError;
    NSManagedObjectContext *context = [[FCDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
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
        FCMessageUtil *message = [array objectAtIndex:0];
        if(message){
            [gkMessageIdMessageMap_old setObject:message forKey:messageId];
            return message;
        }
    }
    return nil;
}

-(void)associateMessageToConversation: (FCConversations *)conversation{
    if(conversation){
        NSMutableSet *mutableSetOfExistingConversationsOnDisk = [conversation  mutableSetValueForKey:@"hasMessages"];
        [mutableSetOfExistingConversationsOnDisk addObject:self];
        self.belongsToConversation = conversation;
        [[FCDataManager sharedInstance]save];
    }
}

-(NSString *)getJSON{
    NSMutableDictionary *messageDict = [[NSMutableDictionary alloc]init];
    [messageDict setObject:[self messageType] forKey:@"messageType"];
    if([[self messageType] intValue ]== 1)
        [messageDict setObject:[self text] forKey:@"text"];
    else if([[self messageType] intValue ]== 2)
        [messageDict setObject:[self durationInSecs] forKey:@"durationInSecs"];
    else if([[self messageType] intValue ]== 3)
    {
        [messageDict setObject:[self picThumbWidth] forKey:@"picThumbWidth"];
        [messageDict setObject:[self picThumbHeight] forKey:@"picThumbHeight"];
        [messageDict setObject:[self picHeight] forKey:@"picHeight"];
        [messageDict setObject:[self picWidth] forKey:@"picWidth"];
        
        if([self picCaption])
            [messageDict setObject:[self picCaption] forKey:@"picCaption"];
}
    NSError *error;
    NSData *pJsonString = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:&error];
    return [[NSString alloc ]initWithData:pJsonString encoding:NSUTF8StringEncoding];
}

-(void)markAsRead{
    [self setMessageRead:YES];
}

-(void)markAsUnread{
    BOOL wasRead = [self messageRead];
    if(!wasRead) return
    [self setMessageRead:NO];
}

+(FCMessageUtil *)createNewMessage:(NSDictionary *)message{
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    FCMessageUtil *newMessage = (FCMessageUtil *)[NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_MESSAGES_ENTITY inManagedObjectContext:context];
    newMessage.isWelcomeMessage = NO;
    newMessage.messageAlias = [message valueForKey:@"alias"];
    newMessage.messageType = [message valueForKey:@"messageType"];
    newMessage.messageUserId = [message[@"messageUserType"]stringValue];
    newMessage.bytes = [message valueForKey:@"bytes"];
    newMessage.durationInSecs = [message valueForKey:@"durationInSecs"];
    newMessage.read = [message valueForKey:@"read"];
    [newMessage setAudioURL:[message valueForKey:@"binaryUrl"]];
    newMessage.text = (message[@"text"]) ? message[@"text"] : @"";
    [newMessage setCreatedMillis:[message valueForKey:@"createdMillis"]];
    [newMessage setMarketingId:[message valueForKey:@"marketingId"]];
    [newMessage setActionLabel:[message valueForKey:@"messageActionLabel"]];
    [newMessage setActionURL:[message valueForKey:@"messageActionUrl"]];
    
    if (message[@"articleId"]) {
        newMessage.articleID = message[@"articleId"];
    }
    
    if(([newMessage.messageType isEqualToNumber:[NSNumber numberWithInt:KonotorMessageTypePicture]])||([newMessage.messageType isEqualToNumber:[NSNumber numberWithInt:KonotorMessageTypePictureV2]])){
        [newMessage setPicHeight:[message valueForKey:@"picHeight"]];
        [newMessage setPicWidth:[message valueForKey:@"picWidth"]];
        [newMessage setPicThumbHeight:[message valueForKey:@"picThumbHeight"]];
        [newMessage setPicThumbWidth:[message valueForKey:@"picThumbWidth"]];
        [newMessage setPicUrl:[message valueForKey:@"picUrl"]];
        [newMessage setPicThumbUrl:[message valueForKey:@"picThumbUrl"]];
        [newMessage setPicCaption:[message valueForKey:@"picCaption"]];
    }
    [[FCDataManager sharedInstance]save];
    [FCMessageUtil markDirty];
    return newMessage;
}

-(KonotorMessageData *) ReturnMessageDataFromManagedObject{
    KonotorMessageData *message = [[KonotorMessageData alloc]init];
    message.articleID = self.articleID;
    message.messageType = [self messageType];
    message.messageUserId = [self messageUserId];
    message.messageId =[self messageAlias];
    message.durationInSecs = [self durationInSecs];
    message.read = [self read];
    message.uploadStatus = [self uploadStatus];
    message.createdMillis = [self createdMillis];
    message.text = [self text];
    message.messageRead = [self messageRead];
    message.actionURL = [self actionURL];
    message.actionLabel = [self actionLabel];
    message.isMarketingMessage = [self isMarketingMessage];
    message.marketingId = self.marketingId;
    message.isWelcomeMessage = self.isWelcomeMessage;
    
    if([message.messageType isEqualToNumber:[NSNumber numberWithInt:2]]){
        FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[self valueForKeyPath:@"hasMessageBinary"];
        message.audioData = [pMessageBinary binaryAudio];
    }
    
    if(([message.messageType isEqualToNumber:[NSNumber numberWithInt:KonotorMessageTypePicture]])||([message.messageType isEqualToNumber:[NSNumber numberWithInt:KonotorMessageTypePictureV2]])){
        message.picHeight = [self picHeight];
        message.picWidth = [self picWidth];
        message.picThumbHeight = [self picThumbHeight];
        message.picThumbWidth = [self picThumbWidth];
        
        if([self picUrl])  message.picUrl = [self picUrl];
        
        if([self picThumbUrl]) message.picThumbUrl = [self picThumbUrl];
        
        if([self picCaption])message.picCaption = [self picCaption];
        
        FCMessageBinaries *pMessageBinary = (FCMessageBinaries*)[self valueForKeyPath:@"hasMessageBinary"];
        if(pMessageBinary){
            message.picData = [pMessageBinary binaryImage];
            message.picThumbData = [pMessageBinary binaryThumbnail];
        }

    }
    return message;
}


- (BOOL) isMarketingMessage{
    if(([[self marketingId] intValue]<=0)||(![self marketingId]))
        return NO;
    else
        return YES;
}

+(NSArray *)getAllMesssageForChannel:(FCChannels *)channel{
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    NSArray *matches = channel.messages.allObjects;
    for (int i=0; i<matches.count; i++) {
        KonotorMessageData *message = [matches[i] ReturnMessageDataFromManagedObject];
        if (message) {
            [messages addObject:message];
        }        
    }
    return messages;
}

+(FCMessageUtil *)getWelcomeMessageForChannel:(FCChannels *)channel{
    FCMessageUtil *message = nil;
    NSManagedObjectContext *context = [FCDataManager sharedInstance].mainObjectContext;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
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

+(bool) hasUserMessageInContext:(NSManagedObjectContext *)context {
    static BOOL messageExists = NO;
    if(messageExistsDirty){
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
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
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
        fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isWelcomeMessage <> 1"];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(!error){
            for(FCMessageUtil *message in matches){
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
    long long lastMessageTime = [FCMessageUtil lastMessageTimeInContext:context];
    return ([[NSDate date] timeIntervalSince1970] - (lastMessageTime/1000))/86400;
}

@end


@implementation KonotorMessageData

@end
