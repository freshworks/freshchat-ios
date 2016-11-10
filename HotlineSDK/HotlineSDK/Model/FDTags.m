//
//  FDTags.m
//  HotlineSDK
//
//  Created by harish on 06/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDTags.h"
#import "KonotorDataManager.h"

@implementation FDTags

@dynamic taggableID;
@dynamic taggableType;
@dynamic tagName;

+(FDTags *)createWithInfo:(NSDictionary *)TagsInfo inContext:(NSManagedObjectContext *)context{
    FDTags *tag = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_TAGS_ENTITY inManagedObjectContext:context];
    return [self updateTags:tag withInfo:TagsInfo];
}

-(void)updateWithInfo:(NSDictionary *)tagInfo{
    [FDTags updateTags:self withInfo:tagInfo];
}

+(FDTags *)updateTags:(FDTags *)tag withInfo:(NSDictionary *)categoryInfo{
    tag.taggableID = categoryInfo[@"categoryId"];
    tag.taggableType = categoryInfo[@"title"];
    tag.tagName = categoryInfo[@"icon"];
    return tag;
}

@end
