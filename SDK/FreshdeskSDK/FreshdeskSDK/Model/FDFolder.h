//
//  FDFolder.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 31/10/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FDArticle;

@interface FDFolder : NSManagedObject

@property (nonatomic, retain) NSNumber * categoryID;
@property (nonatomic, retain) NSString * categoryName;
@property (nonatomic, retain) NSString * folderDescription;
@property (nonatomic, retain) NSNumber * folderID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSNumber * categoryPosition;

@end

@interface FDFolder (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(FDArticle *)value;
- (void)removeArticlesObject:(FDArticle *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

+(FDFolder *)folderWithInfo:(NSDictionary *)fetchedInfo inManagedObjectContext:(NSManagedObjectContext *)context;

@end