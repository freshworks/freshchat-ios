//
//  KonotorDataManager.m
//  Konotor
//
//  Created by Vignesh G on 15/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//
#import "FCDataManager.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCConstants.h"
#import "FCMemLogger.h"
#import "FCChannels.h"
#import "FCCategories.h"
#import "FCTagManager.h"

#define logInfo(dict) [self.logger addErrorInfo:dict withMethodName:NSStringFromSelector(_cmd)];
#define logMsg(str) [self.logger addMessage:str withMethodName:NSStringFromSelector(_cmd)];

@interface FCDataManager ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;
@property (nonatomic, strong) NSPersistentStore *persistentStore;
@property (nonatomic, strong) NSManagedObjectModel *objectModel;
@property (nonatomic, strong) FCMemLogger *logger;

@end

@implementation FCDataManager

+ (FCDataManager*)sharedInstance {
    static dispatch_once_t pred;
    static FCDataManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    if(![sharedInstance isReady]){
        @synchronized(sharedInstance) {
            if(![sharedInstance isReady]){
                @try {
                    [sharedInstance preparePSC];
                    [sharedInstance prepareMainContext];
                } @catch (NSException *exception) {
                    NSString *exceptionDesc = [NSString stringWithFormat:@"COREDATA_EXCEPTION: %@", exception.description];
                    [[FCMemLogger new]addMessage:exceptionDesc];
                }
            }
        }
    }
	return sharedInstance;
}

-(BOOL)isReady{
    return (self.persistentStore && self.psc) ? YES : NO;
}

-(id)init{
    self = [super init];
    if (self) {
        self.logger = [[FCMemLogger alloc] init];
    }
    return  self;
}

- (NSString*)konotorSQLiteDirPath {
    NSString *path = nil;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    path = [libraryPath stringByAppendingPathComponent:@"Database"];
    FDLog(@"\n\n\n%@\n\n\n", path);
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![manager fileExistsAtPath:path isDirectory:&isDirectory]) {
        NSError *error = nil;
        NSDictionary *attr = @{ NSFileProtectionKey: NSFileProtectionComplete};
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:attr error:&error];
        if (error){
            NSDictionary *errorInfo = @{@"Folder Creation Failed" :@{
                                                @"Reason:"   : error.description,
                                                @"FolderPath" : path
                                                }};
            logInfo(errorInfo);
        }
    }
    return path;
}

-(NSDictionary *)configWithJournalDisabled{
    return @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
              NSInferMappingModelAutomaticallyOption : @YES,
              NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"} };
}

-(NSDictionary *)configWithJournalWALMode{
    return @{ NSMigratePersistentStoresAutomaticallyOption : @YES,
              NSInferMappingModelAutomaticallyOption : @YES,
              NSSQLitePragmasOption: @{@"journal_mode": @"WAL"} };
}

-(NSManagedObjectModel *)loadKonotorDataModel{
    NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"FreshchatModels" ofType:@"bundle"];
    NSURL *modelURL = [[NSBundle bundleWithPath:bundlePath] URLForResource:@"FreshchatModel" withExtension:@"momd"];
    NSManagedObjectModel *obj =  [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return obj;
}

-(NSURL *)konotorSQLiteURL{
    NSString *storePath = [[self konotorSQLiteDirPath] stringByAppendingPathComponent:@"Freshchat.sqlite"];
    return [NSURL fileURLWithPath:storePath];
}

// Link PSC with SQLite file, if successful return a valid PS object, log errors if any
-(NSPersistentStore *)linkPSC:(NSPersistentStoreCoordinator *)psc URL:(NSURL *)url
                         mode:(NSDictionary *)mode errorInfo:(NSDictionary *)errorInfo{
    NSError *error = nil;
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:mode error:&error];
    
    if (error) {
        if (errorInfo == nil) errorInfo = @{};
        
        logInfo(( @{ @"Error" : @[@{ @"Create PSC failed" : error }, @{ @"Additional Info" :  errorInfo }]} ));
        
        //TODO: Remove this check if we are not seeing this issue in loggly.
        if(store){
            [self unlinkStore:store fromPSC:self.psc errorInfo:@{@"RARE_PSC_ERROR" : @"Getting valid store and error when linking PSC with PS"}];
        }
        
        store = nil;
    }
    
    return store;
}

-(void)preparePSC{
    NSURL *SQLiteURL = [self konotorSQLiteURL];
    BOOL requiresMigration = [self isMigrationRequired:self.psc storeURL:SQLiteURL];
    self.psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self loadKonotorDataModel]];
    
    self.persistentStore = [self linkPSC:self.psc URL:SQLiteURL mode:[self configWithJournalWALMode]
                                             errorInfo:@{@"FAILURE_POINT" : @"Link PSC with Journal-WAL mode failed"}];
    
    if (self.persistentStore == nil) {
        
        if (requiresMigration) {
            
            logMsg(@"Core data errored out in migration, attempting to link using Journal-DELETE mode");
            
            self.psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self loadKonotorDataModel]];
            
            self.persistentStore = [self linkPSC:self.psc URL:SQLiteURL mode:[self configWithJournalDisabled]
                                  errorInfo:@{@"FAILURE_POINT" : @"Link PSC with Journal-DELETE mode failed"}];
            
            if (self.persistentStore) {
                
                BOOL hasUnlinked = [self unlinkStore:self.persistentStore fromPSC:self.psc
                                           errorInfo:@{@"FAILURE_POINT" : @"Unlinking PSC with Journal-Delete mode failed"}];
                
                if (hasUnlinked == NO) {
                    [self.logger upload];
                    return;
                }
                
                //relink to WAL mode in the same session. [ WAL mode for everyone :) ]
                self.persistentStore = [self linkPSC:self.psc URL:SQLiteURL mode:[self configWithJournalWALMode]
                                           errorInfo:@{@"FAILURE_POINT" : @"Relinking PSC with Journal-WAL mode failed"}];
                
                if (self.persistentStore == nil) {
                    [self.logger upload];
                    return;
                }else{
                    //Just adding one log message at the end to figure we have reached the goal..
                    logMsg(@"Handled core data migration failure successfully");
                }
                
            }else{
                logMsg(@"Journal-DELETE mode not helping much, so flushing out konotor SQLite files");
                [self deleteKonotorSQLiteFiles:[self konotorSQLiteDirPath]];
                [self.logger upload];
                return;
            }
        }else{
            logMsg(@"Core data errored out in normal launch");
        }
        
        [self.logger upload];
        
    }else{
        [self.logger reset];
    }
}


-(BOOL)deleteKonotorSQLiteFiles:(NSString *)dirPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Konotor.*" options:NSRegularExpressionCaseInsensitive error:nil];
    NSDirectoryEnumerator *filesEnumerator = [fileManager enumeratorAtPath:dirPath];
    BOOL status = YES;
    NSString *file;
    while (file = [filesEnumerator nextObject]) {
        NSUInteger match = [regex numberOfMatchesInString:file options:0 range:NSMakeRange(0, [file length])];
        if (match) {
            NSError *error;
            NSString *filePath = [dirPath stringByAppendingPathComponent:file];
            FDLog(@"Deleting file at URL :%@", filePath);
            [fileManager removeItemAtPath:filePath error:&error];
            if (!error) {
                FDLog(@"Deleted %@",file);
            }else{
                FDLog(@"File: %@ could not be deleted %@",file, error);
                status = NO;
                break;
            }
        }
    }
    return status;
}

-(BOOL)unlinkStore:(NSPersistentStore *)store fromPSC:(NSPersistentStoreCoordinator *)psc errorInfo:(NSDictionary *)info{
    NSError *error = nil;
    
    BOOL status = [psc removePersistentStore:store error:&error];
    
    if (status && error == nil) {
        return YES;
    }else{
        if (info == nil) info = @{};
        if (error == nil) error = [NSError errorWithDomain:@"PSC_ERROR" code:1 userInfo:@{ @"Reason" : @"PSC Could not be unlinked" }];
        logInfo((@{@"Unlinking PSC from PC failed" : @[ @{@"error" : error}, @{@"Additional Info" : info} ] }));
        return NO;
    }
}

-(BOOL)isMigrationRequired:(NSPersistentStoreCoordinator *)store storeURL:(NSURL *)storeURL{
    NSError *error = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                              URL:storeURL
                                                                                            error:&error];
    //At first launch, there won't be any store, so NO migration
    if (sourceMetadata == nil) return NO;
    
    NSManagedObjectModel *destinationModel = [store managedObjectModel];
    BOOL pscCompatible = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    return !pscCompatible;
}

-(NSManagedObjectContext *)backgroundContext{
    if ([self isReady] && _backgroundContext == nil) {
        _backgroundContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backgroundContext.persistentStoreCoordinator = self.psc;
        _backgroundContext.undoManager = nil;
    }
    return _backgroundContext;
}

-(void)prepareMainContext{
    if ([self isReady]) {
        self.mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.mainObjectContext.undoManager = nil;
        self.mainObjectContext.persistentStoreCoordinator = self.psc;
        self.mainObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }
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

- (void) fetchAllCategoriesForTags  :(NSArray*) categoriesIds withCompletion :(void(^)(NSArray *solutions, NSError *error))handler{
    NSManagedObjectContext *mainContext = self.mainObjectContext;
    [mainContext performBlock:^{
        NSMutableArray *fetchedSolutions = [NSMutableArray new];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        if(categoriesIds.count > 0){
            for(NSNumber * categoryId in categoriesIds){
                FCCategories *category = [FCCategories getWithID:categoryId inContext:mainContext];
                if(category){
                    [fetchedSolutions addObject :category];
                }
            }
            NSArray *sortedChannels = [fetchedSolutions sortedArrayUsingDescriptors:@[position]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(handler) handler(sortedChannels,nil);
            });
        }
        else{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CATEGORIES_ENTITY];
            request.sortDescriptors = @[position];
            NSArray *results = [mainContext executeFetchRequest:request error:nil];
            for (int i=0; i< results.count; i++) {
                [fetchedSolutions addObject:results[i]];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler) handler(fetchedSolutions,nil);
        });
    }];
}

- (void) fetchAllCategoriesWithCompletion :(void(^)(NSArray *solutions, NSError *error))handler{
    NSManagedObjectContext *mainContext = self.mainObjectContext;
    [mainContext performBlock:^{
        NSMutableArray *fetchedSolutions = [NSMutableArray new];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CATEGORIES_ENTITY];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        request.sortDescriptors = @[position];
        NSArray *results = [mainContext executeFetchRequest:request error:nil];
        for (int i=0; i< results.count; i++) {
            [fetchedSolutions addObject:results[i]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler) handler(fetchedSolutions,nil);
        });
    }];
}

-(void)fetchAllArticlesOfCategoryID:(NSNumber *)categoryID handler:(void(^)(NSArray *articles, NSError *error))handler{
    NSManagedObjectContext *mainContext = [FCDataManager sharedInstance].mainObjectContext;
    [mainContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_ARTICLES_ENTITY];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
        request.predicate = [NSPredicate predicateWithFormat:@"categoryID == %@",categoryID];
        request.sortDescriptors = @[position];
        NSArray *results =[[mainContext executeFetchRequest:request error:nil]valueForKey:@"objectID"];
        dispatch_async(dispatch_get_main_queue(), ^{
                if(handler) handler(results,nil);
        });
    }];
}

-(void)deleteAllSolutions:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_CATEGORIES_ENTITY handler:handler inContext:self.backgroundContext];
}

-(void)deleteAllIndices:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_FAQ_SEARCH_INDEX_ENTITY handler:handler inContext:self.backgroundContext];
}

-(void)deleteAllFAQ:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_CATEGORIES_ENTITY handler:^(NSError *error) {
        [self deleteAllEntriesOfEntity:FRESHCHAT_FAQ_SEARCH_INDEX_ENTITY handler:^(NSError *error) {
            [[FCTagManager sharedInstance] deleteTagWithTaggableType:@[@1,@2] handler:handler inContext:self.backgroundContext];
        } inContext:self.backgroundContext];
    } inContext:self.backgroundContext];
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
            FDLog(@"Deleting entries from table : %@ ", entity);
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CATEGORIES_ENTITY];
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

- (void) fetchAllVisibleChannelsForTags:(NSArray *)channelsIds hasTags:(BOOL)containstags   completion:(void (^)(NSArray *channelInfos, NSError *))handler {
    
    NSManagedObjectContext *context = self.mainObjectContext;
    [context performBlock:^{
        NSMutableArray *channelInfos= [NSMutableArray new];
        if(channelsIds.count >0){
            for(NSNumber * channelId in channelsIds){
                FCChannels *channel = [FCChannels getWithID:channelId inContext:context];
                if(channel){
                    [channelInfos addObject:channel];
                }
            }
            NSSortDescriptor *channelSorter = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
            [channelInfos sortUsingDescriptors:@[channelSorter]];
        }
        else{
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
            NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
            
            NSPredicate *predicate = (containstags) ? [NSPredicate predicateWithFormat:@"isHidden == NO"] : [NSPredicate predicateWithFormat:@"isHidden == NO AND isRestricted == NO"];
            request.predicate = predicate;
            request.sortDescriptors = @[position];
            NSArray *results = [context executeFetchRequest:request error:nil];
            for (int i=0; i<results.count; i++) {
                FCChannels *channel = results[i];
                FCChannelInfo *channelInfo = [[FCChannelInfo alloc ]initWithChannel:channel];
                [channelInfos addObject:channelInfo];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler) handler(channelInfos,nil);
        });
    }];
}

- (void) fetchAllVisibleChannelsWithCompletion:(void (^)(NSArray *channelInfos, NSError *))handler {
    
    NSManagedObjectContext *context = self.mainObjectContext;
    [context performBlock:^{
        NSMutableArray *channelInfos= [NSMutableArray new];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
        NSSortDescriptor *position = [NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES];
    
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isHidden == NO AND isRestricted == NO"];
        request.predicate = predicate;
        request.sortDescriptors = @[position];
        NSArray *results = [context executeFetchRequest:request error:nil];
        for (int i=0; i<results.count; i++) {
            FCChannels *channel = results[i];
            FCChannelInfo *channelInfo = [[FCChannelInfo alloc ]initWithChannel:channel];
            [channelInfos addObject:channelInfo];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if(handler) handler(channelInfos,nil);
        });
    }];
}

-(void)deleteAllChannels:(void(^)(NSError *error))handler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_CHANNELS_ENTITY handler:handler inContext:self.mainObjectContext];
}

-(void)deleteAllProperties:(void (^)(NSError *))handler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_USER_PROPERTIES_ENTITY handler:handler inContext:self.mainObjectContext];
}

-(void)deleteAllCSATEntries:(void (^)(NSError *))handler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_CSAT_ENTITY handler:handler inContext:self.mainObjectContext];
}

-(void)cleanUpUser:(void (^)(NSError *))mainHandler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_TAGS_ENTITY handler:^(NSError *error){
        [self clearUserExceptTags:mainHandler];
 } inContext:self.mainObjectContext];
}

-(void)clearUserExceptTags:(void (^)(NSError *))mainHandler{
    [self deleteAllEntriesOfEntity:FRESHCHAT_CSAT_ENTITY handler:^(NSError *error){
        [self deleteAllEntriesOfEntity:FRESHCHAT_MESSAGES_ENTITY handler:^(NSError *error){
            [self deleteAllEntriesOfEntity:FRESHCHAT_MESSAGE_FRAGMENTS_ENTITY handler:^(NSError *error){
                [self deleteAllEntriesOfEntity:FRESHCHAT_CHANNELS_ENTITY handler:^(NSError *error){
                    [self deleteAllEntriesOfEntity:FRESHCHAT_USER_PROPERTIES_ENTITY handler:^(NSError *error){
                        mainHandler(error);
                    } inContext:self.mainObjectContext];
                } inContext:self.mainObjectContext];
            } inContext:self.mainObjectContext];
        } inContext:self.mainObjectContext];
    } inContext:self.mainObjectContext];
}



-(void)areChannelsEmpty:(void(^)(BOOL isEmpty))handler{
    NSManagedObjectContext *context = self.mainObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:FRESHCHAT_CHANNELS_ENTITY];
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
