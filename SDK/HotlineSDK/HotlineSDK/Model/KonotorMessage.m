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
#import "KonotorApp.h"
#import "KonotorDataManager.h"

#define KONOTOR_IMG_COMPRESSION YES

@class KonotorConversationData;
@class KonotorMessageData;

@implementation KonotorMessage

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
    NSString *intervalString = [NSString stringWithFormat:@"%.0f", today*1000];
    NSString *userid = [KonotorUser GetUserAlias];
    NSString *messageID  =[NSString stringWithFormat:@"%@%@%@",userid,@"_",intervalString];
    return messageID;
}

+(void)insertLocalTextMessage : (NSString *) text Read:(BOOL) read IsWelcomeMessage:(BOOL) isWelcomeMessage{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage *message = (KonotorMessage *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];
    [message setMessageAlias:[KonotorMessage generateMessageID]];
    [message setMessageType:[NSNumber numberWithInt:1]];
    [message setMessageRead:read];
    [message setText:text];
    [message setUploadStatus:[NSNumber numberWithInt:2]];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    [datamanager save];
    
    KonotorUser *pUser = [KonotorUser GetCurrentlyLoggedInUser];
    if(pUser){
        KonotorConversation *pDefaultConvo = [pUser valueForKeyPath:@"defaultConversation"];
        [message associateMessageToConversation:pDefaultConvo];
        if(!read)
            [pDefaultConvo incrementUnreadCount];
    }
    
    if(isWelcomeMessage){
        NSURL *moURI = [[message objectID] URIRepresentation];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[moURI absoluteString] forKey:@"uriForWelcomeMessage"];
        [defaults synchronize];
    }
}

+(void)updateWelcomeMessageText:(NSString*)text{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *urlString = [defaults stringForKey:@"uriForWelcomeMessage"];
    if(urlString){
        NSURL *mouri = [NSURL URLWithString:urlString];
        NSPersistentStoreCoordinator *coord = [[KonotorDataManager sharedInstance]persistentStoreCoordinator];
        NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
        KonotorMessage *message = (KonotorMessage*)[context objectWithID:[coord managedObjectIDForURIRepresentation:mouri]];
        if(message){
            if([[message text] isEqualToString:text])
                return;
            message.text=text;
            [[KonotorDataManager sharedInstance] save];
        }
    }
}

+(KonotorMessage *)saveTextMessageInCoreData:(NSString *)text{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage *message = [NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];
    [message setMessageUserId:[KonotorUser GetUserAlias]];
    [message setMessageAlias:[KonotorMessage generateMessageID]];
    [message setMessageType:@1];
    [message setMessageRead:YES];
    [message setText:text];
    [message setCreatedMillis:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000]];
    [datamanager save];
    return message;
}

+(NSString*)savePictureMessageInCoreData:(UIImage *)image withCaption: (NSString *) caption{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    KonotorMessage *message = (KonotorMessage *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];
    [message setMessageUserId:[KonotorUser GetUserAlias]];
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
    [datamanager save];
    return message.messageAlias;
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

+(void) markMarketingMessageAsClicked:(NSNumber *) marketingId{
    
    if(![KonotorUser isUserCreatedOnServer]) return;
    
    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];
    
    if([marketingId intValue] ==0 || !marketingId) return;
    
    //PUT {appId}/user/{alias}/message/marketing/{marketingId}/status?delivered=1&clicked=1&seen=1&t={appkey}
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",app,@"/user/",user,@"/message/marketing/",[marketingId stringValue ],@"/status?clicked=1&t=",token];
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

-(void) MarkMarketingMessageAsRead{
    
    if(![KonotorUser isUserCreatedOnServer]) return;
    
    if([self messageRead])return;
    
    NSNumber *marketingId = [self marketingId];
    
    if([marketingId intValue] ==0 || !marketingId) return;
    
    //mark as read, if the call fails we can mark it as unread.
    [self MarkAsRead];

    NSURL *url = [NSURL URLWithString:[KonotorUtil GetBaseURL]];
    AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    
    NSString *app = [KonotorApp GetAppID];
    NSString *user = [KonotorUser GetUserAlias];
    NSString *token = [KonotorApp GetAppKey];
    
    //PUT {appId}/user/{alias}/message/marketing/{marketingId}/status?delivered=1&clicked=1&seen=1&t={appkey}
    NSString *postPath = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",@"services/app/",app,@"/user/",user,@"/message/marketing/",[marketingId stringValue ],@"/status?seen=1&t=",token];
    
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
            for(int i=0;i<[array count];i++){
                KonotorMessage *message = [array objectAtIndex:i];
                if(message){
                    KonotorConversation *convo = [message valueForKey:@"belongsToConversation"];
                    if (convo) {
                        [KonotorWebServices uploadMessage:message toConversation:convo onChannel:nil];
                    }
                }
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
        NSLog(@"%@", @"Multiple Messages stored with the same message Id");
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
    [messageDict setObject:[self messageAlias] forKey:@"alias"];
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

+(KonotorMessage *)createNewMessage: (KonotorMessage *)message{
    NSManagedObjectContext *context = [KonotorDataManager sharedInstance].mainObjectContext;
    KonotorMessage *newMessage = (KonotorMessage *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorMessage" inManagedObjectContext:context];
    newMessage.messageAlias = [message valueForKey:@"alias"];
    newMessage.messageType = [message valueForKey:@"messageType"];
    newMessage.messageUserId = [message valueForKey:@"messageUserAlias"];
    newMessage.bytes = [message valueForKey:@"bytes"];
    newMessage.durationInSecs = [message valueForKey:@"durationInSecs"];
    newMessage.read = [message valueForKey:@"read"];
    [newMessage setAudioURL:[message valueForKey:@"binaryUrl"]];
    [newMessage setText:[message valueForKey:@"text"]];
    [newMessage setCreatedMillis:[message valueForKey:@"createdMillis"]];
    [newMessage setMarketingId:[message valueForKey:@"marketingId"]];
    [newMessage setActionLabel:[message valueForKey:@"messageActionLabel"]];
    [newMessage setActionURL:[message valueForKey:@"messageActionUrl"]];
    
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

+(NSArray *)getAllMessagesForDefaultConversation{
    KonotorUser *pUser = [KonotorUser GetCurrentlyLoggedInUser];
    if(pUser){
        KonotorConversation *pDefaultConvo = [pUser valueForKeyPath:@"defaultConversation"];
        if(pDefaultConvo){
            NSSet *pMessagesSet =[NSSet setWithSet:[pDefaultConvo valueForKeyPath:@"hasMessages"]];
            NSMutableArray *pMessages = [NSMutableArray arrayWithArray:[pMessagesSet allObjects]];
            NSMutableArray *pMessageArrayToReturn = [[NSMutableArray alloc]init];
            for(int i =0;i<[pMessages count];i++){
                KonotorMessageData *message = [[pMessages objectAtIndex:i] ReturnMessageDataFromManagedObject] ;
                [pMessageArrayToReturn addObject:message];
            }
            return pMessageArrayToReturn;
        }

    }
    return nil;
}

-(KonotorMessageData *) ReturnMessageDataFromManagedObject{
    KonotorMessageData *message = [[KonotorMessageData alloc]init];
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

+(KonotorMessageData *)getWelcomeMessageForChannel:(HLChannel *)channel{
    return [channel.welcomeMessage ReturnMessageDataFromManagedObject];
}

+(NSArray *)getAllMesssageForChannel:(HLChannel *)channel{
    KonotorDataManager *datamanager = [KonotorDataManager sharedInstance];
    NSManagedObjectContext *context = [datamanager mainObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"KonotorMessage"];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"belongsToChannel.channelID == %@",channel.channelID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    NSMutableArray *messages = [[NSMutableArray alloc]init];
    for (int i=0; i<matches.count; i++) {
        KonotorMessageData *message = [matches[i] ReturnMessageDataFromManagedObject];
        [messages addObject:message];
    }
    return messages;
}

@end