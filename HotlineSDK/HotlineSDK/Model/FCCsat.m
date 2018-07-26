//
//  HLCsat.m
//  HotlineSDK
//
//  Created by user on 10/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCMacros.h"
#import "FCCsat.h"

@implementation FCCsat

@dynamic csatID;
@dynamic conversationID;
@dynamic question;
@dynamic mobileUserCommentsAllowed;
@dynamic belongToConversation;
@dynamic userRatingCount;
@dynamic csatStatus;
@dynamic userComments;
@dynamic isIssueResolved;
@dynamic initiatedTime;

+(FCCsat *)getWithID:(NSString *)conversationID inContext:(NSManagedObjectContext *)context{
    FCCsat *csat = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CSAT_ENTITY];
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

+(FCCsat *)updateCSAT:(FCCsat *)csat withInfo:(NSDictionary *)conversationInfo{
    csat.conversationID = [[conversationInfo valueForKey:@"conversationId"]stringValue];
    csat.csatID = [[conversationInfo valueForKeyPath:@"csat.csatId"]stringValue];
    csat.question = [conversationInfo valueForKeyPath:@"csat.question"];
    csat.mobileUserCommentsAllowed = @([[conversationInfo valueForKeyPath:@"csat.mobileUserCommentsAllowed"]boolValue]);
    csat.initiatedTime = [conversationInfo valueForKeyPath:@"csat.initiated"];
    return csat;
}

+(FCCsat *)createWithInfo:(NSDictionary *)conversationInfo inContext:(NSManagedObjectContext *)context{
    FCCsat *csat = [NSEntityDescription insertNewObjectForEntityForName:FRESHCHAT_CSAT_ENTITY inManagedObjectContext:context];
    csat.csatStatus = @(CSAT_NOT_RATED);
    return [self updateCSAT:csat withInfo:conversationInfo];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    if (nil == self.initiatedTime) {
        [self willChangeValueForKey:@"initiatedTime"];
        self.initiatedTime = [NSNumber numberWithLong: [[NSDate date] timeIntervalSince1970] * 1000];
        [self didChangeValueForKey:@"initiatedTime"];
    }
}

@end


@implementation HLCsatHolder

- (instancetype)init{
    self = [super init];
    if (self) {
        self.userComments = @"";
        self.userRatingCount = 0;
        self.isIssueResolved = NO;
    }
    return self;
}

@end
