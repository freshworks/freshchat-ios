//
//  HLArticleTagManager.m
//  HotlineSDK
//
//  Created by Hrishikesh on 23/06/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLArticleTagManager.h"
#import "HLMacros.h"

#define STORAGE_DIR_PATH @"Hotline/Offline"
#define TAGS_FILE_NAME @"tags.plist" // Hotline/Events/events.plist

@interface HLArticleTagManager ()

@property NSMutableDictionary *tagMap;
@property NSMutableDictionary *articleMap;
@property dispatch_queue_t queue;
@property NSString *storageFile;
@property BOOL hasChanges;

@end

@implementation HLArticleTagManager

+(instancetype)sharedInstance{
    static HLArticleTagManager *sharedInstance = nil;
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
        self.articleMap = [[NSMutableDictionary alloc] init];
        self.queue = dispatch_queue_create("com.freshdesk.hotline.tagmanager", DISPATCH_QUEUE_SERIAL);
        self.storageFile = [self getFileForStorage:TAGS_FILE_NAME];
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
                FDLog(@"Saved file with contents %@", self.tagMap);
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
            }
        }
    });
}

-(void)addTag:(NSString *)tag forArticleId: (NSNumber *)articleId{
    dispatch_async(self.queue, ^{
        NSMutableSet *articleSet = [self.tagMap objectForKey:tag];
        if(!articleSet){
            articleSet = [[NSMutableSet alloc]init];
        }
        [articleSet addObject:articleId];
        [self.tagMap setObject:articleSet forKey:tag];
        self.hasChanges = YES;
        [self save];
    });
}

-(void)removeTagsForArticleId:(NSNumber *)articleId{
    dispatch_async(self.queue, ^{
        NSMutableDictionary *updatedMap = [[NSMutableDictionary alloc] init];
        for(NSString *tagName in self.tagMap){
            NSMutableSet *articleSet = [self.tagMap objectForKey:tagName];
            if([articleSet containsObject:articleId]){
                [articleSet removeObject:articleId];
            }
            [updatedMap setObject:articleSet forKey:tagName];
        }
        self.tagMap = updatedMap;
        self.hasChanges = YES;
        [self save];
    });
}

-(void)articlesForTag:(NSString *) tag withCompletion:(void (^)(NSSet *))completion{
    dispatch_async(self.queue, ^{
        NSMutableSet *articleSet = [self.tagMap objectForKey:tag];
        if(!articleSet){
            articleSet = [[NSMutableSet alloc]init];
        }
        completion(articleSet);
    });
}

- (NSString*) getFileForStorage:(NSString *) fileName {
    FDLog(@"creating tags library");
    //check for path, if available return else create path
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:STORAGE_DIR_PATH];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSError *error = nil;
        NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                  withIntermediateDirectories:YES
                                                   attributes:attr
                                                        error:&error];
        if (error){
            FDLog(@"Error creating directory path: %@", [error localizedDescription]);
        }
    }
    return [filePath stringByAppendingPathComponent:fileName];
}

@end


