//
//  HLTagManager.m
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCTagManager.h"
#import "FCMacros.h"
#import "FCTags.h"
#import "FCUtilities.h"

#define STORAGE_DIR_PATH @"Hotline/Offline"
#define TAGS_FILE_NAME @"tags.plist"

#define ARTICLE_AND_CATEGORY_TAGS @[@(HLTagTypeArticle),@(HLTagTypeCategory)]

@interface FCTagManager ()

@property (nonatomic,strong)NSMutableDictionary *tagMap;
@property (nonatomic)dispatch_queue_t queue;
@property (nonatomic,strong)NSString *storageFile;
@property (nonatomic)BOOL hasChanges;

@end

@implementation FCTagManager

+(instancetype)sharedInstance{
    static FCTagManager *sharedInstance = nil;
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
                withCompletion:(void (^)(NSArray<FCTags *> *,NSError*))completion {
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_TAGS_ENTITY];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"tagName IN %@ AND taggableType IN %@",
                                            tags, tagTypes];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(completion) {
            completion(matches,error);
        }
    }];
}

-(void)getArticlesForTags:(NSArray *)tags
              inContext:(NSManagedObjectContext *) context
          withCompletion :(void (^)(NSArray<FCArticles *> *))completion{
    [self getTaggableIdsForTags:tags forTypes:ARTICLE_AND_CATEGORY_TAGS inContext:context withCompletion:^(NSArray<FCTags *> *matchingTags, NSError* error){
        NSMutableArray *articleIds = [NSMutableArray array];
        NSMutableArray *categoryIds = [NSMutableArray array];
        for(FCTags *tag in matchingTags){
            if([tag.taggableType integerValue] == HLTagTypeArticle){
                [articleIds addObject:tag.taggableID];
            }
            else if([tag.taggableType integerValue] == HLTagTypeCategory) {
                [categoryIds addObject:tag.taggableID];
            }
        }
        [context performBlock:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_ARTICLES_ENTITY];
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
                withCompletion:(void (^)(NSArray<FCCategories *> *))completion {
    [self getTaggableIdsForTags:tags forTypes:@[@(HLTagTypeCategory)] inContext:context withCompletion:^(NSArray<FCTags *> * matchingTags, NSError* error) {
        NSArray* categoryIds = [matchingTags valueForKey:@"taggableID"];
        [context performBlock:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CATEGORIES_ENTITY];
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
              withCompletion:(void (^)(NSArray<FCChannels *> *, NSError *))completion {
    [self getTaggableIdsForTags:tags forTypes:@[@(HLTagTypeChannel)] inContext:context withCompletion:^(NSArray<FCTags *> * matchingTags, NSError* error) {
        NSArray* channelIds = [matchingTags valueForKey:@"taggableID"];
        [self getChannel:tags channelIds:channelIds inContext:context withCompletion:completion];
    }];
}



- (void) getChannel: (NSArray *)tags
            channelIds : (NSArray *) channelIds
            inContext : (NSManagedObjectContext *) context
            withCompletion:(void (^)(NSArray<FCChannels *> *, NSError *))completion {
    [context performBlock:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
        if([tags count] == 0 && [channelIds count] != 0) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"channelID IN %@",channelIds];
        }
        else if ([tags count] == 0) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"channelID IN %@ AND isHidden == NO AND isRestricted == NO",channelIds];
        } else {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"channelID IN %@",channelIds];
        }
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        fetchRequest.sortDescriptors = @[position];
        NSError *error;
        NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
        if(completion) {
            completion(matches, error);
        }
    }];
}

- (NSString*) getFileForStorage:(NSString *) fileName {
    NSString *dirPath = [FCUtilities returnLibraryPathForDir:TAGS_FILE_NAME];
    return [dirPath stringByAppendingPathComponent:fileName];
}

- (void) removeTagsPlistFile{
    dispatch_async(self.queue, ^{
        if([[NSFileManager defaultManager] fileExistsAtPath:self.storageFile]){
            [[NSFileManager defaultManager] removeItemAtPath:self.storageFile error:NULL];
        }
    });
}

-(void)deleteTagWithTaggableType: (NSArray *)tagTypes
                handler:(void(^)(NSError *error))handler
                inContext:(NSManagedObjectContext *) context{
    [context performBlock:^{
    @try {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_TAGS_ENTITY];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"taggableType IN %@",
                                  tagTypes];
        NSArray *matches = [context executeFetchRequest:fetchRequest error:nil];
        for (int i=0; i<matches.count; i++) {
            NSManagedObject *object = matches[i];
            [context deleteObject:object];
        }
        [context save:nil];
        FDLog(@"Deleting tags of type %@ entries from table : %@ ", tagTypes, FRESHCHAT_TAGS_ENTITY);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) handler(nil);
        });
    }
     @catch(NSException *exception) {
         FDLog(@"Error in deleting tags of type %@ entries from table : %@ ", tagTypes, FRESHCHAT_TAGS_ENTITY);
     }
    }];
}
     


@end
