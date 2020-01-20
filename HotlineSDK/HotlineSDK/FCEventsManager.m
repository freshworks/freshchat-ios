//
//  FCEventsManager.m
//  FreshchatSDK
//
//  Created by Harish kumar on 10/11/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import "FCEventsManager.h"
#import "FCUtilities.h"
#import "FCMacros.h"
#import "FCReachabilityManager.h"
#import "FCRemoteConfig.h"
#import "FCUserUtil.h"
#import "FCCoreServices.h"
#import "FCEventsHelper.h"
#import "FCJWTUtilities.h"
#import "FCEventsConstants.h"
#import "FCSecureStore.h"

@interface FCEventsManager()

@property (nonatomic, strong) NSMutableDictionary *inBoundEvents;
@property (nonatomic, strong) NSMutableDictionary *triggerEventsBatch;
@property (atomic) dispatch_queue_t eventsQueue;
@property (nonatomic, strong) NSString *plistPath;
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) NSNumber *maxEventId;

@end

@implementation FCEventsManager

+ (instancetype)sharedInstance {
    static FCEventsManager *sharedFCEventsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFCEventsManager = [[self alloc]init];
    });
    return sharedFCEventsManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.inBoundEvents = [NSMutableDictionary dictionary];
        self.triggerEventsBatch = [NSMutableDictionary dictionary];
        self.eventsQueue = dispatch_queue_create("com.freshworks.freshchat.events", DISPATCH_QUEUE_SERIAL);
        self.plistPath = [[FCUtilities returnLibraryPathForDir:FC_INBOUND_EVENT_DIR_PATH] stringByAppendingPathComponent:FC_INBOUND_EVENT_FILE_NAME];
        self.maxEventId = [[FCSecureStore sharedInstance] objectForKey:FRESHCHAT_DEFAULTS_EVENTS_IDENTIFIER_COUNT];
        [self loadEvents];
    }
    return self;
}

-(void)startEventsUploadTimer{
    [self runSync:^{
        if(![[FCReachabilityManager sharedInstance] isReachable]
           || [self.pollingTimer isValid]
           || self.inBoundEvents.count == 0){
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.pollingTimer == nil){
                self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval: ([FCRemoteConfig sharedInstance].eventsConfig.maxDelayInMillisUntilUpload/1000)
                                                                     target:self
                                                                   selector:@selector(processEventBatch)
                                                                   userInfo:nil
                                                                    repeats:YES];
                FDLog(@"Started events poller");
            }
        });
    }];
}

-(void)cancelEventsUploadTimer {
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
        FDLog(@"Cancelled Poller");
    }
}

-(void) submitSDKEventWithInfo:(NSDictionary *) eventInfo {
    NSNumber *eventId = [self nextEventId];
    [self runSync:^{
        [self.inBoundEvents setObject:eventInfo forKey:eventId];
        [self.triggerEventsBatch setObject:eventInfo forKey:eventId];
        [self saveEvents];
    }];
}

- (void) loadEvents {
    [self runSync:^{
        NSData *data = [NSData dataWithContentsOfFile:self.plistPath];
        if(data){
            NSDictionary *eventsDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            self.inBoundEvents = [eventsDict mutableCopy];
        }
    }];
}

-(NSNumber *)nextEventId{
    self.maxEventId = @([self.maxEventId intValue] + 1);
    if ([self.maxEventId intValue] > EVENTS_MAX_ID_VALUE) {
        self.maxEventId = @(0);
    }
    return self.maxEventId;
}

-(void) writeEventsToStore{
    
    [[FCSecureStore sharedInstance] setObject:self.maxEventId forKey:FRESHCHAT_DEFAULTS_EVENTS_IDENTIFIER_COUNT];
    int unuploadedEventsLimit = [FCRemoteConfig sharedInstance].eventsConfig.maxAllowedEventsPerDay;
    if (![FCUserUtil isUserRegistered] && (self.inBoundEvents.count > unuploadedEventsLimit)){
        int delIndex;
        int currentIndex = [self.maxEventId intValue];
        
        if ((currentIndex - unuploadedEventsLimit) < 0){
            delIndex = EVENTS_MAX_ID_VALUE - (unuploadedEventsLimit - currentIndex);
        }
        else{
            delIndex = (currentIndex - unuploadedEventsLimit);
        }
        [self.inBoundEvents removeObjectForKey:[NSNumber numberWithInt:delIndex]];
        [self updateEventFile:self.inBoundEvents];
    }
    if(self.triggerEventsBatch.count > 0 && [FCUserUtil isUserRegistered]){
        if (self.triggerEventsBatch.count >= [FCRemoteConfig sharedInstance].eventsConfig.triggerUploadOnEventsCount){
            [self processEventBatchWithEvents:[self.triggerEventsBatch copy]];
            
        }else {
            //if timer is already running then donot start again
            if(![self.pollingTimer isValid]){
                [self startEventsUploadTimer];
            }
        }
    }
}

- (void) updateEventFile : (NSMutableDictionary *) events{
    if ((SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.0"))) {
        NSData *eventData = [NSKeyedArchiver archivedDataWithRootObject:events];
        [eventData writeToFile:self.plistPath atomically:YES];
    }
    else{
        [NSKeyedArchiver archiveRootObject:events toFile:self.plistPath];
    }
}

- (void)saveEvents{
    [self writeEventsToStore];
}

-(void) processEventBatch{
    NSMutableDictionary *eventsToUpload = [[NSMutableDictionary alloc] initWithDictionary:self.inBoundEvents];
    [self processEventBatchWithEvents:eventsToUpload];
}


-(void) processEventBatchWithEvents : (NSDictionary *) events {
    [self.triggerEventsBatch removeAllObjects]; 
    if(![[FCReachabilityManager sharedInstance] isReachable]
       || ![FCUserUtil isUserRegistered] || (events.count == 0) ||
       ([[FCRemoteConfig sharedInstance] isUserAuthEnabled] && ![FCJWTUtilities hasValidTokenState])){
        return; //Do not upload events if user isn't registered or Count or JWT invalid
    }
    
    [self runSync:^{
        NSUInteger numEvents = [events count];
        NSMutableDictionary *batchEventsToUpload = [[NSMutableDictionary alloc] init];
        int batchCount=0,total=0;
        [self cancelEventsUploadTimer];
        for(NSNumber *eventId in events){
            batchCount++ ; total++;
            NSDictionary *eventInfo = [events objectForKey:eventId];
            if(eventInfo != nil){
                [batchEventsToUpload setObject:eventInfo forKey:eventId];
                if((batchCount >= [FCRemoteConfig sharedInstance].eventsConfig.maxEventsPerBatch) || (total >= numEvents)) {
                    //Delete uploading events
                    [self removeEvents:batchEventsToUpload];
                    [FCCoreServices uploadInboundEvents:batchEventsToUpload withCompletion:^(BOOL uploaded, NSDictionary *uploadedEvents, NSError *error) {
                        if(error && !uploaded) {
                            FDLog("Events upload failed due to : %@", error);
                            //Add uploaded events back to plist
                            [self addEvents:uploadedEvents];
                        }
                    }];
                    [batchEventsToUpload removeAllObjects];
                    batchCount = 0;
                }
            }
        }
    }];
}

- (void)runSync:(dispatch_block_t) block {
    dispatch_async(self.eventsQueue,block);
}

- (void) reset {
    [self runSync:^{
        [self clearEvents];
    }];
}

- (void) clearEvents {
    
    self.inBoundEvents = [NSMutableDictionary dictionary];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:self.plistPath];
    //Remove count event index count
    [FCEventsHelper removeEventsIdentifier];
    NSError *error;
    if(exists) {
        [fileManager removeItemAtPath:self.plistPath  error:&error];
    }
    else{
        FDLog(@"** Event manager :: File not exists!!! ***");
    }
    FDLog(@"*** Cleared All Inbound Events ***");
}

- (void) addEvents : (NSDictionary *) eventsToAdd {
        [self.inBoundEvents addEntriesFromDictionary:eventsToAdd];
        [self updateEventFile:self.inBoundEvents];
}

-(void)removeEvents:(NSDictionary *) eventsToRemove{
    for(NSNumber *eventId in eventsToRemove){
        NSDictionary *evt = [self.inBoundEvents objectForKey:eventId];
        if(evt){
            [self.inBoundEvents removeObjectForKey:eventId];
        }
    }
    [self updateEventFile:self.inBoundEvents];
}

@end
