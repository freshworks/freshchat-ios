//
//  HLChannel.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 19/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLChannel.h"
#import "KonotorConversation.h"
#import "Message.h"
#import "HLMacros.h"
#import "HotlineAppState.h"
#import "FDImageView.h"
#import "HLTags.h"

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
@dynamic isRestricted;

+(HLChannel *)createWithInfo:(NSDictionary *)channelInfo inContext:(NSManagedObjectContext *)context{
    HLChannel *channel = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CHANNEL_ENTITY inManagedObjectContext:context];
    return [self updateChannel:channel withInfo:channelInfo];
}

-(void)updateWithInfo:(NSDictionary *)channelInfo{
    [HLChannel updateChannel:self withInfo:channelInfo];
}

- (KonotorConversation*) primaryConversation{
    KonotorConversation *conversation;
    NSArray<KonotorConversation *> *conversations = self.conversations.allObjects;
    long conversationsCount = conversations.count;
    if (conversationsCount <= 1 ) {
        conversation = conversations.firstObject;
    }
    else {
        FDLog(@"Duplicate Conversation found for channel %@", self.channelID);
        for(int i=0; i < conversationsCount ; i++ ){
            KonotorConversation *conv =[conversations objectAtIndex:i];
            if(![conv.conversationAlias  isEqual:@"0"] ) {
                conversation = conv;
                FDLog(@"No Worries we found a match for channel %@", self.channelID);
            }
        }
    }
    return conversation;
}

-(BOOL)hasAtleastATag:(NSArray *) tags{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
    fetchRequest.predicate   = [NSPredicate predicateWithFormat:@"tagName IN %@ AND taggableType ==%d AND taggableID == %@ ",tags, HLTagTypeChannel,self.channelID];
    NSArray *matches         = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    return matches && matches > 0;
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
        [FDUtilities getFDImageWithURL:channel.iconURL withCompletion:^(UIImage *image) {
            FDLog(@"Image with url cached successfully %@", channel.iconURL)
        }];
    }
    
    if ([channelInfo objectForKey:@"restricted"]) {
        channel.isRestricted = channelInfo[@"restricted"];
    }else{
        channel.isRestricted = @NO;
    }
    
    Message *welcomeMessage = [Message getWelcomeMessageForChannel:channel];
    NSDictionary *welcomeMsgData = channelInfo[@"welcomeMessage"];
    if (welcomeMsgData) {
        if (welcomeMessage) {
            [Message removeWelcomeMessage:channel];
        }
        welcomeMessage = [Message createNewMessage:welcomeMsgData toChannelID:channel.channelID];
        welcomeMessage.createdMillis = @0;
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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"isDefault == YES"];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count >= 1) {
        channel = matches.firstObject;
    }
    return channel;
}

//assumes this method is called from whichever thread invokes this.
-(NSInteger)unreadCount{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_MESSAGE_ENTITY];
    NSPredicate *predicate =[NSPredicate predicateWithFormat:@"isRead == NO AND belongsToChannel == %@",self];
    request.predicate = predicate;
    NSArray *messages = [self.managedObjectContext executeFetchRequest:request error:nil];
    NSInteger pendingCSATCount =  [self.primaryConversation isCSATResponsePending] ? 1 : 0;
    return messages.count + pendingCSATCount;
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
        self.unreadMessages = channel.unreadCount;
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
