//
//  FDTag.h
//  Mobihelp
//
//  Created by kirthikas on 26/06/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FDTag : NSManagedObject

@property (nonatomic, retain) NSString * itemType;
@property (nonatomic, retain) NSNumber * itemID;
@property (nonatomic, retain) NSString * tagName;

+(FDTag *)tagForItem:(NSString *)itemType WithInfo:(NSDictionary *)tagInfo anditemID:(NSNumber *)itemID inManagedObjectContext:(NSManagedObjectContext *)context;

@end
