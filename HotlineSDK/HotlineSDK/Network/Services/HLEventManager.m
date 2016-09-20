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

- (instancetype)init
{
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
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *baseURLString = [store objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    
    NSString *domain = [[baseURLString stringByReplacingOccurrencesOfString:@"app" withString:@"events"] stringByAppendingPathComponent:BULK_EVENT_DIR_PATH];
    return [NSString stringWithFormat:HOTLINE_USER_DOMAIN,domain];
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
    //check for path, if available return else create path
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:HLEVENT_DIR_PATH];
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
//    NSData *data = [NSData dataWithContentsOfFile:[self returnEventLibraryPath]];
//    [self.eventsArray addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    return [filePath stringByAppendingPathComponent:HLEVENT_FILE_NAME];
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
    });
}
     
- (void) clearEventFile{
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
#ifdef DEBUG
    NSString *eventURL = [NSString stringWithFormat:@"%@%@",HLEVENTS_BULK_BASE_URL,[store objectForKey:HOTLINE_DEFAULTS_APP_ID]];
#else
    NSString *eventURL = [NSString stringWithFormat:@"%@/%@/",[self getEventsURL],[store objectForKey:HOTLINE_DEFAULTS_APP_ID]];
#endif
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
    HLServiceRequest *request = [[HLServiceRequest alloc]initWithBaseURL:[NSURL URLWithString:eventURL]];
    request.HTTPBody = postData;
    request.HTTPMethod = HTTP_METHOD_POST;
    dispatch_async(self.serialQueue, ^{
        [apiClient request:request withHandler:^(FDResponseInfo *responseInfo,NSError *error) {
        if (!error) {
            //add serial queue code block for serial execution
            if([responseInfo isDict]) {
                NSMutableArray *incompleteEvents = [[NSMutableArray alloc] init];
                NSArray *eventsResponse = [responseInfo responseAsDictionary][@"result"];
                for (int i=0; i<[eventsResponse count]; i++) {
                        
                    if(!(([[eventsResponse objectAtIndex:i][@"status"] intValue] == HLEVENTS_VALIDATION_FAILED) ||
                        ([[eventsResponse objectAtIndex:i][@"status"] intValue] == HLEVENTS_UNSUPPORTED_MEDIA_TYPE) ||
                        ([[eventsResponse objectAtIndex:i][@"status"] intValue] == HLEVENTS_INVALID_REQUEST_FORMAT) ||
                        ([[eventsResponse objectAtIndex:i][@"status"] intValue] == HLEVENTS_REQUEST_ACCEPTED))){
                            
                        [incompleteEvents addObject:[events objectAtIndex:i]];
                    }
                }
                [self writeArrayEvents:incompleteEvents];
            }
        }else{
            if((error.code != 422) || (error.code != 415)){//validation error
                    
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
