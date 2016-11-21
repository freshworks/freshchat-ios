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
@dynamic conversationID;
@dynamic question;
@dynamic mobileUserCommentsAllowed;
@dynamic belongToConversation;
@dynamic userRatingCount;
@dynamic csatStatus;
@dynamic userComments;
@dynamic isIssueResolved;

+(FDCsat *)getWithID:(NSString *)conversationID inContext:(NSManagedObjectContext *)context{
    FDCsat *csat = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CSAT_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"conversationID == %@",conversationID];
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

+(FDCsat *)updateCSAT:(FDCsat *)csat withInfo:(NSDictionary *)conversationInfo{
    csat.conversationID = [[conversationInfo valueForKey:@"conversationId"]stringValue];
    csat.csatID = [[conversationInfo valueForKeyPath:@"csat.csatId"]stringValue];
    csat.question = [conversationInfo valueForKeyPath:@"csat.question"];
    csat.mobileUserCommentsAllowed = @([[conversationInfo valueForKeyPath:@"csat.mobileUserCommentsAllowed"]boolValue]);
    return csat;
}

+(FDCsat *)createWithInfo:(NSDictionary *)conversationInfo inContext:(NSManagedObjectContext *)context{
    FDCsat *csat = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_CSAT_ENTITY inManagedObjectContext:context];
    csat.csatStatus = @(CSAT_NOT_RATED);
    return [self updateCSAT:csat withInfo:conversationInfo];
}

@end


@implementation FDCsatHolder

- (instancetype)init{
    self = [super init];
    if (self) {
        self.userComments = nil;
        self.userRatingCount = 0;
        self.isIssueResolved = NO;
    }
    return self;
}

@end
