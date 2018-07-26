//
//  HLCsat.h
//  HotlineSDK
//
//  Created by user on 10/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FCConversations.h"
#import "FCDataManager.h"

typedef enum {
    CSAT_RATED = 1,
    CSAT_NOT_RATED,
} CSAT_STATUS;

NS_ASSUME_NONNULL_BEGIN

@interface FCCsat : NSManagedObject

@property (nullable, nonatomic, retain) NSString *csatID;
@property (nullable, nonatomic, retain) NSString *conversationID;
@property (nullable, nonatomic, retain) NSString *question;
@property (nullable, nonatomic, retain) NSNumber *csatStatus;
@property (nullable, nonatomic, retain) NSString *userComments;
@property (nullable, nonatomic, retain) NSNumber *userRatingCount;
@property (nullable, nonatomic, retain) NSString *isIssueResolved;
@property (nullable, nonatomic, retain) NSNumber *mobileUserCommentsAllowed;
@property (nullable, nonatomic, retain) FCConversations *belongToConversation;
@property (nullable, nonatomic, retain) NSNumber *initiatedTime;

//Primary key : conversation ID
+(FCCsat *)getWithID:(NSString *)conversationID inContext:(NSManagedObjectContext *)context;
+(FCCsat *)updateCSAT:(FCCsat *)csat withInfo:(NSDictionary *)conversationInfo;
+(FCCsat *)createWithInfo:(NSDictionary *)conversationInfo inContext:(NSManagedObjectContext *)context;

@end


@interface HLCsatHolder : NSObject

@property (nonatomic, strong) NSString *userComments;
@property (nonatomic, assign) int userRatingCount;
@property (nonatomic, assign) BOOL isIssueResolved;

@end

NS_ASSUME_NONNULL_END
