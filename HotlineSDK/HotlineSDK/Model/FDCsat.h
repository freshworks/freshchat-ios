//
//  FDCsat.h
//  HotlineSDK
//
//  Created by user on 10/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KonotorConversation.h"

typedef enum {
    CSAT_RATED = 1,
    CSAT_NOT_RATED,
    CSAT_SENT
} CSAT_STATUS;

NS_ASSUME_NONNULL_BEGIN

@interface FDCsat : NSManagedObject

@property (nullable, nonatomic, retain) NSString *csatID;
@property (nullable, nonatomic, retain) NSString *conversationID;
@property (nullable, nonatomic, retain) NSString *question;
@property (nullable, nonatomic, retain) NSNumber *csatStatus;
@property (nullable, nonatomic, retain) NSString *userComments;
@property (nullable, nonatomic, retain) NSNumber *userRatingCount;
@property (nullable, nonatomic, retain) NSString *isIssueResolved;
@property (nullable, nonatomic, retain) NSNumber *mobileUserCommentsAllowed;
@property (nullable, nonatomic, retain) KonotorConversation *belongToConversation;


@end

NS_ASSUME_NONNULL_END
