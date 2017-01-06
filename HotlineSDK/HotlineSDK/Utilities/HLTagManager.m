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
        self.tagMap = [[NSMutableDictionary alloc] init];
        self.queue = dispatch_queue_create("com.freshdesk.hotline.tagmanager", DISPATCH_QUEUE_SERIAL);
        self.storageFile = [self getFileForStorage:TAGS_FILE_NAME];
        //[self removeTagsPlistFile];
        [self load];
    }
    return self;
}

-(void) save {
    dispatch_async(self.queue, ^{
        if(self.hasChanges){
            if (![NSKeyedArchiver archiveRootObject:self.tagMap toFile:self.storageFile]) {
                FDLog(@"%@ unable to tags data file", self);
            }
            else {
                self.hasChanges = NO;
                FDLog(@"Tags: %d files saved", (int)self.tagMap.count);
            }
        }
    });
}

-(void) load{
    dispatch_async(self.queue, ^{
        if([[NSFileManager defaultManager] fileExistsAtPath:self.storageFile]){
            NSData *data = [NSData dataWithContentsOfFile:self.storageFile];
            if(data){
                self.tagMap = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                 FDLog(@"Tags: %d files loaded", (int)self.tagMap.count);
            }
        }
    });
}

-(void)addTag:(NSString *)tag forArticleId: (NSNumber *)articleId{
    tag = [tag lowercaseString];
    dispatch_async(self.queue, ^{
        NSMutableSet *articleSet = [self.tagMap objectForKey:tag];
        if(!articleSet){
            articleSet = [[NSMutableSet alloc]init];
        }
        [articleSet addObject:articleId];
        [self.tagMap setObject:articleSet forKey:tag];
        self.hasChanges = YES;
    });
}

-(void)removeTagsForArticleId:(NSNumber *)articleId{
    dispatch_async(self.queue, ^{
        NSMutableDictionary *updatedMap = [[NSMutableDictionary alloc] init];
        for(NSString *tagName in self.tagMap){
            NSMutableSet *articleSet = [self.tagMap objectForKey:tagName];
            if([articleSet containsObject:articleId]){
                [articleSet removeObject:articleId];
                [updatedMap setObject:articleSet forKey:tagName];
                self.hasChanges = YES;
            }
            else {
                [updatedMap setObject:articleSet forKey:tagName];
            }
        }
        self.tagMap = updatedMap;
    });
}

-(void) getArticlesForTags : (NSArray *)tags inContext :(NSManagedObjectContext *)context withCompletion:(void (^)(NSArray *))completion {
    NSArray *taggedIds;
    NSMutableSet * articlesSet = [NSMutableSet set];
    if(tags.count >0){
        for(NSString *tag in tags){
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_TAGS_ENTITY];
            fetchRequest.predicate   = [NSPredicate predicateWithFormat:@"tagName == %@ AND (taggableType ==%d OR taggableType ==%d)", tag, HLTagTypeArticle, HLTagTypeCategory];
            NSArray *matches         = [context executeFetchRequest:fetchRequest error:nil];
            for (HLTags *taggedObj in matches){
                if([taggedObj.taggableType intValue] == HLTagTypeArticle){
                
                    [articlesSet addObject:taggedObj.taggableID];
                }
                else if ([taggedObj.taggableType intValue] == HLTagTypeCategory){
                    HLCategory *category = [HLCategory getWithID:taggedObj.taggableID inContext:context];
                    for(HLArticle *articleInfo in category.articles){
                        [articlesSet addObject:articleInfo.articleID];
                    }
                }
            }
            taggedIds = [articlesSet allObjects];
        }
    }
    dispatch_async(dispatch_get_main_queue(),^{
        completion(taggedIds);
    });
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

-(void)clear{
    dispatch_async(self.queue, ^{
        self.tagMap = [[NSMutableDictionary alloc] init];
        self.hasChanges = YES;
        [self save];
        FDLog(@"Fire in the hole");
    });
}

@end


