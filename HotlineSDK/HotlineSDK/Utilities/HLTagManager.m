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
#import "FDUtilities.h"

#define STORAGE_DIR_PATH @"Hotline/Offline"
#define TAGS_FILE_NAME @"tags.plist"

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
        if(completion) {
            completion(matches);
        }
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
            if(completion) {
                completion(matches);
            }
        }];
        
    }];
}

- (void) getCategoriesForTags : (NSArray *)tags
                    inContext : (NSManagedObjectContext *) context
                withCompletion:(void (^)(NSArray<HLCategory *> *))completion {
    [self getTaggableIdsForTags:tags forTypes:@[@(HLTagTypeCategory)] inContext:context withCompletion:^(NSArray<HLTags *> * matchingTags) {
        NSArray* categoryIds = [matchingTags valueForKey:@"taggableID"];
        [context performBlock:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"categoryID IN %@",categoryIds];
            NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
            fetchRequest.sortDescriptors = @[position];
            NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
            if(completion) {
                completion(matches);
            }
        }];
    }];
}

- (void) getChannelsForTags : (NSArray *)tags
                  inContext : (NSManagedObjectContext *) context
              withCompletion:(void (^)(NSArray<HLChannel *> *))completion {
    [self getTaggableIdsForTags:tags forTypes:@[@(HLTagTypeChannel)] inContext:context withCompletion:^(NSArray<HLTags *> * matchingTags) {
        NSArray* channelIds = [matchingTags valueForKey:@"taggableID"];
        [context performBlock:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"channelID IN %@ AND isHidden == NO",channelIds];
            NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
            fetchRequest.sortDescriptors = @[position];
            NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
            if(completion) {
                completion(matches);
            }
        }];
    }];
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
