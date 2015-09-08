//
//  FDError.m
//  FreshdeskSDK
//
//  Created by AravinthChandran on 19/11/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDError.h"

@interface FDError ()

@property (strong, nonatomic) NSDictionary *errorInfo;

@end

@implementation FDError

#pragma mark - Lazy Instantiation

-(NSDictionary *)errorInfo{
    if (!_errorInfo) {
        _errorInfo = @{
           @(MOBIHELP_ERROR_APP_DELETED) : @{
               NSLocalizedDescriptionKey : @"App Deleted !",
               NSLocalizedFailureReasonErrorKey : @"App is deleted from the portal",
               NSLocalizedRecoverySuggestionErrorKey :
                   @"Your Mobihelp app seems to be deleted. Please check your App Credentials."
            },
           @(MOBIHELP_ERROR_ACCOUNT_SUSPENDED) : @ {
               NSLocalizedDescriptionKey : @"Account suspended !",
               NSLocalizedFailureReasonErrorKey : @"Your account is in suspened state",
               NSLocalizedRecoverySuggestionErrorKey :
               @"Freshdesk account seems to be suspended. Please contact support."
           },
           @(MOBIHELP_ERROR_NETWORK_CONNECTIVITY) : @{
               NSLocalizedDescriptionKey : @"No Network Connectivity !",
               NSLocalizedFailureReasonErrorKey : @"Unable to connect to internet",
               NSLocalizedRecoverySuggestionErrorKey : @"Connectivity Issue. Please try again later"
           },
           @(MOBIHELP_ERROR_INVALID_APP_CREDENTIALS) : @{
               NSLocalizedDescriptionKey : @"Invalid Mobihelp Credentials !",
               NSLocalizedFailureReasonErrorKey : @"Invalid app key / app secret",
               NSLocalizedRecoverySuggestionErrorKey : @"Please supply a valid app key and app secret"
           },
           @(MOBIHELP_MULTIPLE_ERRORS) : @{
               NSLocalizedDescriptionKey : @"Operation was unsuccessful !",
               NSLocalizedFailureReasonErrorKey : @"Multiple errors occured for operation.",
               NSLocalizedRecoverySuggestionErrorKey : @"Something is not right. Unexpected Error encountered."
           },
           @(MOBIHELP_ERROR_INVALID_RESPONSE) : @{
               NSLocalizedDescriptionKey : @"Operation was unsuccessful !",
               NSLocalizedFailureReasonErrorKey : @"Invalid response received"
           },
           @(MOBIHELP_NO_TICKET_EXISTS) : @{
               NSLocalizedFailureReasonErrorKey : @"No Ticket Exists",
               NSLocalizedDescriptionKey : @"No Tickets created yet!"
           },
           @(MOBIHELP_DEFAULT_ERROR) : @{
               NSLocalizedFailureReasonErrorKey : @"Default Error",
               NSLocalizedFailureReasonErrorKey : @"Unhandled Error",
               NSLocalizedRecoverySuggestionErrorKey : @"Something is not right. Unexpected Error encountered."
            }
        };

    }
    return _errorInfo;
}

#pragma mark - Designated Initializer

-(instancetype)initWithCode:(NSInteger)code userInfo:(NSDictionary *)dict{
    self = [self initWithDomain:MOBIHELP_ERROR_DOMAIN code:code userInfo:dict];
    return self;
}

-(FDError *)initWithError:(MOBIHELP_ERROR_TYPE)errorType{
    FDError *error = nil;
    NSDictionary *userInfo = self.errorInfo[@(errorType)];
    if (userInfo) {
        error = [self initWithCode:errorType userInfo:userInfo];
    }else{
        error = [self initWithCode:MOBIHELP_DEFAULT_ERROR userInfo:self.errorInfo[@(MOBIHELP_DEFAULT_ERROR)]];
    }
    return error;
}

-(FDError *)initWithMultipleErrors:(NSArray *)errors{
    FDError *error;
    NSMutableDictionary *underlyingErrors = [[NSMutableDictionary alloc]init];
    for (int i=0; i<[errors count]; i++) {
        NSString *errorKey = [NSString stringWithFormat:@"\n Error: %d \n",i+1];
        underlyingErrors[errorKey] = [errors[i] description];
    }
    error = [self initWithCode:MOBIHELP_MULTIPLE_ERRORS userInfo:underlyingErrors];
    return error;
}

+(BOOL)isAppDisabledForError:(FDError *)error{
    if (error.code == MOBIHELP_ERROR_APP_DELETED || error.code == MOBIHELP_ERROR_ACCOUNT_SUSPENDED || error.code == MOBIHELP_ERROR_INVALID_APP_CREDENTIALS) {
        return YES;
    }else{
        return NO;
    }
}

@end