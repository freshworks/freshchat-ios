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
    participant.firstName      = [participantInfo valueForKey: @"firstName"];
    participant.lastName       = [participantInfo valueForKey: @"lastName"];
    participant.alias          = [participantInfo valueForKey: @"alias"] ? [participantInfo valueForKey: @"alias"] :@"";
    participant.profilePicURL  = [participantInfo valueForKey: @"profilePicUrl"];
    return participant;
}

+(FCParticipants *) fetchParticipantForAlias : (NSString *) alias inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_PARTICIPANTS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"alias == %@",alias];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    return matches.firstObject;
}

@end
