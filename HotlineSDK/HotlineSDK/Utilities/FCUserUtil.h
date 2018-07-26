//
//  HLUser.h
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

@interface FCUserUtil : NSObject
    
+(void)registerUser:(void(^)(NSError *error))completion;

+(BOOL)canRegisterUser;
+(BOOL)createUserAOT;
+(BOOL)hasMessageIintiated;
+(BOOL)isUserRegistered;
+(void)setUserMessageInitiated;

@end
