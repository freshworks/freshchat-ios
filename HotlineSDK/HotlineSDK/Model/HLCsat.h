//
//  HLCsat.h
//  HotlineSDK
//
//  Created by user on 10/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KonotorConversation.h"
#import "KonotorDataManager.h"

typedef enum {
    CSAT_RATED = 1,
    CSAT_NOT_RATED,
} CSAT_STATUS;

NS_ASSUME_NONNULL_BEGIN

@interface HLCsat : NSManagedObject

@property (nullable, nonatomic, retain) NSString *csatID;
@property (nullable, nonatomic, retain) NSString *conversationID;
@property (nullable, nonatomic, retain) NSString *question;
@property (nullable, nonatomic, retain) NSNumber *csatStatus;
@property (nullable, nonatomic, retain) NSString *userComments;
@property (nullable, nonatomic, retain) NSNumber *userRatingCount;
@property (nullable, nonatomic, retain) NSString *isIssueResolved;
@property (nullable, nonatomic, retain) NSNumber *mobileUserCommentsAllowed;
@property (nullable, nonatomic, retain) KonotorConversation *belongToConversation;


//Primary key : conversation ID
+(HLCsat *)getWithID:(NSString *)conversationID inContext:(NSManagedObjectContext *)context;
+(HLCsat *)updateCSAT:(HLCsat *)csat withInfo:(NSDictionary *)conversationInfo;
+(HLCsat *)createWithInfo:(NSDictionary *)conversationInfo inContext:(NSManagedObjectContext *)context;

@end


@interface HLCsatHolder : NSObject

@property (nonatomic, strong) NSString *userComments;
@property (nonatomic, assign) int userRatingCount;
@property (nonatomic, assign) BOOL isIssueResolved;

@end

NS_ASSUME_NONNULL_END
