//
//  FDIndexManager.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 20/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCIndexManager : NSObject

+(void)updateIndex;
+(void)setIndexingCompleted:(BOOL)state;

@end
