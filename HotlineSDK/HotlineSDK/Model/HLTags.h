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

+(void)createTagWithInfo : (NSDictionary *)tagInfo inContext:(NSManagedObjectContext *)context;

+(NSDictionary *) createDictWithTagName :(NSString *)tagname type :(NSNumber *) type andIdvalue :(NSNumber *)tagId;

+(void)removeTagsForTaggableId:(NSNumber *)tagId andType : (NSNumber*)type inContext:(NSManagedObjectContext *)context;


@end
