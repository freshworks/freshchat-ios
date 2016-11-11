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
    return [self addTags:tag withInfo:TagsInfo];
}

+(FDTags *)getTaggedWithId : (NSNumber *) taggableID andType: (NSNumber *)taggableType inContext:(NSManagedObjectContext *)context{
    
    FDTags *taggedObj;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"taggableID == %d AND taggableType == %d",taggableID, taggableType];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        taggedObj = matches.firstObject;
    }
    return taggedObj;
}

-(void)updateWithInfo:(NSDictionary *)tagInfo{
    
    [FDTags addTags:self withInfo:tagInfo];
}

+(FDTags *)addTags:(FDTags *)tag withInfo:(NSDictionary *)TagsInfo{
    
    tag.taggableID = TagsInfo[@"taggableID"];
    tag.taggableType = TagsInfo[@"taggableType"];
    tag.tagName = TagsInfo[@"tagName"];
    return tag;
}

@end
