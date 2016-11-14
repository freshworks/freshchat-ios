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


+(void)createTagWithInfo : (NSDictionary *)tagInfo inContext:(NSManagedObjectContext *)context{
    
    FDTags *taggedObj;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"taggableID == %d AND taggableType == %d",tagInfo[@"taggableID"], tagInfo[@"taggableType"]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 1) {
        taggedObj = matches.firstObject;
        taggedObj.tagName = tagInfo[@"tagName"];
    }
    else{
        FDTags *tag = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_TAGS_ENTITY inManagedObjectContext:context];
        [self addTag:tag withInfo:tagInfo];
    }
}

+(FDTags *)addTag:(FDTags *)tag withInfo:(NSDictionary *)tagInfo{
    
    tag.taggableID = tagInfo[@"taggableID"];
    tag.taggableType = tagInfo[@"taggableType"];
    tag.tagName = tagInfo[@"tagName"];
    return tag;
}

@end
