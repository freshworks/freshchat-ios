//
//  KonotorMessageBinary.h
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FCMessageUtil;

@interface FCMessageBinaries : NSManagedObject

@property (nonatomic, retain) NSData * binaryAudio;
@property (nonatomic, retain) NSData * binaryImage;
@property (nonatomic, retain) NSData * binaryThumbnail;

@property (nonatomic, retain) FCMessageUtil *belongsToMessage;

@end
