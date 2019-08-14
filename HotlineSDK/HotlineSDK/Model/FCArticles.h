//
//  HLArticle.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FCCategories;

@interface FCArticles : NSManagedObject

@property (nonatomic, retain) NSString * articleDescription;
@property (nonatomic, retain) NSNumber * articleID;
@property (nonatomic, retain) NSNumber * categoryID;
@property (nonatomic, retain) NSDate * lastUpdatedTime;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) FCCategories *category;
@property (nonatomic, retain) NSString * articleAlias;
@property (nonatomic, retain) NSString * categoryAlias;

+(FCArticles *)getWithID:(NSNumber *)articleID inContext:(NSManagedObjectContext *)context;
+(FCArticles *)createWithInfo:(NSDictionary *)articleInfo inContext:(NSManagedObjectContext *)context;
-(void)updateWithInfo:(NSDictionary *)articleInfo;

@end
