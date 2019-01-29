//
//  FCUnsupportedFragmentErrMsgs.m
//  FreshchatSDK
//
//  Created by Harish Kumar on 30/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "FCUnsupportedFragmentErrorMsgs.h"
#import "FCUserDefaults.h"

@implementation FCUnsupportedFragmentErrorMsgs

-(instancetype)init{
    self = [super init];
    if (self) {
        self.displayErrorCodes = [self canDisplayErrorCodes];
        self.errorCodePlaceholder = [self getErrorCodePlaceholder];
        self.globalErrorMessage = [self getGlobalErrorMessage];
        self.errorMessageByTypes = [self getErrorMessageByTypes];
    }
    return self;
}

- (BOOL) canDisplayErrorCodes {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_DISPLAY_ERROR_CODES_ENABLED] != nil) {
        return [FCUserDefaults getBoolForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_DISPLAY_ERROR_CODES_ENABLED];
    }
    return FALSE;
}

- (NSString *) getErrorCodePlaceholder {
    if ([FCUserDefaults getStringForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_ERROR_CODE_PLACEHOLDER] != nil) {
        return [FCUserDefaults getObjectForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_ERROR_CODE_PLACEHOLDER];
    }
    return nil;
}

- (NSDictionary *) getGlobalErrorMessage {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_GLOBAL_ERROR_MSG] != nil) {
        return [FCUserDefaults getObjectForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_GLOBAL_ERROR_MSG];
    }
    return nil;
}

- (NSArray *) getErrorMessageByTypes {
    if ([FCUserDefaults getObjectForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_ERROR_MESSAGE_BY_TYPES] != nil) {
        return [FCUserDefaults getObjectForKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_ERROR_MESSAGE_BY_TYPES];
    }
    return nil;
}

- (void) updateDisplayErrorCode : (BOOL) displayErrCode{
    [FCUserDefaults setBool:displayErrCode forKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_DISPLAY_ERROR_CODES_ENABLED];
    self.displayErrorCodes = displayErrCode;
}

- (void) updateErrorCodePlaceholder : (NSString *) errCodePlaceholder {
    [FCUserDefaults setString:errCodePlaceholder forKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_ERROR_CODE_PLACEHOLDER];
    self.errorCodePlaceholder = errCodePlaceholder;
}

- (void) updateGlobalErrorMessage : (NSDictionary *) globalErrMsg {
    [FCUserDefaults setObject:globalErrMsg forKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_GLOBAL_ERROR_MSG];
    self.globalErrorMessage = globalErrMsg;
}

- (void) updateErrorMessageByTypes : (NSArray *) errMsgByTypes {
    [FCUserDefaults setObject:errMsgByTypes forKey:CONFIG_RC_UNSUPPORTED_FRAGMENT_ERROR_MESSAGE_BY_TYPES];
    self.errorMessageByTypes = errMsgByTypes;
}

- (void) updateUnsupportedFragmentMsgInfo : (NSDictionary *) info {
    [self updateDisplayErrorCode:[info[@"displayErrorCodes"] boolValue]];
    
    [self updateErrorCodePlaceholder:info[@"errorCodePlaceholder"]];
    
    [self updateGlobalErrorMessage:info[@"globalErrorMessage"]];
    
    [self updateErrorMessageByTypes:info[@"errorMessageByTypes"]];
}

@end
