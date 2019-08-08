//
//  HLChannel.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCChannels.h"
#import "FCConversations.h"
#import "FCMessages.h"
#import "FCMacros.h"
#import "HotlineAppState.h"
#import "FDImageView.h"
#import "FCTags.h"
#import "FCCSATUtil.h"
#import "FCRemoteConfig.h"
#import "FCSecureStore.h"
#import "FCMessageHelper.h"

@implementation FCChannels

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
@dynamic isRestricted;

+(FCChannels *)createWithInfo:(NSDictionary *)channelInfo inContext:(NSManagedObjectContext *)context{
    FCChannels *channel = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_CHANNELS_ENTITY inManagedObjectContext:context];
    return [self updateChannel:channel withInfo:channelInfo];
}

-(void)updateWithInfo:(NSDictionary *)channelInfo{
    [FCChannels updateChannel:self withInfo:channelInfo];
}

- (FCConversations*) primaryConversation{
    FCConversations *conversation;
    NSArray<FCConversations *> *conversations = self.conversations.allObjects;
    long conversationsCount = conversations.count;
    if (conversationsCount <= 1 ) {
        conversation = conversations.firstObject;
    }
    else {
        FDLog(@"Duplicate Conversation found for channel %@", self.channelID);
        for(int i=0; i < conversationsCount ; i++ ){
            FCConversations *conv =[conversations objectAtIndex:i];
            if(![conv.conversationAlias  isEqual:@"0"] ) {
                conversation = conv;
                FDLog(@"No Worries we found a match for channel %@", self.channelID);
            }
        }
    }
    return conversation;
}

-(BOOL)hasAtleastATag:(NSArray *) tags{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_TAGS_ENTITY];
    fetchRequest.predicate   = [NSPredicate predicateWithFormat:@"tagName IN %@ AND taggableType ==%d AND taggableID == %@ ",tags, HLTagTypeChannel,self.channelID];
    NSArray *matches         = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    return matches && matches > 0;
}

-(BOOL)isActiveChannel{
    FCChannels *currentVisibleChannel = [HotlineAppState sharedInstance].currentVisibleChannel;
    if(currentVisibleChannel && [currentVisibleChannel.channelID isEqual:self.channelID]){
        return TRUE;
    }
    return FALSE;
}

+(FCChannels *)updateChannel:(FCChannels *)channel withInfo:(NSDictionary *)channelInfo{
    channel.name = channelInfo[@"name"];
    channel.isDefault = channelInfo[@"defaultChannel"];
    channel.type = channelInfo[@"type"];
    channel.channelID = channelInfo[@"channelId"];
    channel.iconURL = channelInfo[@"iconUrl"];
    channel.icon = nil;
    channel.position = channelInfo[@"position"];
    channel.lastUpdated = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"updated"]doubleValue]];
    channel.created = [NSDate dateWithTimeIntervalSince1970:[channelInfo[@"created"]doubleValue]];
    channel.isHidden = channelInfo[@"hidden"];
    
    //FDwebimage prefetch image and will be used by channel fetch
    if(channel.iconURL){
        [FCUtilities cacheImageWithUrl:channel.iconURL];
    }
    
    if ([channelInfo objectForKey:@"restricted"]) {
        channel.isRestricted = channelInfo[@"restricted"];
    }else{
        channel.isRestricted = @NO;
    }
    
    FCMessages *welcomeMessage = [FCMessages getWelcomeMessageForChannel:channel];
    NSDictionary *welcomeMsgData = channelInfo[@"welcomeMessage"];
    if (welcomeMsgData) {
        if (welcomeMessage) {
            [FCMessages removeWelcomeMessage:channel];
        }
        welcomeMessage = [FCMessages createNewMessage:welcomeMsgData toChannelID:channel.channelID];
        welcomeMessage.createdMillis = @0;
        [channel addMessagesObject:welcomeMessage];
    }
    return channel;
}

+(FCChannels *)getWithID:(NSNumber *)channelID inContext:(NSManagedObjectContext *)context{
    FCChannels *channel = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
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


+(FCChannels *)getWithName:(NSString *)name inContext:(NSManagedObjectContext *)context{
    FCChannels *channel = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"name == [cd] %@",name];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastUpdated" ascending:NO]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count > 0) {
        channel = matches.firstObject;
    }
    return channel;
}

+(FCChannels *)getDefaultChannelInContext:(NSManagedObjectContext *)context{
    FCChannels *channel = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isDefault == YES"];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count >= 1) {
        channel = matches.firstObject;
    }
    return channel;
}

//assumes this method is called from whichever thread invokes this.
-(NSInteger)unreadCount{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_MESSAGES_ENTITY];
    NSPredicate *predicate;
    
    if([FCRemoteConfig sharedInstance].conversationConfig.hideResolvedConversation){
        long long hideConvResolvedMillis = [FCMessageHelper getResolvedConvsHideTimeForChannel:self.channelID];
        predicate = hideConvResolvedMillis ? [NSPredicate predicateWithFormat:@"isRead == NO AND belongsToChannel == %@ AND messageType < 1000 AND createdMillis.longValue > %ld", self, hideConvResolvedMillis] : [NSPredicate predicateWithFormat:@"isRead == NO AND belongsToChannel == %@ AND messageType < 1000", self];
    }
    else{
        predicate =[NSPredicate predicateWithFormat:@"isRead == NO AND belongsToChannel == %@ AND messageType < 1000", self];
    }
    request.predicate = predicate;
    NSArray *messages = [self.managedObjectContext executeFetchRequest:request error:nil];
    BOOL hasExpiredCSAT = [FCCSATUtil isCSATExpiredForInitiatedTime:[self.primaryConversation.hasCsat.allObjects.firstObject.initiatedTime longValue]];
    NSInteger pendingCSATCount = ([self.primaryConversation isCSATResponsePending] && !hasExpiredCSAT)? 1 : 0;
    return messages.count + pendingCSATCount;
}

@end


@implementation FCChannelInfo

-(FCChannelInfo *)initWithChannel:(FCChannels *)channel{
    self = [super init];
    if (self) {
        self.name = channel.name;
        self.iconURL = channel.iconURL;
        self.icon = channel.icon;
        self.channelID = channel.channelID;
        self.unreadMessages = channel.unreadCount;
    }
    return self;
}

-(NSData *)icon{
    return [FCChannels getWithID:self.channelID inContext:[FCDataManager sharedInstance].mainObjectContext].icon;
}

-(void)setIcon:(NSData *)icon{
    if (icon) {
        [FCChannels getWithID:self.channelID inContext:[FCDataManager sharedInstance].mainObjectContext].icon = icon;
        [[FCDataManager sharedInstance]save];
    }
}

@end
