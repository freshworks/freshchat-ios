//
//  HLArticle.h
//  
//
//  Created by Aravinth Chandran on 21/09/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HLCategory;

@interface HLArticle : NSManagedObject

@property (nonatomic, retain) NSString * articleDescription;
@property (nonatomic, retain) NSNumber * articleID;
@property (nonatomic, retain) NSNumber * categoryID;
@property (nonatomic, retain) NSDate * lastUpdatedTime;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) HLCategory *category;

@end
