//
//  HLTags.m
//  HotlineSDK
//
//  Created by harish on 06/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLTags.h"
#import "KonotorDataManager.h"
#import "HLMacros.h"

@implementation HLTags

@dynamic taggableID;
@dynamic taggableType;
@dynamic tagName;

+(void)createTagWithInfo : (NSDictionary *)tagInfo inContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"taggableID == %@ AND taggableType == %@ AND tagName == %@",tagInfo[@"taggableID"], tagInfo[@"taggableType"], tagInfo[@"tagName"]];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if (matches.count == 0) {
        HLTags *tag = [NSEntityDescription insertNewObjectForEntityForName:HOTLINE_TAGS_ENTITY inManagedObjectContext:context];
        FDLog(@"New tag created : %@",tagInfo);
        [self addTag:tag withInfo:tagInfo];
    }
}



+(void)removeTagsForTaggableId:(NSNumber *)tagId andType : (NSNumber*)type inContext:(NSManagedObjectContext *)context{
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"taggableID == %@ AND taggableType == %@", tagId, type];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if(matches.count > 0){
        for (HLTags *object in matches) {
            [context deleteObject:object];
        }
    }
    NSError * error = nil;
    if (![context save:&error])
    {
        ALog(@"Error in tag deletion! %@", error);
    }
}

+(NSDictionary *) createDictWithTagName :(NSString *)tagname type :(NSNumber *) type andIdvalue :(NSNumber *)tagId{
    
    NSMutableDictionary *tagsDict = [[NSMutableDictionary alloc] init];
    [tagsDict setValue:tagId forKey:@"taggableID"];
    [tagsDict setValue:type forKey:@"taggableType"];
    [tagsDict setValue:[tagname lowercaseString] forKey:@"tagName"];
    return tagsDict;
}

+(HLTags *)addTag:(HLTags *)tag withInfo:(NSDictionary *)tagInfo{
    tag.taggableID = tagInfo[@"taggableID"];
    tag.taggableType = tagInfo[@"taggableType"];
    tag.tagName = tagInfo[@"tagName"];
    return tag;
}

@end
