//
//  FCUnsupportedFragmentErrMsgs.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 30/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCUnsupportedFragmentErrorMsgs : NSObject

@property (nonatomic, assign) BOOL displayErrorCodes;
@property (nonatomic, strong) NSString *errorCodePlaceholder;
@property (nonatomic, strong) NSDictionary *globalErrorMessage;
@property (nonatomic, strong) NSArray *errorMessageByTypes;

- (void) updateUnsupportedFragmentMsgInfo : (NSDictionary *) info;

@end

