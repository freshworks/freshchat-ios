//
//  HotlineAppState.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 29/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCChannels.h"

@interface HotlineAppState : NSObject

@property (nonatomic, strong) UIViewController *currentVisibleController;
@property (nonatomic, strong) FCChannels *currentVisibleChannel;

+(instancetype)sharedInstance;

@end
