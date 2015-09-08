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
    
    /*void *addr[2];
     int nframes = backtrace(addr, sizeof(addr)/sizeof(*addr));
     if (nframes > 1)
     {
     char **syms = backtrace_symbols(addr, nframes);
     //NSLog(@"caller: %s and set value to %d", __func__, syms[1],networkIndicator);
     free(syms);
     }
     else
     {
     NSLog(@"%s: *** Failed to generate backtrace.", __func__);
     }*/
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(networkIndicator > 0)];
}

+ (KonotorNetworkUtil *) getHTTPClient

{
    
    if(pKonotorSingletonClient==nil){
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            pKonotorSingletonClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:[KonotorUtil GetBaseURL]]];
        });
    }
    return pKonotorSingletonClient;
}

+(BOOL) isSuccessResponseCode: (NSURLResponse *) response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int statusCode = (int)[httpResponse statusCode];
    return !(statusCode >= 400);
}
- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        //NSLog(@"failed to init");
        return nil;
    }
    [self registerHTTPOperationClass:[AFKonotorJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setParameterEncoding:AFKonotorJSONParameterEncoding];
    
    //NSLog(@"success setting headers");
    return self;
}

+(NSString *) DownloadFile :(NSString *) httpPath
{
    
    NSURL *url = [NSURL URLWithString:httpPath];
    
    NSString *lastComponent = [url lastPathComponent];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:httpPath]];
    AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request] ;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *returnPath = [paths objectAtIndex:0];
    
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:lastComponent];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id responseObject)
     {
         NSString *pNot = [httpPath stringByAppendingString:@"_downloaded"];
         [KonotorUtil PostNotificationWithName:pNot withObject:path];
         ////NSLog(@"Successfully downloaded file to %@", path);
     }
     
                                     failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error)
     {
         NSString *pNot = [path stringByAppendingString:@"_failed"];
         [KonotorUtil PostNotificationWithName:pNot withObject:nil];
         
         //NSLog(@"Error: %@", error);
     }];
    
    [operation start];
    
    return returnPath;
}





+(NSURL *) getRedirectURLWithString:(NSString *) url
{
    NSURL *originalUrl=[NSURL URLWithString:url];
    return [KonotorNetworkUtil getRedirectURLWithURL:originalUrl];
}

+(NSURL *) getRedirectURLWithURL:(NSURL *) url
{
    NSURL *originalUrl=url;
    NSData *data=nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:originalUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    NSURLResponse *response;
    NSError *error;
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSURL *LastURL=[response URL];
    return LastURL;
}
@end


@implementation KonotorUtil

+(NSString *) GetBaseURL
{
    //return @"http://www.certpal.com/app/";
    //return @"https://app.konotor.com/app/";
    //return @"http://app.konotor.com/app/";
    //return @"https://sandbox.target.konotor.com/app/";
    return KONOTORURL;

}

+ (NSString*)base64forData:(NSData*)theData {
    
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
}
+(NSString*) TruncateString:(NSString *)origString withClipLength:(int) clipLength
{
    if(!origString)
        return  nil;
    
    if([origString length]>clipLength )
    {
        NSString *truncatedString = [NSString stringWithFormat:@"\"%@...\"",[origString substringToIndex:clipLength]];
        return truncatedString;
    }
    
    return origString;
}
/*+(NSString *) GetSHAHashForKey:(NSString *)hashkey withSecret:(NSString *)secret
{
    
    NSString *key = secret;
    NSString *data = hashkey;
    
    
    
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    
    
    NSString *hash=[HMAC description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
    
    return hash;
    
    
    
}*/

+ (NSString*) reversingName:(NSString *)myNameText
{
    int len = (int)[myNameText length];
    NSMutableString *reverseName = [[NSMutableString alloc] initWithCapacity:len];
    for(int i=(len-1);i>=0;i--)
    {
        [reverseName appendString:[NSString stringWithFormat:@"%c",[myNameText characterAtIndex:i]]];
    }
    return reverseName;
}

/*+(NSString *) ReturnURIForObject :( NSManagedObject *) object
{
    if(object)
    {
        NSURL *moURI = [[object objectID] URIRepresentation];
        
        if(moURI)
        {
            return [moURI absoluteString];
        }
    }
    
    return nil;
}*/



AFKonotorHTTPClient *pKonotorSingle = nil;

+(AFKonotorHTTPClient *) SingletonClient
{
    
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




+(UIBackgroundTaskIdentifier) beginBackgroundExecutionWithExpirationHandler:(SEL)expirationHandler withParameters:(id)parameter forObject:(id) object
{
    
    
    UIApplication  *app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^
     {
         [object performSelector:expirationHandler withObject:parameter];
         
         [app endBackgroundTask:bgTask];
         bgTask = UIBackgroundTaskInvalid;
     }];
    
    return bgTask;
}

+(void) EndBackgroundExecutionForTask:(UIBackgroundTaskIdentifier) bgtask
{
    UIApplication  *app = [UIApplication sharedApplication];
    [app endBackgroundTask:bgtask];
    bgtask  = UIBackgroundTaskInvalid;
}

#define ENABLE_ALERT_VIEW 0
+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule
{
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

+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object
{
    NSNotification* not=[NSNotification notificationWithName:notName object:object];
    [[NSNotificationCenter defaultCenter] postNotification:not];
}

+ (NSDictionary *)deviceInfoProperties
{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    UIDevice *device = [UIDevice currentDevice];
   
    [properties setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
    [properties setValue:@"Apple" forKey:@"brand"];

    [properties setValue:@"Apple" forKey:@"manufacturer"];
    [properties setValue:[device systemName] forKey:@"os"];
    [properties setValue:[device systemVersion] forKey:@"os_version"];
    [properties setValue:[device model] forKey:@"model"];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    [properties setValue:[NSNumber numberWithInt:(int)size.height] forKey:@"screen_height"];
    [properties setValue:[NSNumber numberWithInt:(int)size.width] forKey:@"screen_width"];
    
    
        
    return [NSDictionary dictionaryWithDictionary:properties];
}

@end
