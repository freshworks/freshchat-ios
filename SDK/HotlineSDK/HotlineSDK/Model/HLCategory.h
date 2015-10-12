//
//  HLCategory.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HLArticle;

@interface HLCategory : NSManagedObject

@property (nonatomic, retain) NSString * categoryDescription;
@property (nonatomic, retain) NSNumber * categoryID;
@property (nonatomic, retain) NSData * icon;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSString *iconURL;
@property (nonatomic, retain) NSDate * lastUpdatedTime;

@end

@interface HLCategory (CoreDataGeneratedAccessors)

+ (HLCategory *)getWithID:(NSNumber *)categoryID inContext:(NSManagedObjectContext *)context;
+ (HLCategory *)createWithInfo:(NSDictionary *)categoryInfo inContext:(NSManagedObjectContext *)context;

- (void)addArticlesObject:(HLArticle *)value;
- (void)removeArticlesObject:(HLArticle *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;
- (void)updateWithInfo:(NSDictionary *)categoryInfo;

@end