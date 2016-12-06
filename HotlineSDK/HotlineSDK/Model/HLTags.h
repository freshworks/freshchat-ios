//
//  HLTags.h
//  HotlineSDK
//
//  Created by harish on 06/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

enum HLTagType {
    HLTagTypeArticle  = 1,
    HLTagTypeCategory = 2,
    HLTagTypeChannel  = 3
};


@interface HLTags : NSManagedObject

@property (nonatomic, retain) NSNumber * taggableID;
@property (nonatomic, retain) NSNumber * taggableType;
@property (nonatomic, retain) NSString * tagName;

+(HLTags *)createWithInfo:(NSDictionary *)TagsInfo inContext:(NSManagedObjectContext *)context;
-(void)updateWithInfo:(NSDictionary *)tagInfo;

@end
