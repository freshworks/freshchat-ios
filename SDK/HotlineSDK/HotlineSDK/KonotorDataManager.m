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

- (NSString*)sharedDocumentsPath;

@end

@implementation KonotorDataManager

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize mainObjectContext = _mainObjectContext;
@synthesize objectModel = _objectModel;

NSString * const kDataManagerBundleName = @"KonotorModels";
NSString * const kDataManagerModelName = @"KonotorModel";
NSString * const kDataManagerSQLiteName = @"Konotor.sqlite";

+ (KonotorDataManager*)sharedInstance {
	static dispatch_once_t pred;
	static KonotorDataManager *sharedInstance = nil;
    
	dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
	return sharedInstance;
}

- (void)dealloc {
	[self save];
}

- (NSManagedObjectModel*)objectModel {
	if (_objectModel)
		return _objectModel;
    
	NSBundle *bundle = [NSBundle mainBundle];
	if (kDataManagerBundleName)
    {
        
        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"KonotorModels" ofType:@"bundle"];
		bundle = [NSBundle bundleWithPath:bundlePath];
	}
	NSString *modelPath = [bundle pathForResource:kDataManagerModelName ofType:@"momd"];
	_objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
    
	return _objectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
	if (_persistentStoreCoordinator)
		return _persistentStoreCoordinator;
    
	// Get the paths to the SQLite file
	NSString *storePath = [[self sharedDocumentsPath] stringByAppendingPathComponent:kDataManagerSQLiteName];
	NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
	// Define the Core Data version migration options
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    
    
	// Attempt to load the persistent store
	NSError *error = nil;
    
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
		//NSLog(@"Fatal error while creating persistent store: %@", error);
		abort();
	}
    
	return _persistentStoreCoordinator;
}

- (NSManagedObjectContext*)mainObjectContext {
	if (_mainObjectContext)
		return _mainObjectContext;
    
	// Create the main context only on the main thread
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(mainObjectContext) withObject:nil waitUntilDone:YES];
		return _mainObjectContext;
	}
	_mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainObjectContext.undoManager = nil;
    _mainObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    _mainObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	return _mainObjectContext;
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

- (NSString*)sharedDocumentsPath {
	static NSString *SharedDocumentsPath = nil;
	if (SharedDocumentsPath)
		return SharedDocumentsPath;
    
	// Compose a path to the <Library>/Database directory
	NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	SharedDocumentsPath = [libraryPath stringByAppendingPathComponent:@"Database"];
    
	// Ensure the database directory exists
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDirectory;
	if (![manager fileExistsAtPath:SharedDocumentsPath isDirectory:&isDirectory] || !isDirectory) {
		NSError *error = nil;
		NSDictionary *attr = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                         forKey:NSFileProtectionKey];
		[manager createDirectoryAtPath:SharedDocumentsPath
		   withIntermediateDirectories:YES
                            attributes:attr
                                 error:&error];
		if (error)
			NSLog(@"Error creating directory path: %@", [error localizedDescription]);
	}
    
	return SharedDocumentsPath;
}

-(NSManagedObjectContext *)backgroundContext{
    if (!_backgroundContext) {
        _backgroundContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        _backgroundContext.undoManager = nil;
    }
    return _backgroundContext;
}

/* Execute fetch request on the background context (I/O). which inturn update PSC, fetch objects from updated PSC from main context (non I/O)
 Controllers can safely can this method without blocking UI, returned managed objects are managed by main context. */

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
            [mainContext reset];
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

- (void)deleteAllSolutions:(void(^)(NSError *error))handler{
    NSManagedObjectContext *context = self.backgroundContext;
    [context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HOTLINE_CATEGORY_ENTITY];
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

@end