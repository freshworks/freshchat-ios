//
//  FCJWTAuth.h
//  FreshchatSDK
//
//  Created by Harish Kumar on 05/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JWTState){
    Active,
    Waiting,
    InProgress,
    ReAuth,
    Expired
};

@interface FCJWTAuth : NSObject

@property (nonatomic, assign) JWTState state;

@end

NS_ASSUME_NONNULL_END
