//
//  FCJWTUtilities.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 09/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FCJWTUtilities : NSObject

+ (NSDictionary *) getJWTUserPayloadFromToken : (NSString *) token;

+ (BOOL) isUserAuthEnabled;

@end

