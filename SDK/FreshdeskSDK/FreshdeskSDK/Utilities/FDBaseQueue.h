//
//  FDBaseQueue.h
//  FreshdeskSDK
//
//  Created by Aravinth on 09/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDBaseQueue : NSObject <NSCoding>

@property (strong, nonatomic) NSMutableArray *items;

-(id)dequeue;
-(void)enqueue:(id)anObject;
-(id)peek;
-(NSInteger)count;
-(void)clear;

/*  Miscellaneous */
-(void)loadWithArray:(NSMutableArray *)array;
-(NSMutableArray *)contentsAsArray;

/*
 # Indexed Subscripting - Access objects using keyed subscript
 usage,id obj = obj[i];
 */
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;

@end
