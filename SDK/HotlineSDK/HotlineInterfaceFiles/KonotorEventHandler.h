//
//  KonotorEventHandler.h
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 20/08/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Konotor.h"
#import "KonotorUtility.h"

@interface KonotorEventHandler : NSObject <KonotorDelegate>
@property (nonatomic, strong) UILabel* badgeLabel;
+ (KonotorEventHandler*) sharedInstance;
@end
