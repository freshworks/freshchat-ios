//
//  FDQueue.h
//  FreshdeskSDK
//
//  Created by kirthikas on 07/01/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDBaseQueue.h"

@interface FDQueue : FDBaseQueue

@property NSInteger queueSize;

-(instancetype)initWithSize:(NSInteger) size;
-(void)enqueue:(id)anObject;
-(void)removeWithPredicate:(NSPredicate *)predicate;

@end
