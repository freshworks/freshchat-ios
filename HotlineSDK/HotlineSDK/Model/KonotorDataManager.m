//
//  KonotorDataManager.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//
#import "KonotorDataManager.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "HLConstants.h"
#import "FDMemLogger.h"

#define logInfo(dict) [self.logger addErrorInfo:dict withMethodName:NSStringFromSelector(_cmd)];
#define logMsg(str) [self.logger addMessage:str withMethodName:NSStringFromSelector(_cmd)];

@interface KonotorDataManager ()

@property (nonatomic, strong) NSManagedObjectModel *objectModel;
@property FDMemLogger *logger;

@end

@implementation KonotorDataManager

NSString * const kDataManagerBundleName = @"KonotorModels";
NSString * const kDataManagerModelName = @"KonotorModel";
NSString * const kDataManagerSQLiteName = @"Konotor.sqlite";

+ (KonotorDataManager*)sharedInstance {
    static dispatch_once_t pred;
    static KonotorDataManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    if(!sharedInstance.persistentStoreCoordinator){
        @synchronized(sharedInstance) {
            if(!sharedInstance.persistentStoreCoordinator){
                @try {
                    [sharedInstance preparePersistantStoreCoordinator];
                    [sharedInstance setMainQueueContext];
                } @catch (NSException *exception) {
                    [[FDMemLogger new]addMessage:exception.description];
                }
            }
        }
    }
	return sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.logger = [[FDMemLogger alloc] init];
    }
    return  self;
}

- (NSString*)sharedLibraryPath {
    NSString *sharedLibraryPath = nil;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    sharedLibraryPath = [libraryPath stringByAppendingPathComponent:@"Database"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![manager fileExistsAtPath:sharedLibraryPath isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        NSDictionary *attr = @{ NSFileProtectionKey: NSFileProtectionComplete};
        [manager createDirectoryAtPath:sharedLibraryPath withIntermediateDirectories:YES attributes:attr error:&error];
        if (error){
            NSDictionary *errorInfo = @{@"Folder Creation Failed" :@{
                                                @"Reason:"   : error.description,
                                                @"FolderPath" : sharedLibraryPath
                                                }};
            logInfo(errorInfo);
        }
    }
    return sharedLibraryPath;
}

-(void)preparePersistantStoreCoordinator{
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"KonotorModels" ofType:@"bundle"];
    NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"KonotorModel" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSString *storePath = [[self sharedLibraryPath] stringByAppendingPathComponent:@"Konotor.sqlite"];
    FDLog(@"StoreURL %@",storePath);
    NSURL *persistentStoreURL = [NSURL fileURLWithPath:storePath];
    [self logModelVersionData:persistentStoreURL];
    
    NSError* error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                            URL:persistentStoreURL options:options error:&error];
    if (error) {
        logInfo((@{@"Persistent store creation failed" :@{
                          @"Reason" : error.description,
                          @"SQLLiteFilePath" : persistentStoreURL.description
                          }}));
        [self.logger upload];
        
        // OK now lets try to create this on next attempt
        _persistentStoreCoordinator = nil;
    }
}

-(void)logModelVersionData:(NSURL *)storeURL{
    
    @try {
        NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                                  URL:storeURL error:nil];
        if (sourceMetadata) {
            logInfo(@{@"Store Info: ": sourceMetadata});
        }
        
    } @catch (NSException *exception) {
        
    }
}

-(void)setMainQueueContext{
    if(!self.persistentStoreCoordinator){
        return;
    }
    self.mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainObjectContext.undoManager = nil;
    self.mainObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.mainObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
}

-(NSManagedObjectContext *)backgroundContext{
    if (!_backgroundContext) {
        _backgroundContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        _backgroundContext.undoManager = nil;
    }
    return _backgroundContext;
}

- (BOOL)save {
    
    if (![[NSThread currentThread]isMainThread]) {
        NSDictionary *info = @{
                               @"Core data thred violation" : @{
                                       @"Reason" : @"Main context saved in a wrong thread",
                                       @"Call stack" : [NSThread callStackSymbols] }};
        
        logInfo(info);
        [self.logger upload];
        
    }
    
    if (![self.mainObjectContext hasChanges])
        return YES;
    
    NSError *error = nil;
    if (![self.mainObjectContext save:&error]) {
        if (error) {
            NSDictionary *errorInfo = @{@"Main context save failed" : @{
                                                @"Error" : error,
                                                @"call stack" : [NSThread callStackSymbols]
                                                }};
            
            logInfo(errorInfo);
            [self.logger upload];
        }
        return NO;
    }
    
    return YES;
}


/* Execute fetch request on the background context (I/O)
   fetch objects from updated PSC from main context (non I/O)
   controllers can safely call this method without blocking UI.
   returned managed objects are managed by the Main context.  */

-(void)fetchAllSolutions:(void(^)(NSArray *solutions, NSError *error))handler{
    NSManagedObjectContext *backgroundContext = self.backgroundContext;
    NSManagedObjectContext *mainContext = self.mainObjectContext;
    [backgroundContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        request.sortDescriptors = @[position];
        NSArray *results =[[backgroundContext executeFetchRequest:request error:nil]valueForKey:@"objectID"];
        NSMutableArray *fetchedSolutions = [NSMutableArray new];
        [mainContext performBlock:^{
            for (int i=0; i< results.count; i++) {
                NSManagedObject *newSolution = [mainContext existingObjectWithID:results[i] error:nil];
                [mainContext refreshObject:newSolution mergeChanges:YES];
                
                if (newSolution) {
                    [fetchedSolutions addObject:newSolution];
                }
                
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(handler) handler(fetchedSolutions,nil);
            });
        }];
    }];
}

-(void)fetchAllArticlesOfCategoryID:(NSNumber *)categoryID handler:(void(^)(NSArray *articles, NSError *error))handler{
    NSManagedObjectContext *backgroundContext = [KonotorDataManager sharedInstance].backgroundContext;
    NSManagedObjectContext *mainContext = [KonotorDataManager sharedInstance].mainObjectContext;
    [backgroundContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_ARTICLE_ENTITY];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        request.predicate = [NSPredicate predicateWithFormat:@"categoryID == %@",categoryID];
        request.sortDescriptors = @[position];
        NSArray *results =[[backgroundContext executeFetchRequest:request error:nil]valueForKey:@"objectID"];
        NSMutableArray *fetchedSolutions = [NSMutableArray new];
        [mainContext performBlock:^{
            for (int i=0; i< results.count; i++) {
                NSManagedObject *newSolution = [mainContext objectWithID:results[i]];
                [mainContext refreshObject:newSolution mergeChanges:YES];
                
                if (newSolution) {
                    [fetchedSolutions addObject:newSolution];
                }
                
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(handler) handler(fetchedSolutions,nil);
            });
        }];
    }];
}

-(void)deleteAllSolutions:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:HOTLINE_CATEGORY_ENTITY handler:handler inContext:self.backgroundContext];
}

-(void)deleteAllIndices:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:HOTLINE_INDEX_ENTITY handler:handler inContext:self.backgroundContext];
}

-(void)deleteAllEntriesOfEntity:(NSString *)entity handler:(void(^)(NSError *error))handler inContext:(NSManagedObjectContext *)context{
    [context performBlock:^{
        @try {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
            NSArray *results = [context executeFetchRequest:request error:nil];
            for (int i=0; i<results.count; i++) {
                NSManagedObject *object = results[i];
                [context deleteObject:object];
            }
            [context save:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) handler(nil);
            });
        }
        @catch(NSException *exception) {
            NSDictionary *errorInfo = @{
                                        @"msg" : @"Error deleting all Entries",
                                        @"entity" : entity,
                                        @"excp_desc" : [exception description],
                                        @"exception_stack_trace" : [exception callStackSymbols],
                                        @"call_stack_trace" : [NSThread callStackSymbols]
                                        };
            logInfo(errorInfo);
            [self.logger upload];
        }
    }];
}

-(void)areSolutionsEmpty:(void(^)(BOOL isEmpty))handler{
    NSManagedObjectContext *context = self.backgroundContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
    request.resultType = NSCountResultType;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    [context performBlock:^{
        NSUInteger count = [[context executeFetchRequest:request error:NULL].lastObject integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) handler(count == 0);
        });
    }];
}

-(void)fetchAllVisibleChannels:(void(^)(NSArray *channels, NSError *error))handler{
    NSManagedObjectContext *context = self.mainObjectContext;
    [context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        request.predicate = [NSPredicate predicateWithFormat:@"isHidden == NO"];
        request.sortDescriptors = @[position];
        NSArray *results = [context executeFetchRequest:request error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler) handler(results,nil);
        });
    }];
}

-(void)deleteAllChannels:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:HOTLINE_CHANNEL_ENTITY handler:handler inContext:self.mainObjectContext];
}

-(void)deleteAllProperties:(void (^)(NSError *))handler{
    [self deleteAllEntriesOfEntity:@"KonotorCustomProperty" handler:handler inContext:self.mainObjectContext];
}

-(void)areChannelsEmpty:(void(^)(BOOL isEmpty))handler{
    NSManagedObjectContext *context = self.mainObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CHANNEL_ENTITY];
    request.resultType = NSCountResultType;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    [context performBlock:^{
        NSUInteger count = [[context executeFetchRequest:request error:NULL].lastObject integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) handler(count == 0);
        });
    }];
}

-(void)deleteAllMessages:(void (^)(NSError *))handler{
    [self deleteAllEntriesOfEntity:@"KonotorMessage" handler:handler inContext:self.mainObjectContext];
}

@end
