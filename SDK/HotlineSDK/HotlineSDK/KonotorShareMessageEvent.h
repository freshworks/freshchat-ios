//
//  KonotorShareMessageEvent.h
//  Konotor
//
//  Created by Vignesh G on 08/10/14.
//  Copyright (c) 2014 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KonotorShareMessageEvent : NSManagedObject

@property (nonatomic, retain) NSString * messageID;
@property (nonatomic, retain) NSString * shareType;
@property (nonatomic,retain) NSNumber *uploadStatus;
+(KonotorShareMessageEvent*) sharedMessageWithID:(NSString *)messageID withShareType:(NSString *)shareType;
+(void) UploadAllUnuploadedEvents;
@end
