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

NSString * const DataManagerDidSaveNotification = @"DataManagerDidSaveNotification";
NSString * const DataManagerDidSaveFailedNotification = @"DataManagerDidSaveFailedNotification";

@interface KonotorDataManager ()

@property (nonatomic, strong) NSManagedObjectModel *objectModel;
//TODO: Make this generic later for use across SDK - Rex
@property (nonatomic, strong) NSMutableDictionary *logInfo;

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
	return sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.logInfo = [NSMutableDictionary new];
        [self preparePersistantStoreCoordinator];
        [self setMainQueueContext];
    }
    return  self;
}

-(void)appendLogInfo:(NSString *)info forKey:(NSString *)key{
    self.logInfo[key]=info;
    FDLog(@"%@",self.logInfo);
}

-(void)appendLogInfo:(NSDictionary *)info{
    [self.logInfo addEntriesFromDictionary:info];
}


- (NSString*)sharedDocumentsPath {
    NSString *SharedDocumentsPath = nil;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    SharedDocumentsPath = [libraryPath stringByAppendingPathComponent:@"Database"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![manager fileExistsAtPath:SharedDocumentsPath isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        NSDictionary *attr = @{ NSFileProtectionKey: NSFileProtectionComplete};
        [manager createDirectoryAtPath:SharedDocumentsPath withIntermediateDirectories:YES attributes:attr error:&error];
        if (error){
            NSDictionary *errorInfo = @{@"Folder creation failed" :@{
                                                @"Reason :"   : error.description,
                                                @"Folder path used" : SharedDocumentsPath
                                                }};
            [self appendLogInfo:errorInfo];
        }
    }
    return SharedDocumentsPath;
}

-(void)preparePersistantStoreCoordinator{
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"KonotorModels" ofType:@"bundle"];
    NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"KonotorModel" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSString *storePath = [[self sharedDocumentsPath] stringByAppendingPathComponent:@"Konotor.sqlite"];
    FDLog(@"StoreURL %@",storePath);
    NSURL *persistentStoreURL = [NSURL fileURLWithPath:storePath];
    
    NSError* error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                            URL:persistentStoreURL options:options error:&error];
    if (error) {
        [self appendLogInfo:persistentStoreURL.description forKey:@"SQLite file path"];
        [self appendLogInfo:@{@"Persistent store creation failed" :@{ @"Reason" : error.description}}];
        [self retryPersistentStoreCreation:persistentStoreURL];
    }
}

-(void)retryPersistentStoreCreation:(NSURL *)storeURL{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
    
    if (error) {
        [self appendLogInfo:@{@"could not delete existing persistent store " : @{ @"Reason" : error.description }}];
    }
    
    [self appendLogInfo:@{@"Attempting to re-create persistent store at URL" : storeURL}];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil URL:storeURL options:nil error:&error]) {
        if (error) {
            
            [self appendLogInfo:@{@"Persistent store re-creation failed " : @{ @"Reason" : error.description}}];
            
            NSDictionary *additionalInfo = @{
                                             @"Time stamp" : [NSDate date],
                                             @"SDK Version" : HOTLINE_SDK_VERSION,
                                             @"Device Info" : [FDUtilities deviceInfoProperties]
            };
            [self appendLogInfo:additionalInfo];
            NSException *e= [[NSException alloc]
                                initWithName:@"Perisistent store exception"                                                     reason:[NSString stringWithFormat:@"%@", self.logInfo]                                                     userInfo:[error userInfo]];
            @throw e;
        }
    }

}

-(void)setMainQueueContext{
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
    if (![self.mainObjectContext hasChanges])
        return YES;
    
    NSError *error = nil;
    if (![self.mainObjectContext save:&error]) {
        //NSLog(@"[Konotor] Error while saving: %@\n%@", [error localizedDescription], [error userInfo]);
        [[NSNotificationCenter defaultCenter] postNotificationName:DataManagerDidSaveFailedNotification
                                                            object:error];
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DataManagerDidSaveNotification object:nil];
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
                [fetchedSolutions addObject:newSolution];
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
                [fetchedSolutions addObject:newSolution];
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

- (void)dealloc {
    [self save];
}

@end