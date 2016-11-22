//
//  FDTags.h
//  HotlineSDK
//
//  Created by harish on 06/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

enum FDTagType {
    FDTagTypeArticle  = 1,
    FDTagTypeCategory = 2,
    FDTagTypeChannel  = 3
};


@interface FDTags : NSManagedObject

@property (nonatomic, retain) NSNumber * taggableID;
@property (nonatomic, retain) NSNumber * taggableType;
@property (nonatomic, retain) NSString * tagName;

+(void)createTagWithInfo : (NSDictionary *)tagInfo inContext:(NSManagedObjectContext *)context;

+(NSDictionary *) createDictWithTagName :(NSString *)tagname type :(NSNumber *) type andIdvalue :(NSNumber *)tagId;

+(void)removeTagsForTaggableId:(NSNumber *)tagId andType : (NSNumber*)type inContext:(NSManagedObjectContext *)context;

//-(void)updateWithInfo:(NSDictionary *)tagInfo;

@end
