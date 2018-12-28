//
//  FCMessageMaskConfig.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 04/12/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCMessageMaskConfig : NSObject

@property (nonatomic, strong) NSArray *messageMasks;

- (void) updateMessageMaskingInfo : (NSDictionary *) info;

@end

