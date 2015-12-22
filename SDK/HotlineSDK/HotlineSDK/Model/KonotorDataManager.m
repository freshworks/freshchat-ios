//
//  KonotorDataManager.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//
#import "KonotorDataManager.h"
#import "HLMacros.h"

NSString * const DataManagerDidSaveNotification = @"DataManagerDidSaveNotification";
NSString * const DataManagerDidSaveFailedNotification = @"DataManagerDidSaveFailedNotification";

@interface KonotorDataManager ()

@property (nonatomic, strong) NSManagedObjectModel *objectModel;

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
        [self preparePersistantStoreCoordinator];
        [self setMainQueueContext];
    }
    return  self;
}

-(void)preparePersistantStoreCoordinator{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"KonotorModels" ofType:@"bundle"];
    NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"KonotorModel" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSString *storePath = [[self sharedDocumentsPath] stringByAppendingPathComponent:@"Konotor.sqlite"];
    NSURL *persistantStoreURL = [NSURL fileURLWithPath:storePath];
    NSError* error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                            URL:persistantStoreURL options:options error:&error];
    if (error) {
        FDLog(@"Persistant Coordinator could not be created \n%@", error);
        //delete the sqlite file and try again
        [[NSFileManager defaultManager] removeItemAtPath:persistantStoreURL.path error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistantStoreURL options:nil error:&error]) {
            NSException *e= [[NSException alloc] initWithName:@"PerisistentStoreException" reason:[NSString stringWithFormat:@"Unresolved error %@, %@", error,[error userInfo]] userInfo:[error userInfo]];
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

- (NSString*)sharedDocumentsPath {
	static NSString *SharedDocumentsPath = nil;
    if (SharedDocumentsPath){
        return SharedDocumentsPath;
    }
    
	// Compose a path to the <Library>/Database directory
	NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	SharedDocumentsPath = [libraryPath stringByAppendingPathComponent:@"Database"];
    
    FDLog(@"database path :%@", SharedDocumentsPath);
    
	// Ensure the database directory exists
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if (![manager fileExistsAtPath:SharedDocumentsPath isDirectory:&isDirectory] || !isDirectory) {
		NSError *error = nil;
		NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
		[manager createDirectoryAtPath:SharedDocumentsPath withIntermediateDirectories:YES attributes:attr error:&error];
        if (error){
            NSLog(@"Error creating directory path: %@", [error localizedDescription]);
        }
	}
	return SharedDocumentsPath;
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
                NSManagedObject *newSolution = [mainContext objectWithID:results[i]];
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

- (void)dealloc {
    [self save];
}

@end