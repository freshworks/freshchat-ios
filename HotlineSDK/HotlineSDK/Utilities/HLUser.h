//
//  HLUser.h
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

@interface HLUser : NSObject
    
+(void)registerUser:(void(^)(NSError *error))completion;

+(BOOL)canDeferUser;
+(BOOL)canRegisterUser;
+(BOOL)hasMessageIintiated;
+(BOOL)isUserRegistered;
+(void)setUserMessageInitiated;

@end
