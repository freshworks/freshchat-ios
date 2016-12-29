//
//  FDControllerUtils.h
//  HotlineSDK
//
//  Created by user on 03/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLConversationUtil.h"

//TODO: Move all controller config logic from hotline.m to here

@interface FDControllerUtils : NSObject

+(UIViewController *)getConvController:(BOOL)isEmbeded;

@end
