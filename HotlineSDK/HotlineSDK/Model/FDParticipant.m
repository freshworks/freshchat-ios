//
//  FDParticipant.m
//  HotlineSDK
//
//  Created by user on 10/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDParticipant.h"
#import "KonotorDataManager.h"

@implementation FDParticipant
@dynamic alias;
@dynamic name;
@dynamic profilePicURL;

+(void)createParticipantWithInfo : (NSDictionary *)participantInfo inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_PARTICIPANT];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"alias == %@",participantInfo[@"alias"]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 0) {
        [self createWithInfo:participantInfo inContext:context];
    }
    else{
        //update participants
    }
}

+(FDParticipant *)createWithInfo:(NSDictionary *) participantInfo inContext:(NSManagedObjectContext *)context{
    
    FDParticipant *paricipant = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_PARTICIPANT inManagedObjectContext:context];
    return [self updateParticipant:paricipant withInfo:participantInfo ];
}

- (void)updateWithInfo:(NSDictionary *)articleInfo{
    
    [FDParticipant updateParticipant:self withInfo:articleInfo];
}

+ (FDParticipant*) updateParticipant: (FDParticipant *) participant withInfo : (NSDictionary *) participantInfo{
    
    participant.name    = [participantInfo valueForKey: @"name"];
    participant.alias   = [participantInfo valueForKey: @"alias"];
    participant.alias   = [participantInfo valueForKey: @"profilePicURL"];
    return participant;
}

@end
