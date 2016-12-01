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
#import "HotlineAppState.h"

@implementation HLChannel

@dynamic channelID;
@dynamic type;
@dynamic created;
@dynamic icon;
@dynamic iconURL;
@dynamic isHidden;
@dynamic isDefault;
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

-(BOOL)isActiveChannel{
    HLChannel *currentVisibleChannel = [HotlineAppState sharedInstance].currentVisibleChannel;
    if(currentVisibleChannel && [currentVisibleChannel.channelID isEqual:self.channelID]){
        return TRUE;
    }
    return FALSE;
}

+(HLChannel *)updateChannel:(HLChannel *)channel withInfo:(NSDictionary *)channelInfo{
    channel.name = channelInfo[@"name"];
    channel.type = channelInfo[@"type"];
    channel.channelID = channelInfo[@"channelId"];
    channel.iconURL = channelInfo[@"iconUrl"];
    channel.icon = nil;
    channel.position = channelInfo[@"position"];
    channel.lastUpdated = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"updated"]doubleValue]];
    channel.created = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"created"]doubleValue]];
    channel.isHidden = channelInfo[@"hidden"];
    KonotorMessage *welcomeMessage = [KonotorMessage getWelcomeMessageForChannel:channel];
    NSString *updatedMessage = trimString(channelInfo[@"welcomeMessage"][@"text"]); //set welcome message here
    if (welcomeMessage) {
        welcomeMessage.text = updatedMessage;
    }else{
        welcomeMessage = [KonotorMessage createNewMessage:channelInfo[@"welcomeMessage"]];
        welcomeMessage.text = updatedMessage;
        welcomeMessage.createdMillis = @0;
        welcomeMessage.isWelcomeMessage = YES;
        welcomeMessage.messageRead = YES;
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
        FDLog(@"Duplicates found in Channel table !");
    }
    return channel;
}


+(HLChannel *)getWithName:(NSString *)name inContext:(NSManagedObjectContext *)context{
    HLChannel *channel = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"name == [cd] %@",name];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastUpdated" ascending:NO]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count > 0) {
        channel = matches.firstObject;
    }
    return channel;
}

+(HLChannel *)getDefaultChannelInContext:(NSManagedObjectContext *)context{
    HLChannel *channel = nil;
    //TODO: Sort by created because we don't store default channel - Fix this later
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES]];
    
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count > 0) {
        channel = matches.firstObject;
    }
    return channel;
}

@end


@implementation HLChannelInfo

-(HLChannelInfo *)initWithChannel:(HLChannel *)channel{
    self = [super init];
    if (self) {
        self.name = channel.name;
        self.iconURL = channel.iconURL;
        self.icon = channel.icon;
        self.channelID = channel.channelID;
    }
    return self;
}

-(NSData *)icon{
    return [HLChannel getWithID:self.channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext].icon;
}

-(void)setIcon:(NSData *)icon{
    if (icon) {
        [HLChannel getWithID:self.channelID inContext:[KonotorDataManager sharedInstance].mainObjectContext].icon = icon;
        [[KonotorDataManager sharedInstance]save];
    }
}

@end
