//
//  FDError.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 19/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDError_h
#define FreshdeskSDK_FDError_h

#import <Foundation/Foundation.h>

#define MOBIHELP_ERROR_DOMAIN @"COM.FRESHDESK.MOBIHELP_ERROR_DOMAIN"

typedef NS_ENUM(NSInteger, MOBIHELP_ERROR_TYPE) {
    MOBIHELP_ERROR_APP_DELETED = 1,
    MOBIHELP_ERROR_ACCOUNT_SUSPENDED,
    MOBIHELP_ERROR_NETWORK_CONNECTIVITY,
    MOBIHELP_ERROR_INVALID_APP_CREDENTIALS,
    MOBIHELP_MULTIPLE_ERRORS,
    MOBIHELP_UNEXPECTED_ERROR,
    MOBIHELP_ERROR_INVALID_RESPONSE,
    MOBIHELP_NO_TICKET_EXISTS,
    MOBIHELP_DEFAULT_ERROR
};

@interface FDError : NSError

-(FDError *)initWithError:(MOBIHELP_ERROR_TYPE)errorType;
-(FDError *)initWithMultipleErrors:(NSArray *)errors;
+(BOOL)isAppDisabledForError:(FDError *)error;

@end

#endif