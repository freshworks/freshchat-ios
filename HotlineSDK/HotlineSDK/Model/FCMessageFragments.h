//
//  Fragment.h
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FCDataManager.h"
#import "FCMessages.h"
#import "FCMessageData.h"

@class FCMessageFragments;

NS_ASSUME_NONNULL_BEGIN

enum FragmentStatus {
    ToBeDownloaded          = 1,
    ToBeUploaded            = 2,
    UploadDownloadComplete  = 3,
};


@interface FCMessageFragments : NSManagedObject
    @property (nullable, nonatomic, retain) NSString *content;
    @property (nullable, nonatomic, retain) NSString *contentType;
    @property (nullable, nonatomic, retain) NSString *extraJSON;
    @property (nullable, nonatomic, retain) NSString *type;
    @property (nullable, nonatomic, retain) NSNumber *index;
    @property (nullable, nonatomic, retain) NSNumber *status;
    @property (nonatomic,retain) NSData *binaryData1;
    @property (nonatomic,retain) NSData *binaryData2;
    +(NSArray *)getAllFragments:(FCMessages *) message;
    +(NSArray *)getAllFragmentsInDictionary:(FCMessages *) message;
    +(void)createFragments:(NSArray *) dictArr toMessage:(FCMessages *) message;
    +(FCMessageFragments *) createUploadFragment: (NSDictionary *)fragmentInfo toMessage:(FCMessages *) message;
    +(FCMessageFragments *) getImageFragment: (FCMessages *)messsage;
    - (NSDictionary *)toDictionary;
    -(void)updateWithInfo:(NSDictionary *)info;
@end

@interface FragmentData : NSObject
    @property (nullable, nonatomic, retain) NSString *content;
    @property (nullable, nonatomic, retain) NSString *contentType;
    @property (nullable, nonatomic, retain) NSString *extraJSON;
    @property (nullable, nonatomic, retain) NSString *type;
    @property (nullable, nonatomic, retain) NSNumber *index;
    @property (nullable, nonatomic, retain) NSNumber *status;
    @property (nonatomic,retain) NSData *binaryData1;
    @property (nonatomic,retain) NSData *binaryData2;

    -(void)storeImageDataOfMessage:(FCMessageData *)message withCompletion:(void (^)())completion;
    - (NSURL *) getOpenURL;
    - (BOOL)isQuickReplyFragment;
@end

NS_ASSUME_NONNULL_END
