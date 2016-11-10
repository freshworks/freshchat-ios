//
//  FDCsat.h
//  HotlineSDK
//
//  Created by user on 10/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface FDCsat : NSManagedObject

@property (nullable, nonatomic, copy) NSNumber *csatID;
@property (nullable, nonatomic, copy) NSString *question;
@property (nullable, nonatomic, copy) NSNumber *isManadatory;
@property (nullable, nonatomic, copy) NSNumber *mobileUserCommentsAllowed;


@end

NS_ASSUME_NONNULL_END
