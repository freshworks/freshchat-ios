//
//  KonotorUtil.m
//  Konotor
//
//  Created by Vignesh G on 16/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorUtil.h"

@implementation KonotorNetworkUtil

static KonotorNetworkUtil *pKonotorSingletonClient = nil;
static NSInteger networkIndicator = 0;

+ (void) SetNetworkActivityIndicator: (BOOL) isVisible
{
    if (isVisible)
        networkIndicator++;
    else
    {
        if(networkIndicator > 0)
            networkIndicator--;
        else
        {
            //NSLog(@"%@", @"Something wrong");
        }
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(networkIndicator > 0)];
}

+ (KonotorNetworkUtil *) getHTTPClient{
    if(pKonotorSingletonClient==nil){
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            pKonotorSingletonClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:[KonotorUtil GetBaseURL]]];
        });
    }
    return pKonotorSingletonClient;
}

+(BOOL) isSuccessResponseCode: (NSURLResponse *) response{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)[httpResponse statusCode];
    return !(statusCode >= 400);
}
- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    [self registerHTTPOperationClass:[AFKonotorJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setParameterEncoding:AFKonotorJSONParameterEncoding];
    
    return self;
}

+(NSString *) DownloadFile :(NSString *) httpPath{
    NSURL *url = [NSURL URLWithString:httpPath];
    
    NSString *lastComponent = [url lastPathComponent];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:httpPath]];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request] ;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *returnPath = [paths objectAtIndex:0];
    
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:lastComponent];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id responseObject){
         NSString *pNot = [httpPath stringByAppendingString:@"_downloaded"];
         [KonotorUtil PostNotificationWithName:pNot withObject:path];
     }
     
                                     failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
         NSString *pNot = [path stringByAppendingString:@"_failed"];
         [KonotorUtil PostNotificationWithName:pNot withObject:nil];
     }];
    
    [operation start];
    
    return returnPath;
}

@end


@implementation KonotorUtil

+(NSString *) GetBaseURL{
    return @"http://hline.pagekite.me/app/";
}

AFKonotorHTTPClient *pKonotorSingle = nil;

+(AFKonotorHTTPClient *) SingletonClient{
    
    if(!pKonotorSingle)
    {
        NSString *pBasePath = [KonotorUtil GetBaseURL];
       

        pKonotorSingle = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
        [pKonotorSingle setDefaultHeader:@"Accept" value:@"application/json"];
        [pKonotorSingle setDefaultHeader:@"Content-Type" value:@"application/json"];
        
        [pKonotorSingle setParameterEncoding:AFKonotorJSONParameterEncoding];
        
    }
    
    return pKonotorSingle;
    
    
}

+(UIBackgroundTaskIdentifier) beginBackgroundExecutionWithExpirationHandler:(SEL)expirationHandler withParameters:(id)parameter forObject:(id) object{
    UIApplication  *app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^
     {
         [object performSelector:expirationHandler withObject:parameter];
         
         [app endBackgroundTask:bgTask];
         bgTask = UIBackgroundTaskInvalid;
     }];
    
    return bgTask;
}

+(void) EndBackgroundExecutionForTask:(UIBackgroundTaskIdentifier) bgtask{
    UIApplication  *app = [UIApplication sharedApplication];
    [app endBackgroundTask:bgtask];
    bgtask  = UIBackgroundTaskInvalid;
}

#define ENABLE_ALERT_VIEW 0
+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule{
    return;
#ifdef ENABLE_ALERT_VIEW
    NSString *pStr = [NSString stringWithFormat:@"%@:%@",pModule,alertviewstring ];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: pModule
                          message: pStr
                          delegate: nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Ok",
                          nil];
    [alert show];
#else
    return;
#endif
}

+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object{
    NSNotification* not=[NSNotification notificationWithName:notName object:object];
    [[NSNotificationCenter defaultCenter] postNotification:not];
}

+ (NSDictionary *)deviceInfoProperties{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    UIDevice *device = [UIDevice currentDevice];
   
    [properties setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
    [properties setValue:@"Apple" forKey:@"brand"];

    [properties setValue:@"Apple" forKey:@"manufacturer"];
    [properties setValue:@"iPhone OS" forKey:@"os"];
    [properties setValue:[device systemVersion] forKey:@"os_version"];
    [properties setValue:[device model] forKey:@"model"];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    [properties setValue:[NSNumber numberWithInt:(int)size.height] forKey:@"screen_height"];
    [properties setValue:[NSNumber numberWithInt:(int)size.width] forKey:@"screen_width"];
    
    return [NSDictionary dictionaryWithDictionary:properties];
}

@end