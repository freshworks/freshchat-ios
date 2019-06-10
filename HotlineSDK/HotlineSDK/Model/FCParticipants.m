//
//  FDParticipant.m
//  HotlineSDK
//
//  Created by user on 10/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCParticipants.h"
#import "FCDataManager.h"

@implementation FCParticipants
@dynamic alias;
@dynamic firstName;
@dynamic lastName;
@dynamic profilePicURL;

+(void)addParticipantWithInfo : (NSDictionary *)participantInfo inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_PARTICIPANTS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"alias == %@",participantInfo[@"alias"]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 0) {
        [self createWithInfo:participantInfo inContext:context];
    }
    else{
        [self updateParticipant:matches.firstObject withInfo:participantInfo];
    }
    [context save:nil];
}

+(FCParticipants *)createWithInfo:(NSDictionary *) participantInfo inContext:(NSManagedObjectContext *)context{
    FCParticipants *paricipant = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_PARTICIPANTS_ENTITY inManagedObjectContext:context];
    return [self updateParticipant:paricipant withInfo:participantInfo ];
}

+ (FCParticipants*) updateParticipant: (FCParticipants *) participant withInfo : (NSDictionary *) participantInfo{
    participant.firstName      = participantInfo [@"firstName"];
    //For system generated names last name won't be available
    participant.lastName       = participantInfo [@"lastName"] ? participantInfo [@"lastName"] :@"";
    participant.alias          = participantInfo [@"alias"] ? participantInfo [@"alias"] :@"";
    participant.profilePicURL  = participantInfo [@"profilePicUrl"];
    return participant;
}

+(FCParticipants *) fetchParticipantForAlias : (NSString *) alias inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_PARTICIPANTS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"alias == %@",alias];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    return matches.firstObject;
}

@end
