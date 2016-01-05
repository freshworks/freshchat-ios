//
//  KonotorMessage.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorMessage.h"
#import "KonotorConversation.h"
#import "Konotor.h"
#import "WebServices.h"
#import "KonotorUtil.h"
#import "KonotorMessageBinary.h"
#import "KonotorDataManager.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"

#define KONOTOR_IMG_COMPRESSION YES

@class KonotorConversationData;
@class KonotorMessageData;

@implementation KonotorMessage

@dynamic articleID;
@dynamic actionLabel;
@dynamic actionURL;
@dynamic audioURL;
@dynamic bytes;
@dynamic createdMillis;
@dynamic durationInSecs;
@dynamic isDownloading;
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

NSMutableDictionary *gkMessageIdMessageMap;

+(NSString *)generateMessageID{
    NSTimeInterval  today = [[NSDate date] timeIntervalSince1970];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *intervalString = [NSString stringWithFormat:@"%.0f", today*1000];
    NSString *messageID  =[NSString stringWithFormat:@"%@%@%@",userAlias,@"_",intervalString];
    return messageID;
}

+(KonotorMessage *)saveTextMessageInCoreData:(NSString *)text onConversation:(KonotorConversation *)conversation{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];

    //TODO: why do we need to associate user alias to message (local cache) ?
    [message setMessageUserId:@"Sender-User"];

    //TODO: Use defined message type instead of hardcoding
    [message setMessageType:@1];
    [message setMessageRead:YES];
    [message setText:text];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];

    //TODO: Test if all the messages are deleted when channel is deleted
    message.belongsToConversation = conversation;
    [datamanager save];
    return message;
}

+(KonotorMessage* )savePictureMessageInCoreData:(UIImage *)image withCaption:(NSString *)caption onConversation:(nonnull KonotorConversation *)conversation{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage *message = (KonotorMessage *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];
    
    [message setMessageUserId:@"Sender-User"];
    [message setMessageAlias:[KonotorMessage generateMessageID]];
    [message setMessageType:@3];
    [message setMessageRead:YES];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    [message setPicCaption:caption];
    KonotorMessageBinary *messageBinary = (KonotorMessageBinary *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessageBinary" inManagedObjectContext:context];
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
    }
    [messageBinary setBinaryImage:imageData];
    [messageBinary setBinaryThumbnail:thumbnailData];
    [messageBinary setValue:message forKey:@"belongsToMessage"];
    [message setValue:messageBinary forKey:@"hasMessageBinary"];
    message.belongsToConversation = conversation;
    [datamanager save];
    return message;
}

+(void)markAllMessagesAsRead{
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorMessage" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"messageRead == NO"];
        request.predicate = predicate;
        NSArray *array = [context executeFetchRequest:request error:&pError];
        if([array count]==0){
            [KonotorMessage PostUnreadCountNotifWithNumber:@0];
            return;
        }else{
            for(int i=0;i<[array count];i++){
                KonotorMessage *message = [array objectAtIndex:i];
                if(message){
                    if(![[message marketingId] isEqualToNumber:@0]){
                        [message MarkMarketingMessageAsRead];
                    }else{
                        [message markAsReadwithNotif:NO];
                    }
                }
            }
            [KonotorMessage PostUnreadCountNotifWithNumber:@0];
        }
    }];
}


//TODO: Move this to HLCoreServices
+(void) markMarketingMessageAsClicked:(NSNumber *) marketingId{
    
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    
    if([marketingId intValue] ==0 || !marketingId) return;
    
    //PUT {appId}/user/{alias}/message/marketing/{marketingId}/status?delivered=1&clicked=1&seen=1&t={appkey}
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",appID,@"/user/",userAlias,@"/message/marketing/",[marketingId stringValue ],@"/status?clicked=1&t=",appKey];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:nil];
    [operation start];
}

+(BOOL) setBinaryImage:(NSData *)imageData forMessageId:(NSString *)messageId{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage* messageObject = [KonotorMessage retriveMessageForMessageId:messageId];
    if(!messageObject) return NO;
    
    KonotorMessageBinary *pMessageBinary = (KonotorMessageBinary*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    if(!pMessageBinary){
        KonotorMessageBinary *messageBinary = (KonotorMessageBinary *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessageBinary" inManagedObjectContext:context];
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
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage* messageObject = [KonotorMessage retriveMessageForMessageId:messageId];
    if(!messageObject){
        return NO;
    }
    KonotorMessageBinary *pMessageBinary = (KonotorMessageBinary*)[messageObject valueForKeyPath:@"hasMessageBinary"];
    if(!pMessageBinary){
        KonotorMessageBinary *messageBinary = (KonotorMessageBinary *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessageBinary" inManagedObjectContext:context];
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


//TODO: Move this to HLCoreServices

-(void) MarkMarketingMessageAsRead{
    
    if([self messageRead])return;
    
    NSNumber *marketingId = [self marketingId];
    
    if([marketingId intValue] ==0 || !marketingId) return;
    
    //mark as read, if the call fails we can mark it as unread.
    [self MarkAsRead];

    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *userAlias = [FDUtilities getUserAlias];
    NSString *appKey = [store objectForKey:HOTLINE_DEFAULTS_APP_KEY];
    
    //PUT {appId}/user/{alias}/message/marketing/{marketingId}/status?delivered=1&clicked=1&seen=1&t={appkey}
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",appID,@"/user/",userAlias,@"/message/marketing/",[marketingId stringValue ],@"/status?seen=1&t=",appKey];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"PUT" path:postPath parameters:nil];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:nil failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
         [self markAsUnread];
     }];
    [operation start];
}

+(void) PostUnreadCountNotifWithNumber:(NSNumber *)number{
    [KonotorUtil PostNotificationWithName:@"KonotorUnreadMessagesCount" withObject:number];
}

+(void)uploadAllUnuploadedMessages{
    FDLog(@"Uploading all unuploaded messages");
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    [context performBlock:^{
        NSError *pError;
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorMessage" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isMarkedForUpload == YES AND uploadStatus == 0"];
        [request setPredicate:predicate];
        NSArray *array = [context executeFetchRequest:request error:&pError];
        if([array count]==0){
            return;
        }else{
            FDLog(@"There are %d unuploaded messages", (int)array.count);
            FDLog(@"Message retry initiated");
            for(int i=0;i<[array count];i++){
                KonotorMessage *message = array[i];
                KonotorConversation *convo = message.belongsToConversation;
                [KonotorWebServices uploadMessage:message toConversation:convo onChannel:message.belongsToChannel];
            }
        }
    }];
}

+(KonotorMessage *)retriveMessageForMessageId: (NSString *)messageId{
    if(gkMessageIdMessageMap){
        KonotorMessage *message = [gkMessageIdMessageMap objectForKey:messageId];
        if(message) return message;
    }
    
    if(!gkMessageIdMessageMap){
        gkMessageIdMessageMap = [[ NSMutableDictionary alloc]init];
    }
    
    NSError *pError;
    NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"KonotorMessage" inManagedObjectContext:context];
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
        KonotorMessage *message = [array objectAtIndex:0];
        if(message){
            [gkMessageIdMessageMap setObject:message forKey:messageId];
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

-(KonotorConversation *) parentConversation{
    return self.belongsToConversation;
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

-(void) markAsReadwithNotif:(BOOL) notif{
    BOOL wasRead = [self messageRead];
 
    if(![[self marketingId] isEqualToNumber:@0]){
        [self MarkMarketingMessageAsRead];
    }else{
        [self setMessageRead:YES];
    }
    KonotorConversation *parentConvo = [self parentConversation];
    if(parentConvo){
        if(!wasRead)
            [parentConvo decrementUnreadCount];
        
        if(notif)
            [KonotorMessage PostUnreadCountNotifWithNumber:[parentConvo unreadMessagesCount]];
    }
}

//introducing this function to solve for the recursive calling of markmarketingasread
-(void) MarkAsRead{
    BOOL wasRead = [self messageRead];

    [self setMessageRead:YES];
    KonotorConversation *parentConvo = [self parentConversation];
    if(parentConvo){
        if(!wasRead)
            [parentConvo decrementUnreadCount];
    }
}

-(void)markAsUnread{
    BOOL wasRead = [self messageRead];
    if(!wasRead) return
    [self setMessageRead:NO];
    KonotorConversation *parentConvo = [self parentConversation];
    if(parentConvo){
        [parentConvo incrementUnreadCount];
    }
}

+(KonotorMessage *)createNewMessage:(NSDictionary *)message{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    KonotorMessage *newMessage = (KonotorMessage *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];
    newMessage.messageAlias = [message valueForKey:@"alias"];
    newMessage.messageType = [message valueForKey:@"messageType"];
    newMessage.messageUserId = @"Sender-Agent";
    newMessage.bytes = [message valueForKey:@"bytes"];
    newMessage.durationInSecs = [message valueForKey:@"durationInSecs"];
    newMessage.read = [message valueForKey:@"read"];
    [newMessage setAudioURL:[message valueForKey:@"binaryUrl"]];
    [newMessage setText:[message valueForKey:@"text"]];
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
    [[KonotorDataManager sharedInstance]save];
    return newMessage;
}

+(NSArray *)getAllMessagesForConversation:(NSString* )conversationID;{
    KonotorConversation *convo = [KonotorConversation RetriveConversationForConversationId:conversationID];
    if(convo){
        NSSet *pMessagesSet =[NSSet setWithSet:[convo valueForKeyPath:@"hasMessages"]];
        NSMutableArray *pMessages = [NSMutableArray arrayWithArray:[pMessagesSet allObjects]];
        NSMutableArray *pMessageArrayToReturn = [[NSMutableArray alloc]init];
        for(int i =0;i<[pMessages count];i++){
            KonotorMessageData *message = [[pMessages objectAtIndex:i] ReturnMessageDataFromManagedObject] ;
            [pMessageArrayToReturn addObject:message];
        }
        return pMessageArrayToReturn;
    }
    return nil;
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
    
    if([message.messageType isEqualToNumber:[NSNumber numberWithInt:2]]){
        KonotorMessageBinary *pMessageBinary = (KonotorMessageBinary*)[self valueForKeyPath:@"hasMessageBinary"];
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
        
        KonotorMessageBinary *pMessageBinary = (KonotorMessageBinary*)[self valueForKeyPath:@"hasMessageBinary"];
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

+(NSArray *)getAllMesssageForChannel:(HLChannel *)channel{
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    NSArray *matches = channel.messages.allObjects;
    for (int i=0; i<matches.count; i++) {
        KonotorMessageData *message = [matches[i] ReturnMessageDataFromManagedObject];
        [messages addObject:message];
    }
    return messages;
}

@end