//
//  HLTags.m
//  HotlineSDK
//
//  Created by harish on 06/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLTags.h"
#import "KonotorDataManager.h"

@implementation HLTags

@dynamic taggableID;
@dynamic taggableType;
@dynamic tagName;

+(HLTags *)createWithInfo:(NSDictionary *)TagsInfo inContext:(NSManagedObjectContext *)context{
    HLTags *tag = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_TAGS_ENTITY inManagedObjectContext:context];
    return [self updateTags:tag withInfo:TagsInfo];
}

-(void)updateWithInfo:(NSDictionary *)tagInfo{
    [HLTags updateTags:self withInfo:tagInfo];
}

+(HLTags *)updateTags:(HLTags *)tag withInfo:(NSDictionary *)categoryInfo{
    tag.taggableID = categoryInfo[@"categoryId"];
    tag.taggableType = categoryInfo[@"title"];
    tag.tagName = categoryInfo[@"icon"];
    return tag;
}

@end
