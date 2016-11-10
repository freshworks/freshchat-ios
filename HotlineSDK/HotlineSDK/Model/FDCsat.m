//
//  FDCsat.m
//  HotlineSDK
//
//  Created by user on 10/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDCsat.h"
#import "HLMacros.h"

@implementation FDCsat

@dynamic csatID;
@dynamic question;
@dynamic mobileUserCommentsAllowed;
@dynamic belongsToConversation;
@dynamic userRatingCount;
@dynamic status;
@dynamic userComments;

+(FDCsat *)getWithID:(NSNumber *)csatID inContext:(NSManagedObjectContext *)context{
    FDCsat *csat = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CSAT_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"csatID == %@",csatID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        csat = matches.firstObject;
    }
    if (matches.count > 1) {
        csat = nil;
        FDLog(@"Duplicates found in CSAT table !");
    }
    return csat;
}


+(FDCsat *)createWithInfo:(NSDictionary *)csatInfo inContext:(NSManagedObjectContext *)context{
    FDCsat *csat = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CSAT_ENTITY inManagedObjectContext:context];
    csat.csatID = csatInfo[@"csatId"];
    csat.question = csatInfo[@"question"];
    csat.mobileUserCommentsAllowed = [csatInfo valueForKeyPath:@"mobileUserCommentsAllowed"];
    csat.status = @(CSAT_NOT_RATED);
    return csat;
}

@end
