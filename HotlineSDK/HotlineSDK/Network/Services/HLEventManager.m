//
//  HLEventManager.m
//  HotlineSDK
//
//  Created by Harish Kumar on 09/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLEventManager.h"
#import "FDUtilities.h"
#import "Hotline.h"
#import "FDSecureStore.h"
#import "KonotorDataManager.h"
#import "HLAPIClient.h"
#import "HLServiceRequest.h"
#import "HLMacros.h"
#import "FDReachabilityManager.h"
#import "HLEvent.h"

#define isRetriableHttpError(code) (code != HLEVENTS_HTTP_RESPONSE_CODE_UNSUPPORTED_MEDIA_TYPE || \
                                    code != HLEVENTS_HTTP_RESPONSE_CODE_VALIDATION_FAILED )

#define canRetryResponseCode(code) !(( code == EVENT_STORE_RESPCODE_VALIDATION_FAILED) || \
                                    ( code == EVENT_STORE_RESPCODE_UNSUPPORTED_MEDIA_TYPE) || \
                                    ( code == EVENT_STORE_RESPCODE_INVALID_REQUEST_FORMAT))

#define isSuccessRespCode(code) ( code == EVENT_STORE_RESPCODE_REQUEST_ACCEPTED)

@interface HLEventManager()

//@property (nonatomic, strong) NSMutableArray *eventsArray;
@property (nonatomic, strong) NSMutableDictionary *events;
@property (nonatomic, strong) NSString *plistPath;
@property (nonatomic, strong) NSString *sessionID;
@property (nonatomic, strong)NSTimer *pollingTimer;
@property dispatch_queue_t eventsQ;
@property (nonatomic, strong) NSNumber *maxEventId;

@end

@implementation HLEventManager

+ (instancetype)sharedInstance{
    static HLEventManager *sharedHLEventManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHLEventManager = [[self alloc]init];
    });
    return sharedHLEventManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.events = [NSMutableDictionary dictionary];
        self.sessionID = [FDStringUtil generateUUID];
        self.eventsQ = dispatch_queue_create("com.freshdesk.hotline.events", DISPATCH_QUEUE_SERIAL);
        self.plistPath = [[FDUtilities returnLibraryPathForDir:HLEVENT_DIR_PATH] stringByAppendingPathComponent:HLEVENT_FILE_NAME];
        self.maxEventId = 0;
        [self loadEvents];
        [self startEventsUploadTimer];
    }
    return self;
}

-(NSString *)getEventsURL{
#if DEBUG
    return HLEVENTS_BULK_EVENTS_DEBUG_URL;
#else
    NSString *domain = [[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    if ([theme rangeOfString:@"orange"].location != NSNotFound ||
        [theme rangeOfString:@"blonde"].location != NSNotFound ||
        [theme rangeOfString:@"white"].location != NSNotFound ||
        [theme rangeOfString:@"black"].location != NSNotFound ||
        [theme rangeOfString:@"staging"].location != NSNotFound){
        return HLEVENTS_BULK_EVENTS_DEBUG_URL;
    }
    return HLEVENTS_BULK_EVENTS_URL;
#endif
}

-(void)startEventsUploadTimer{
    [self runSync:^{
        if([[FDReachabilityManager sharedInstance] isReachable]){
            if([self.pollingTimer isValid]){
                FDLog(@"Poller Already running");
            }
            else if(self.events.count == 0){
                FDLog(@"Not Starting poller. No events to send" );
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:15
                                                                         target:self
                                                                       selector:@selector(processEventBatch)
                                                                       userInfo:nil
                                                                        repeats:YES];
                    FDLog(@"Started events poller");
                });
            }
        }
    }];
}

-(void)cancelEventsUploadTimer{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
        FDLog(@"Cancelled Poller");
    }
}

-(void) submitEvent:(NSString *)eventName
                   ofType:(NSString *)eventType
                withBlock:(void(^)(HLEvent *event))builderBlock{
    [self runSync:^{
        HLEvent *event = [[HLEvent alloc] initWithEventName:eventName];
        [event propKey:HLEVENT_PARAM_TYPE andVal:HLEVENT_TYPE_SDK];
        builderBlock(event);
        NSDictionary *eventDictionary = [event toEventDictionary:[HLEventManager getUserSessionId]];
        if(eventDictionary){
            [self updateFileWithEvent:eventDictionary];
        }
    }];
}

//All events right now are generated from SDK. Add user events when we expose API for events.
-(void) submitSDKEvent:(NSString *)eventName withBlock:(void(^)(HLEvent *event))builderBlock{
    [self submitEvent:eventName
                         ofType:HLEVENT_TYPE_SDK
                      withBlock:builderBlock];
}

- (void) loadEvents {
    [self runSync:^{
        NSData *data = [NSData dataWithContentsOfFile:self.plistPath];
        NSDictionary *eventsDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        self.events = [eventsDict mutableCopy];
        for(NSNumber *eventId in self.events){
            if(eventId > self.maxEventId){
                self.maxEventId = eventId;
            }
        }
    }];
}

-(NSNumber *)nextEventId{
    self.maxEventId = @([self.maxEventId longValue] + 1);
    return self.maxEventId;
}

-(void) updateFileWithEvent:(NSDictionary *) eventDict{
    [self.events setObject:eventDict forKey:[self nextEventId]];
    FDLog(@"Submitted event to store, %@", eventDict);
    [self saveEvents];
}

-(void) writeEventsToStore{
    NSDictionary *eventsCopy = [self.events copy];
    if (![NSKeyedArchiver archiveRootObject:eventsCopy toFile:self.plistPath]) {
        FDLog(@"%@ unable to create events data", self);
    }
}

-(void) processEventBatch{
    FDLog(@"Scheduling upload");
    [self runSync:^{
        if(![[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DEVICE_UUID]){
            return;
        }
        
        NSMutableArray *eventIds = [NSMutableArray array];
        NSMutableArray *eventsBatch = [NSMutableArray array];
        NSUInteger numEvents = [self.events count];
        int batchCount=0,total=0;
        for(NSNumber *eventId in self.events){
            batchCount++ ; total++;
            [eventIds addObject:eventId];
            NSDictionary *eventInfo = [self.events objectForKey:eventId];
            FDLog(@"collecting event %@", eventInfo )
            [eventsBatch addObject:eventInfo];
            if(batchCount >= HLEVENTS_BATCH_SIZE || total >= numEvents ) {
                [self uploadUserEvents:eventsBatch withIds:eventIds];
                eventIds = [NSMutableArray array];
                eventsBatch = [NSMutableArray array];
                batchCount = 0;
            }
        }
        
    }];
}

-(void)runSync:(dispatch_block_t) block{
    dispatch_async(self.eventsQ,block);
}

- (void) reset{
    [self runSync:^{
        [self clearEvents];
    }];
}
     
- (void)clearEvents{
    self.events = [NSMutableDictionary dictionary];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:self.plistPath];
    NSError *error;
    if(exists) {
        [fileManager removeItemAtPath:self.plistPath  error:&error];
    }
    else{
        FDLog(@"** Event manager :: File not exists!!! ***");
    }
    FDLog(@"*** Cleared All Events ***");
}

-(void)removeEvents:(NSArray *) eventsToRemove{
    for(NSNumber *eventId in eventsToRemove){
        NSDictionary *evt = [self.events objectForKey:eventId];
        if(evt){
            [self.events removeObjectForKey:eventId];
            FDLog(@"Removing Event %@", evt);
        }
    }
    [self saveEvents];
}

+(NSString *)getUserSessionId{
    return [NSString stringWithFormat:@"%@_%@", [HLEventManager sharedInstance].sessionID, [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000] stringValue]];
}

- (void) uploadUserEvents:(NSArray *)events withIds:(NSArray *) eventIds{

    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *eventURL = [NSString stringWithFormat:@"%@/%@",[self getEventsURL],[store objectForKey:HOTLINE_DEFAULTS_APP_ID]];
    
    NSError *error;
    NSData * postData = [NSJSONSerialization dataWithJSONObject:events options:0 error:&error];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:eventURL] andMethod:HTTP_METHOD_POST];
    request.HTTPBody = postData;
    [self runSync:^{
        [apiClient request:request withHandler:^(FDResponseInfo *responseInfo,NSError *error) {
            if (!error) {
                if([responseInfo isDict]) {
                    NSMutableArray *eventsToRemove = [[NSMutableArray alloc] init];
                    NSArray *eventsResponse = [responseInfo responseAsDictionary][@"result"];
                    for (int i=0; i<[eventsResponse count]; i++) {
                        NSInteger status = [[eventsResponse objectAtIndex:i][@"status"] intValue];
                        if(isSuccessRespCode(status) ||  !canRetryResponseCode(status)){
                            [eventsToRemove addObject:[eventIds objectAtIndex:i]];
                        }
                    }
                    [self removeEvents:eventsToRemove];
                }
            }else{
                if(error.code == HLEVENTS_HTTP_RESPONSE_CODE_NOT_SUPPORTED){
                    [self clearEvents];
                }
                else if(!isRetriableHttpError(error.code)){
                    [self removeEvents:eventIds];
                }
            }
        }];
    }];
    
}

- (void)saveEvents{
    [self runSync:^{
        if([self.events count]==0){
            [self clearEvents];
            [self cancelEventsUploadTimer];
        }
        else {
            [self startEventsUploadTimer];
        }
        [self writeEventsToStore];
    }];
}

@end
