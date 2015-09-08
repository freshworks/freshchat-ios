//
//  coreDataCoordinator.m
//  FreshdeskSDK
//
//  Created by kirthikas on 23/03/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDCoreDataCoordinator.h"
#import "FDMacros.h"
#import "FDUtilities.h"

#define EXTENSION_MOMD                   @"momd"
#define EXTENSION_BUNDLE                 @"bundle"
#define CORE_DATA_MODEL_ID               @"MobiHelp"
#define CORE_DATA_MODEL_CONTAINER_BUNDLE @"MHModel"
#define MOBIHELP_DIRECTORY_NAME          @"Mobihelp"
#define MOBIHELP_SQLITE_FILE_NAME        @"MobiHelpModel.sqlite"

@implementation FDCoreDataCoordinator

#pragma mark singleton methods

+(id)sharedInstance{
    static FDCoreDataCoordinator *sharedInstance = nil;
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken,^{
        sharedInstance = [[FDCoreDataCoordinator alloc]init];
    });
    return sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        self.fileManager = [NSFileManager defaultManager];
        [self preparePersistantStoreCoordinator];
    }
    return  self;
}

-(NSManagedObjectContext *)mainContext{

#ifdef DEBUG
    [FDUtilities assertMainThread];
#endif
    
    if(!_mainContext){
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        _mainContext.undoManager = [[NSUndoManager alloc] init];
    }
    
    return _mainContext;
}

-(void)preparePersistantStoreCoordinator{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:CORE_DATA_MODEL_CONTAINER_BUNDLE ofType:EXTENSION_BUNDLE];
    NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:CORE_DATA_MODEL_ID withExtension:EXTENSION_MOMD];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSURL *persistantStoreURL = [self getPersistantStoreURL];
    NSError* error;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES };
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                            URL:persistantStoreURL options:options error:&error];
    if (error) {
        FDLog(@"Persistant Coordinator could not be created \n%@", error);
    }
}

-(NSManagedObjectContext*) getBackgroundContext{
    NSManagedObjectContext* backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    backgroundContext.undoManager = [[NSUndoManager alloc] init];
    [self registerContextNotification:backgroundContext];
    return backgroundContext;
}

-(void)registerContextNotification:(NSManagedObjectContext*) context{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification
                             object:context];
}

-(void)contextDidSave:(NSNotification*)notification{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSManagedObjectContext *moc = self.mainContext;
        [moc mergeChangesFromContextDidSaveNotification:notification];
    });
}

-(NSURL *)getPersistantStoreURL{
    NSURL *storeURL = nil;
    NSString *libraryDirectory   = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *mobihelpDirectory  = [self createFolder:MOBIHELP_DIRECTORY_NAME InDirectory:libraryDirectory];
    if ([self hasMobihelpSQLiteInDirectory:documentsDirectory]){
        NSLog(@"moving Mobihelp DB from Documents directory to Library directory");
        [self moveMobihelpSQLiteFromSource:documentsDirectory toDestination:mobihelpDirectory];
    }
    NSString *sqliteStorePath = [mobihelpDirectory stringByAppendingPathComponent:MOBIHELP_SQLITE_FILE_NAME];
    storeURL = [NSURL fileURLWithPath:sqliteStorePath];
    FDLog(@"Store URL %@",storeURL);
    return storeURL;
}

-(BOOL)hasMobihelpSQLiteInDirectory:(NSString *)directory{
    NSString *mobihelpSQLiteStorePath = [directory stringByAppendingPathComponent:MOBIHELP_SQLITE_FILE_NAME];
    return [self.fileManager fileExistsAtPath:mobihelpSQLiteStorePath];
}

-(void)moveMobihelpSQLiteFromSource:(NSString *)sourceDirectory toDestination:(NSString *)destinationDirectory{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"MobiHelpModel.*" options:NSRegularExpressionCaseInsensitive error:nil];
    NSDirectoryEnumerator *filesEnumerator = [self.fileManager enumeratorAtPath:sourceDirectory];
    NSString *file;
    while (file = [filesEnumerator nextObject]) {
        NSUInteger match = [regex numberOfMatchesInString:file options:0 range:NSMakeRange(0, [file length])];
        if (match) {
            NSError *error;
            NSURL *sourceFileURL  = [NSURL fileURLWithPath:[sourceDirectory stringByAppendingPathComponent:file]];
            NSURL *destinationURL = [NSURL fileURLWithPath:[destinationDirectory stringByAppendingPathComponent:file]];
            [self.fileManager moveItemAtURL:sourceFileURL toURL:destinationURL error:&error];
            if (!error) {
                FDLog(@"moved %@",file);
            }else{
                NSLog(@"File: %@ could not be moved %@",file, error);
            }
        }
    }
}

-(NSString *)createFolder:(NSString *)folderName InDirectory:(NSString *)directory{
    NSString *folderPath = [directory stringByAppendingPathComponent:folderName];
    if (![self.fileManager fileExistsAtPath:folderPath]){
        NSError *error;
        [self.fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"%@ folder could not be created",folderName);
        }
    }
    return folderPath;
}

@end