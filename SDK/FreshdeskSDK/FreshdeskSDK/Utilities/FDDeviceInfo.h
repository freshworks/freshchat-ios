//
//  FDDeviceInfo.h
//  FreshdeskSDK
//
//  Created by Aravinth on 12/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FDDeviceInfo : NSObject

//App Info
+(NSString *)appName;
+(NSString *)appVersion;
+(NSString *)appIdentifier;
+(NSString *)mobihelpSDKVersion;

//Device Info
+(NSString *)osVersion;
+(NSString *)osName;
+(NSString *)deviceMake;
+(NSString*)deviceModelName;

//Info Collection
+(NSDictionary *)collectDeviceAndAppInfo;

@end
