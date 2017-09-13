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
@dynamic firstName;
@dynamic lastName;
@dynamic profilePicURL;

+(void)addParticipantWithInfo : (NSDictionary *)participantInfo inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_PARTICIPANT];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"alias == %@",participantInfo[@"alias"]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 0) {
        [self createWithInfo:participantInfo inContext:context];
    }
    else{
        [self updateParticipant:matches.firstObject withInfo:participantInfo];
        [context save:nil];
    }
}

+(FDParticipant *)createWithInfo:(NSDictionary *) participantInfo inContext:(NSManagedObjectContext *)context{
    
    FDParticipant *paricipant = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_PARTICIPANT inManagedObjectContext:context];
    return [self updateParticipant:paricipant withInfo:participantInfo ];
}

+ (FDParticipant*) updateParticipant: (FDParticipant *) participant withInfo : (NSDictionary *) participantInfo{
    participant.firstName      = [participantInfo valueForKey: @"firstName"];
    participant.lastName       = [participantInfo valueForKey: @"lastName"];
    participant.alias          = [participantInfo valueForKey: @"alias"];
    participant.profilePicURL  = [participantInfo valueForKey: @"profilePicURL"];
    return participant;
}

+(FDParticipant *) fetchParticipantForAlias : (NSString *) alias inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_PARTICIPANT];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"alias == %@",alias];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        return matches.firstObject;
    }
    return nil;
}

@end
