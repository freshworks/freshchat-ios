//
//  HLChannel.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLChannel.h"
#import "KonotorConversation.h"
#import "KonotorMessage.h"
#import "HLMacros.h"

@implementation HLChannel

@dynamic channelID;
@dynamic type;
@dynamic created;
@dynamic icon;
@dynamic iconURL;
@dynamic isHidden;
@dynamic lastUpdated;
@dynamic name;
@dynamic position;
@dynamic conversations;
@dynamic messages;

+(HLChannel *)createWithInfo:(NSDictionary *)channelInfo inContext:(NSManagedObjectContext *)context{
    HLChannel *channel = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CHANNEL_ENTITY inManagedObjectContext:context];
    return [self updateChannel:channel withInfo:channelInfo];
}

-(void)updateWithInfo:(NSDictionary *)channelInfo{
    [HLChannel updateChannel:self withInfo:channelInfo];
}

- (KonotorConversation*) primaryConversation{
    return self.conversations.allObjects.firstObject;
}

+(HLChannel *)updateChannel:(HLChannel *)channel withInfo:(NSDictionary *)channelInfo{
    channel.name = channelInfo[@"name"];
    channel.type = channelInfo[@"type"];
    channel.channelID = channelInfo[@"channelId"];
    channel.iconURL = channelInfo[@"iconUrl"];
    channel.position = channelInfo[@"position"];
    channel.lastUpdated = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"updated"]doubleValue]];
    channel.created = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"created"]doubleValue]];
    channel.isHidden = channelInfo[@"hidden"];
    
    //TODO: Use this prefetch when channel is created with background context
    
    //Prefetch category icon
    
    //    __block NSData *imageData = nil;
    //    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //        imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:channelInfo[@"iconUrl"]]];
    //    });
    //    channel.icon = imageData;
    
    
    KonotorMessage *welcomeMessage = [KonotorMessage getWelcomeMessageForChannel:channel];
    if (welcomeMessage) {
        NSString *updatedMessage = channelInfo[@"welcomeMessage"][@"text"]; //set welcome message here
        welcomeMessage.text = updatedMessage;
        FDLog(@"Welcome message of channel: \"%@\" is updated !", channel.name);
    }else{
        welcomeMessage = [KonotorMessage createNewMessage:channelInfo[@"welcomeMessage"]];
        welcomeMessage.createdMillis = @([[NSDate date] timeIntervalSince1970] *1000);
        welcomeMessage.isWelcomeMessage = YES;
        [channel addMessagesObject:welcomeMessage];
    }
    
    return channel;
}

+(HLChannel *)getWithID:(NSNumber *)channelID inContext:(NSManagedObjectContext *)context{
    HLChannel *channel = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"channelID == %@",channelID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        channel = matches.firstObject;
    }
    if (matches.count > 1) {
        channel = nil;
        FDLog(@"Duplicates found in Category table !");
    }
    return channel;
}



@end
