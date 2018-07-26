//
//  HLCategory.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FCArticles;

@interface FCCategories : NSManagedObject

@property (nonatomic, retain) NSString * categoryDescription;
@property (nonatomic, retain) NSNumber * categoryID;
@property (nonatomic, retain) NSData * icon;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSString *iconURL;
@property (nonatomic, retain) NSDate * lastUpdatedTime;

@end

@interface FCCategories (CoreDataGeneratedAccessors)

+ (FCCategories *)getWithID:(NSNumber *)categoryID inContext:(NSManagedObjectContext *)context;
+ (FCCategories *)createWithInfo:(NSDictionary *)categoryInfo inContext:(NSManagedObjectContext *)context;

- (void)addArticlesObject:(FCArticles *)value;
- (void)removeArticlesObject:(FCArticles *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;
- (void)updateWithInfo:(NSDictionary *)categoryInfo;

@end
