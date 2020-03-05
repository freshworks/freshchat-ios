//
//  FCHybridConfig.h
//  FreshchatSDK
//
//  Created by Harish kumar on 03/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCHybridConfig : NSObject

@property (nonatomic, assign) BOOL webAppEnabled;
@property (nonatomic, strong) NSString *webAppUrl;

- (void) updateHybridConfig : (NSDictionary *) info;

@end

