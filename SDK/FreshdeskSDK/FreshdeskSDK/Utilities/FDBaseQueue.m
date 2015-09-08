//
//  FDBaseQueue.m
//  FreshdeskSDK
//
//  Created by Aravinth on 09/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//


#import "FDBaseQueue.h"
#import "FDConstants.h"


@interface FDBaseQueue ()

@end

@implementation FDBaseQueue

-(instancetype)init{
    self = [super init];
    if (self) {
        self.items = [[NSMutableArray alloc]init];
    }
    return self;
}


#pragma mark - NSCoding Methods

-(id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.items = [aDecoder decodeObjectForKey:@"items"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.items forKey:@"items"];
}

#pragma mark - Queue

- (void)enqueue:(id)anObject {
    [self.items addObject:anObject];
}

-(id)dequeue{
    if ([self.items count] == 0) return nil;
    id firstObject = [self.items firstObject];
    if (firstObject) [self.items removeObjectAtIndex:0];
    return firstObject;
}

-(id)peek{
    return [self.items firstObject];
}

-(NSInteger)count{
    return [self.items count];
}

-(void)clear{
    [self.items removeAllObjects];
}

#pragma mark - Misc

-(void)loadWithArray:(NSMutableArray *)array{
    [self.items addObjectsFromArray:array];
}

-(NSMutableArray *)contentsAsArray{
    return self.items;
}

#pragma mark - Indexed Subscript

-(id)objectAtIndexedSubscript:(NSUInteger)idx{
    return self.items[idx];
}

-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx{
    self.items[idx]=obj;
}

#pragma mark - Description

-(NSString *)description{
    return [self.items debugDescription];
}

@end