//
//  HLTagManager.m
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLTagManager.h"
#import "HLMacros.h"
#import "HLTags.h"
#import "HLCategory.h"
#import "HLArticle.h"
#import "FDUtilities.h"

#define STORAGE_DIR_PATH @"Hotline/Offline"
#define TAGS_FILE_NAME @"tags.plist" // Hotline/Events/events.plist

#define ARTICLE_AND_CATEGORY_TAGS @[@(HLTagTypeArticle),@(HLTagTypeCategory)]

@interface HLTagManager ()

@property (nonatomic,strong)NSMutableDictionary *tagMap;
@property (nonatomic)dispatch_queue_t queue;
@property (nonatomic,strong)NSString *storageFile;
@property (nonatomic)BOOL hasChanges;

@end

@implementation HLTagManager

+(instancetype)sharedInstance{
    static HLTagManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
}

-(instancetype) init {
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("com.freshdesk.hotline.tagmanager", DISPATCH_QUEUE_SERIAL);
        self.storageFile = [self getFileForStorage:TAGS_FILE_NAME];
        //[self removeTagsPlistFile];
    }
    return self;
}

-(void) getTaggableIdsForTags : (NSArray *)tags
                     forTypes : (NSArray *) tagTypes
                inContext   : (NSManagedObjectContext *) context
                withCompletion:(void (^)(NSArray<HLTags *> *))completion {
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"tagName IN %@ AND taggableType IN %@",
                                            tags, tagTypes];
        NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
        completion(matches);
    }];
}

-(void)getArticlesForTags:(NSArray *)tags
              inContext:(NSManagedObjectContext *) context
          withCompletion :(void (^)(NSArray<HLArticle *> *))completion{
    [self getTaggableIdsForTags:tags forTypes:ARTICLE_AND_CATEGORY_TAGS inContext:context withCompletion:^(NSArray<HLTags *> *matchingTags){
        NSMutableArray *articleIds = [NSMutableArray array];
        NSMutableArray *categoryIds = [NSMutableArray array];
        for(HLTags *tag in matchingTags){
            if([tag.taggableType integerValue] == HLTagTypeArticle){
                [articleIds addObject:tag.taggableID];
            }
            else if([tag.taggableType integerValue] == HLTagTypeCategory) {
                [categoryIds addObject:tag.taggableID];
            }
        }
        [context performBlock:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"articleID IN %@ OR categoryID IN %@",
                                      articleIds, categoryIds];
            [fetchRequest setReturnsDistinctResults:YES];
            NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
            completion(matches);
        }];
        
    }];
}


- (void) getCategoriesForTags : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion {
    NSMutableSet * categoriesSet = [NSMutableSet set];
    if(tags.count >0){
        for(NSString *tag in tags){
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
            fetchRequest.predicate   = [NSPredicate predicateWithFormat:@"tagName == %@ AND taggableType ==%d",tag, HLTagTypeCategory];
            NSArray *matches         = [context executeFetchRequest:fetchRequest error:nil];
            for (HLTags *taggedObj in matches){
                [categoriesSet addObject:taggedObj.taggableID];
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(),^{
        completion([[categoriesSet allObjects] mutableCopy]);
    });
}

- (void) getChannelsWithOptions : (NSArray *)tags inContext : (NSManagedObjectContext *) context withCompletion:(void (^)(NSArray *))completion {
    NSMutableSet * channelsSet = [NSMutableSet set];
    if(tags.count >0){
        for(NSString *tag in tags){
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
            fetchRequest.predicate   = [NSPredicate predicateWithFormat:@"tagName == %@ AND taggableType ==%d",tag, HLTagTypeChannel];
            NSArray *matches         = [context executeFetchRequest:fetchRequest error:nil];
            for (HLTags *taggedObj in matches){
                [channelsSet addObject:taggedObj.taggableID];
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(),^{
        completion([[channelsSet allObjects] mutableCopy]);
    });
}

- (void)articlesForTags:(NSArray *) tags withCompletion:(void (^)(NSSet *))completion{
    dispatch_async(self.queue, ^{
        NSMutableSet *articleSet = [[NSMutableSet alloc]init];
        for(NSString *tag in tags){
            NSString *tagValue = [tag lowercaseString];
            NSSet *matches = [self.tagMap objectForKey:tagValue];
            [articleSet addObjectsFromArray:[matches allObjects]];
        }
        dispatch_async(dispatch_get_main_queue(),^{
            completion(articleSet);
        });
    });
}

- (NSString*) getFileForStorage:(NSString *) fileName {
    NSString *dirPath = [FDUtilities returnLibraryPathForDir:TAGS_FILE_NAME];
    return [dirPath stringByAppendingPathComponent:fileName];
}

- (void) removeTagsPlistFile{
    dispatch_async(self.queue, ^{
        if([[NSFileManager defaultManager] fileExistsAtPath:self.storageFile]){
            [[NSFileManager defaultManager] removeItemAtPath:self.storageFile error:NULL];
        }
    });
}

@end


