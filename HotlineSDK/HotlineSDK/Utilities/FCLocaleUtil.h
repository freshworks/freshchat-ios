//
//  FDLocaleUtil.h
//  HotlineSDK
//
//  Created by Sanjith J K on 17/02/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCLocaleUtil : NSObject

+(NSString *)getLocalLocale;
+(NSString *)getUserLocale;
+(NSArray *)userLocaleParams:(BOOL)voteReq;
+ (NSArray *) channelLocaleParams;
+(NSNumber *)getContentLocaleId;
+(NSNumber *) getConvLocaleId;
+(void)updateLocaleWith:(NSString *)localLocale;
+(void)updateLocale;
+(BOOL)hadLocaleChange;

@end
