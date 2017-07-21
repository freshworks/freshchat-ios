//
//  FDLocaleUtil.h
//  HotlineSDK
//
//  Created by Sanjith J K on 17/02/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDLocaleUtil : NSObject

+(NSString *)getLocalLocale;
+(NSString *)getUserLocale;
+(NSArray *)userLocaleParams:(BOOL)voteReq;
+ (NSArray *) channelLocaleParams;
+(NSNumber *)getContentLocaleId;
+(NSNumber *) getConvLocaleId;
+(void)updateLocale:(NSString *)localLocale;
+(BOOL)hadLocaleChange;

@end
