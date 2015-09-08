//
//  FDQueue.m
//  FreshdeskSDK
//
//  Created by kirthikas on 07/01/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDQueue.h"
#import "FDConstants.h"

@implementation FDQueue

-(instancetype)initWithSize:(NSInteger) size{
    self= [super init];
    if(self){
        self.queueSize = size;
    }
    return self;
}

-(void)enqueue:(id)anObject{
    [super enqueue:anObject];
    while ( [self.items count] > self.queueSize){
        [self dequeue];
    }
}

-(void)removeWithPredicate:(NSPredicate *)predicate{
    self.items = [[self.items filteredArrayUsingPredicate:predicate]mutableCopy];
}


@end
