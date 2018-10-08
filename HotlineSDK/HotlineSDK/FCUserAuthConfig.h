//
//  FCUserAuthConfig.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 08/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCUserAuthConfig : NSObject

@property (nonatomic, assign) BOOL isjwtAuthEnabled;
@property (nonatomic, assign) BOOL isStrictModeEnabled;

- (void) updateUserAuthConfig : (NSDictionary *) info;

@end
