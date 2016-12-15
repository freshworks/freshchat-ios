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


#define isRetriableHttpError(code) code != HLEVENTS_HTTP_RESPONSE_CODE_UNSUPPORTED_MEDIA_TYPE || \
                                    code != HLEVENTS_HTTP_RESPONSE_CODE_VALIDATION_FAILED

#define canRetryResponseCode(code) !(( code == EVENT_STORE_RESPCODE_VALIDATION_FAILED) || \
                                    ( code == EVENT_STORE_RESPCODE_UNSUPPORTED_MEDIA_TYPE) || \
                                    ( code == EVENT_STORE_RESPCODE_INVALID_REQUEST_FORMAT))

#define isSuccessRespCode(code) ( code == EVENT_STORE_RESPCODE_REQUEST_ACCEPTED)

@interface HLEventManager()

@property (nonatomic, strong) NSString *plistURL;
@property (nonatomic, strong) NSString *sessionID;
@property dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSTimer *pollingTimer;

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
        self.eventsArray = [NSMutableArray array];
        self.sessionID = [FDStringUtil generateUUID];
        self.serialQueue = dispatch_queue_create("com.freshdesk.hotline.events", DISPATCH_QUEUE_SERIAL);
        self.plistURL = [self returnEventLibraryPath];
        [self getOldEvents];
        [self startEventsUploadTimer];
    }
    return self;
}

-(NSString *)getEventsURL{
#if DEBUG
    return HLEVENTS_BULK_EVENTS_DEBUG_URL;
#else
    NSString *domain = [[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    if ([theme rangeOfString:@"mr.orange"].location != NSNotFound ||
        [theme rangeOfString:@"mr.blonde"].location != NSNotFound ||
        [theme rangeOfString:@"mr.white"].location != NSNotFound ||
        [theme rangeOfString:@"staging.konotor.com"].location != NSNotFound){
        return HLEVENTS_BULK_EVENTS_DEBUG_URL;
    }
    return HLEVENTS_BULK_EVENTS_URL;
#endif
}

-(void)startEventsUploadTimer{
    if([[FDReachabilityManager sharedInstance] isReachable]){
        if(![self.pollingTimer isValid] && [self.eventsArray count]){
            self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(getEventsAndUpload)
                                                           userInfo:nil repeats:YES];
        }
    }
}

-(void)cancelEventsUploadTimer{
    if([self.pollingTimer isValid]){
        [self.pollingTimer invalidate];
    }
}

- (NSString*)returnEventLibraryPath {
    return [[FDUtilities returnLibraryPathForDir:HLEVENT_DIR_PATH] stringByAppendingPathComponent:HLEVENT_FILE_NAME];
}

+ (HLEvent *) submitEvent:(NSString *)eventName
                   ofType:(NSString *)eventType
                withBlock:(void(^)(HLEvent *event))builderBlock{
    HLEvent *event = [[HLEvent alloc] initWithEventName:eventName];
    [event propKey:HLEVENT_PARAM_TYPE andVal:HLEVENT_PARAM_TYPE];
    builderBlock(event);
    NSDictionary *eventDictionary = [event toEventDictionary:[HLEventManager getUserSessionId]];
    if(eventDictionary){
        [[HLEventManager sharedInstance] updateFileWithEvent:eventDictionary];
    }
    return event;
}

+ (HLEvent *) submitSDKEvent:(NSString *)eventName withBlock:(void(^)(HLEvent *event))builderBlock{
    return [HLEventManager submitEvent:eventName
            //All events right now are generated from SDK. Add user events when we expose API for events.
                                ofType:HLEVENT_TYPE_SDK
                             withBlock:builderBlock];
}

- (void) getOldEvents {
    NSData *data = [NSData dataWithContentsOfFile:[self returnEventLibraryPath]];
    NSArray *eventsArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self.eventsArray addObjectsFromArray:eventsArray];
}

- (void) updateFileWithEvent:(NSDictionary *) eventDict{
    dispatch_async(self.serialQueue, ^{
        
        [self.eventsArray addObject:eventDict];
        [self writeEventsToPList];
    });
}

- (void) writeEventsToPList{
    NSMutableArray *eventsArrayCopy = [NSMutableArray arrayWithArray:[self.eventsArray copy]];
    if (![NSKeyedArchiver archiveRootObject:eventsArrayCopy toFile:self.plistURL]) { // NOTE:
        FDLog(@"%@ unable to create events data", self);
    }
}

- (void) getEventsAndUpload{
    
    dispatch_async(self.serialQueue, ^{
        NSData *data = [NSData dataWithContentsOfFile:[self returnEventLibraryPath]]; //self.url
        NSArray *eventsArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSMutableArray *events = [NSMutableArray array];
    
        for(int j = 0; j < [eventsArray count]; j += HLEVENTS_BATCH_SIZE) {
        
            NSArray *subarray = [eventsArray subarrayWithRange:NSMakeRange(j, MIN(HLEVENTS_BATCH_SIZE, [eventsArray count] - j))];
            for (int i=0; i<[subarray count]; i++) {
                [events addObject:eventsArray[i]];
            }
            [self uploadUserEvents:events];
        }
        [self cancelEventsUploadTimer];
    });
}
     
- (void) clearEvents{
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self returnEventLibraryPath]];
    NSError *error;
    if(exists) {
        [[NSFileManager defaultManager]removeItemAtPath:[self returnEventLibraryPath]  error:&error];
    }
    else{
        FDLog(@"File not exists!!!");
    }
}

+(NSString *)getUserSessionId{
    NSString *sessionId =[NSString stringWithFormat:@"%@_%@", [HLEventManager sharedInstance].sessionID, [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000] stringValue]];
    return sessionId;
}

+ (NSDictionary *) getUserProperties{
    //get all user properties and forward them to
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *userAlias = [FDUtilities getUserAlias];
    if(!userAlias){userAlias=@"Undefined_Alias";}
    NSString *appAlias = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *appName = [FDUtilities appName];
    NSDictionary *deviceInfo = [FDUtilities deviceInfoProperties];
    NSDictionary *user = @{ @"userId":userAlias,
                            @"tracker":[FDUtilities getTracker],
                            @"groupId":appAlias,
                            @"appName":appName,
                            @"properties":deviceInfo};
    return user;
}

- (void) uploadUserEvents :(NSMutableArray *)events{
    
    if(![FDUtilities getUserAlias]){
        return;
    }
    FDSecureStore *store = [FDSecureStore sharedInstance];

    NSString *eventURL = [NSString stringWithFormat:@"%@/%@",[self getEventsURL],[store objectForKey:HOTLINE_DEFAULTS_APP_ID]];

    NSMutableArray *tempEventsArray = [[NSMutableArray alloc] initWithArray:self.eventsArray];
    
    for(NSDictionary *event in events){
        for(NSDictionary *eventCompare in tempEventsArray){
            if ([eventCompare[@"_eventTimestamp"] compare:event[@"_eventTimestamp"]] == NSOrderedSame){
                [self.eventsArray removeObject:eventCompare];
            }
        }
    }
    
    NSError *error;
    NSData * postData = [NSJSONSerialization dataWithJSONObject:events options:0 error:&error];
    HLAPIClient *apiClient = [HLAPIClient sharedInstance];
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:eventURL] andMethod:HTTP_METHOD_POST];
    request.HTTPBody = postData;
    dispatch_async(self.serialQueue, ^{
        [apiClient request:request withHandler:^(FDResponseInfo *responseInfo,NSError *error) {
        if (!error) {
            
            //add serial queue code block for serial execution
            if([responseInfo isDict]) {
                NSMutableArray *eventsToRetry = [[NSMutableArray alloc] init];
                NSArray *eventsResponse = [responseInfo responseAsDictionary][@"result"];
                for (int i=0; i<[eventsResponse count]; i++) {
                    NSInteger status = [[eventsResponse objectAtIndex:i][@"status"] intValue];
                    if(!isSuccessRespCode(status) && canRetryResponseCode(status)){
                        [eventsToRetry addObject:[events objectAtIndex:i]];
                    }
                }
                [self writeArrayEvents:eventsToRetry];
            }
        }else{
            if(error.code == HLEVENTS_HTTP_RESPONSE_CODE_NOT_SUPPORTED){
                [self clearEvents];
            }
            else if(isRetriableHttpError(error.code)){//validation error
                [self writeArrayEvents:events];
            }
        }
        }];
    });
}

- (void) writeArrayEvents :(NSMutableArray *)events{
    if(![events count]){
        [self writeEventsToPList];
        return;
    }
    for(NSDictionary *event in events){
        [self updateFileWithEvent:event];
    }
}

@end
