//
//  Fragment.h
//  HotlineSDK
//
//  Created by user on 01/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "KonotorDataManager.h"
#import "Message.h"
#import "MessageData.h"

@class Fragment;

NS_ASSUME_NONNULL_BEGIN

enum FragmentStatus {
    ToBeDownloaded          = 1,
    ToBeUploaded            = 2,
    UploadDownloadComplete  = 3,
};


@interface Fragment : NSManagedObject
    @property (nullable, nonatomic, retain) NSString *content;
    @property (nullable, nonatomic, retain) NSString *contentType;
    @property (nullable, nonatomic, retain) NSString *extraJSON;
    @property (nullable, nonatomic, retain) NSString *type;
    @property (nullable, nonatomic, retain) NSNumber *index;
    @property (nullable, nonatomic, retain) NSNumber *status;
    @property (nonatomic,retain) NSData *binaryData1;
    @property (nonatomic,retain) NSData *binaryData2;
    +(NSArray *)getAllFragments:(Message *) message;
    +(NSArray *)getAllFragmentsInDictionary:(Message *) message;
    +(void)createFragments:(NSArray *) dictArr toMessage:(Message *) message;
    +(Fragment *) createUploadFragment: (NSDictionary *)fragmentInfo toMessage:(Message *) message;
    +(Fragment *) getImageFragment: (Message *)messsage;
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
    -(void)storeImageDataOfMessage:(MessageData *)message withCompletion:(void (^)())completion;
@end

NS_ASSUME_NONNULL_END
