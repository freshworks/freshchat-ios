//
//  FDUtilities.m
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <asl.h>
#import "KonotorUser.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "HLTheme.h"
#import "FDStringUtil.h"
#import "HLLocalization.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import "FDPlistManager.h"
#import "HLCoreServices.h"
#import "FDLocalNotification.h"
#import "HLUserDefaults.h"
#import "HLConstants.h"
#import "HLLocalization.h"

#define EXTRA_SECURE_STRING @"fd206a6b-7363-4a20-9fa9-62deca85b6cd"

@implementation FDUtilities

#pragma mark - General Utitlites

+(NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath      = [[NSBundle bundleForClass:[self class]] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"FreshdeskSDKResources.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

+(UIImage *)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+(NSString *) getTracker{
    return [NSString stringWithFormat:@"hl_ios_%@",[Hotline SDKVersion]];
}

+(BOOL)isUserRegistered{
    NSString *userAlias = [self currentUserAlias];
    return ([[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED] &&
            (userAlias && userAlias.length > 0));
}

+(NSString *) getUUIDLookupKey{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *uuIdLookupKey = [NSString stringWithFormat:@"%@-%@", appID ,HOTLINE_DEFAULTS_DEVICE_UUID ];
    return uuIdLookupKey;
}

/* This function gets the user-alias from persisted secure store for new customers (Hotline),
 it also migrates the key from [Konotor SDK to Hotline SDK] if exists */
+(NSString *)currentUserAlias{
    NSString* userAlias = [[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    if(userAlias){
        return userAlias;
    }
    return @""; //return empty to prevent null
}

+(NSString *)getUserAliasWithCreate{
    NSString* userAlias = [[FDSecureStore sharedInstance] objectForKey:HOTLINE_DEFAULTS_DEVICE_UUID];
    if(userAlias){
        return userAlias;
    }
    else {
        userAlias = [FDUtilities generateUserAlias];
        if(userAlias){
            [[FDSecureStore sharedInstance] setObject:userAlias forKey:HOTLINE_DEFAULTS_DEVICE_UUID];
        }
    }
    return userAlias;
}

+(UIViewController*) topMostController {
    UIViewController *topController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

+(NSString *)generateUserAlias{
    NSString *userAlias;
    //TODO: This logic is too nested. Need to remove this - Rex
    if(![[FDSecureStore sharedInstance] checkItemWithKey:HOTLINE_DEFAULTS_APP_ID]){
        FDLog(@"WARNING : getUserAlias Called before init");
        return nil; // safety check for functions called before init.
    }
    FDSecureStore *persistedStore = [FDSecureStore persistedStoreInstance];
    NSString *uuIdLookupKey = [FDUtilities getUUIDLookupKey];
    BOOL isExistingUser = [persistedStore checkItemWithKey:uuIdLookupKey];
    if (!isExistingUser) {
        KonotorUser *user = [KonotorUser getUser];
        if (user.userAlias) {
            userAlias = user.userAlias;
            FDLog(@"Migrating Konotor User");
        }
        else {
            userAlias = [FDStringUtil generateUUID];
        }
        [FDUtilities storeUserAlias:userAlias];
    }
    userAlias = [persistedStore objectForKey:uuIdLookupKey];
    return userAlias;
}

+(void)storeUserAlias:(NSString *)alias{
    FDSecureStore *persistedStore = [FDSecureStore persistedStoreInstance];
    [persistedStore setObject:alias forKey:[FDUtilities getUUIDLookupKey]];
}

+ (NSString *) returnLibraryPathForDir : (NSString *) directory{
    
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:directory];
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
    return filePath;
}

+(NSString *) getKeyForObject:(NSObject *) object {
    if(object){
        return [NSString stringWithFormat:@"%lu" , (unsigned long)[object hash]];
    }
    return @"nil";
}

+(NSString *)getAdID{
    NSString *adId = @"";
    Class advertisingClass = NSClassFromString(@"ASIdentifierManager");
    if (advertisingClass){
        adId = [[[advertisingClass performSelector:@selector(sharedManager)]
                                    performSelector:@selector(advertisingIdentifier)]
                                    performSelector: @selector(UUIDString)];
    }
    return  adId;
}

+(NSString *)generateOfflineMessageAlias{
    NSString *randomString = [FDStringUtil generateUUID];
    return [NSString stringWithFormat:@"temp-%@", randomString];
}


+(NSDictionary *)deviceInfoProperties{
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    UIDevice *device = [UIDevice currentDevice];
    
    [properties setValue:[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
    [properties setValue:@"Apple" forKey:@"brand"];
    
    [properties setValue:@"Apple" forKey:@"manufacturer"];
    [properties setValue:@"iPhone OS" forKey:@"os"];
    [properties setValue:[device systemVersion] forKey:@"os_version"];
    [properties setValue:[FDUtilities deviceModelName] forKey:@"model"];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    [properties setValue:[NSNumber numberWithInt:(int)size.height] forKey:@"screen_height"];
    [properties setValue:[NSNumber numberWithInt:(int)size.width] forKey:@"screen_width"];
    
    return [NSDictionary dictionaryWithDictionary:properties];
}

static NSInteger networkIndicator = 0;

+(void)setActivityIndicator:(BOOL)isVisible{
    if (isVisible){
        networkIndicator++;
    }
    else{
        if(networkIndicator > 0){
            networkIndicator--;
        }
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(networkIndicator > 0)];
}

+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule{
    NSString *pStr = [NSString stringWithFormat:@"%@:%@",pModule,alertviewstring ];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: pModule
                          message: pStr
                          delegate: nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Ok",
                          nil];
    [alert show];
    return;
}

+(NSString *) typicalRepliesMsgForTime :(NSInteger)timeInSec{
    float minutes = timeInSec/60;
    if (minutes < 1) {
        return HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_MIN);
    }else if (minutes < 55) {
        int min;
        if (minutes < 10) {
            // If < 10 minutes
            min = (int) ceil(minutes);
        } else {
            // If < 55 minutes, round off to factor of 5
            min = (int) ceil(minutes / 5) * 5;
        }
        return [NSString stringWithFormat: @"%@ %d %@",LOC_TYPICALLY_REPLIES_WITHIN_MIN, min,LOC_PLACEHOLDER_MINS];
    } else if (minutes < 60) {
        return HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_HOUR);
    } else if (minutes < 120) {
        return HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_TWO_HOUR);
    } else {
        return HLLocalizedString(LOC_TYPICALLY_REPLIES_WITHIN_FEW_HOURS);
    }
}

+ (NSString*)convertIntoMD5 :(NSString *) str
{
    // Create pointer to the string as UTF8
    const char *ptr = [str UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[16];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr,(unsigned int) strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:16 * 2];
    for(int i = 0; i < 16; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

+(BOOL)isPoweredByHidden{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    
    NSString *secretKey = [[HLTheme sharedInstance] getFooterSecretKey];
    if (!secretKey) return NO;
    
    NSString* myString = [NSString stringWithFormat:@"%@%@%@",[store objectForKey:HOTLINE_DEFAULTS_APP_ID],EXTRA_SECURE_STRING,[store objectForKey:HOTLINE_DEFAULTS_APP_KEY]];
    
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[myString length]];
    
    [myString enumerateSubstringsInRange:NSMakeRange(0,[myString length])
                                 options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                              usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                  [reversedString appendString:substring];
                              }];
    
    return ([[self convertIntoMD5:reversedString] isEqualToString:secretKey]) ? YES : NO;
}

+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key{
    NSNumber *lastUpdateTime = [[FDSecureStore sharedInstance] objectForKey:key];
    if (lastUpdateTime == nil) lastUpdateTime = @0;
    return lastUpdateTime;
}

+(BOOL) isValidPropKey: (NSString *) str {
    return str && [str length] <=32 && [FDStringUtil isValidUserPropName:str];
}

+(BOOL) isValidPropValue: (NSString *) str {
    return str && [str length] <= 256;
}

+(NSDictionary*) filterValidUserPropEntries :(NSDictionary*) userDict{
    NSMutableDictionary *userProperties = [[NSMutableDictionary alloc] init];
    if(userDict){
        for(id key in userDict){
            if([FDUtilities isValidPropKey:key]){
                NSObject *valueObj = [userDict objectForKey:key];
                if([valueObj isKindOfClass:[NSString class]]) {
                    NSString *value = (NSString *) valueObj;
                    if([FDUtilities isValidPropValue:value]){
                        [userProperties setObject:value forKey:key];
                    }
                    else {
                        ALog(@"Invalid user property value %@ - %@ : <validation error>", key, valueObj);
                    }
                } else {
                    ALog(@"Invalid user property value. Not a NSString. %@ - %@ : <validation error>", key, valueObj);
                }
            }
            else{
                ALog(@"Invalid user property  key %@ : <validation error>", key);
            }
        }
    }
    return userProperties;
}

+(NSString *)appName{
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    if (appName) {
        return appName;
    }else{
        return [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    }
}

+(NSArray *) convertTagsArrayToLowerCase : (NSArray *)tags{
    NSArray *noEmptyTags = [tags filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"length > 0"]];
    return [noEmptyTags valueForKey:@"lowercaseString"];
}

+(BOOL) canMakeSessionCall {
    if(![HLUserDefaults getObjectForKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME]){
        return  true;
    }
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:[HLUserDefaults getObjectForKey:FRESHCHAT_DEFAULTS_SESSION_UPDATED_TIME]];
    FDLog(@"Time interval b/w dates %f", interval);
    if(interval > SESSION_UPDATE_INTERVAL){
        return true;
    }
    return false;
}

+(BOOL) canMakeDAUCall {
    NSDate *currentdate = [NSDate date];
    NSDate *lastFetchDate = [NSDate dateWithTimeIntervalSince1970:[[[FDSecureStore sharedInstance] objectForKey: HOTLINE_DEFAULTS_DAU_LAST_UPDATED_INTERVAL_TIME] doubleValue]/1000];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents* currentComp = [calendar components:unitFlags fromDate:currentdate];
    NSDateComponents* lastFetchComp = [calendar components:unitFlags fromDate:lastFetchDate];
    NSComparisonResult result;
    result = [currentdate compare:lastFetchDate];
    if(result == NSOrderedDescending){//date comparision, current should be greater than
        if (!([currentComp day] == [lastFetchComp day] && [currentComp month] == [lastFetchComp month] && [currentComp year]  == [lastFetchComp year])){
            return true;
        }
    }
    return 0;
}

+(BOOL) containsHTMLContent: (NSString *)content {
    if ((([FDUtilities containsString:content andTarget:@"<b>"]) && ([FDUtilities containsString:content andTarget:@"</b>"]))
    || (([FDUtilities containsString:content andTarget:@"<i>"]) && ([FDUtilities containsString:content andTarget:@"</i>"]))
    || (([FDUtilities containsString:content andTarget:@"<u>"]) && ([FDUtilities containsString:content andTarget:@"</u>"]))
    || (([FDUtilities containsString:content andTarget:@"<a>"]) && ([FDUtilities containsString:content andTarget:@"</a>"]))
    || (([FDUtilities containsString:content andTarget:@"<h1>"]) && ([FDUtilities containsString:content andTarget:@"</h1>"]))
    || (([FDUtilities containsString:content andTarget:@"<h2>"]) && ([FDUtilities containsString:content andTarget:@"</h2>"]))
    || (([FDUtilities containsString:content andTarget:@"<h3>"]) && ([FDUtilities containsString:content andTarget:@"</h3>"]))
    || (([FDUtilities containsString:content andTarget:@"<h4>"]) && ([FDUtilities containsString:content andTarget:@"</h4>"]))
    || (([FDUtilities containsString:content andTarget:@"<h5>"]) && ([FDUtilities containsString:content andTarget:@"</h5>"]))
    || (([FDUtilities containsString:content andTarget:@"<h6>"]) && ([FDUtilities containsString:content andTarget:@"</h6>"]))) {
        return true;
    }
    return false;
}

+(BOOL) containsString: (NSString *)original andTarget:(NSString *)target {
    if([original rangeOfString:target].location == NSNotFound) {
        return false;
    }
    return true;
}

+(NSString *) appendFirstName :(NSString *)firstName withLastName:(NSString *) lastName{
    
    return ([@[firstName, @" ", lastName] componentsJoinedByString:@""]);
}

+(NSString*)deviceModelName{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machineName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSDictionary *commonNamesDictionary =
    @{
      @"i386":     @"iOS Simulator",
      @"x86_64":   @"iOS Simulator",
      
      @"iPhone1,1":    @"iPhone",
      @"iPhone1,2":    @"iPhone 3G",
      @"iPhone2,1":    @"iPhone 3GS",
      @"iPhone3,1":    @"iPhone 4",
      @"iPhone3,2":    @"iPhone 4(Rev A)",
      @"iPhone3,3":    @"iPhone 4(CDMA)",
      @"iPhone4,1":    @"iPhone 4S",
      @"iPhone5,1":    @"iPhone 5(GSM)",
      @"iPhone5,2":    @"iPhone 5(GSM+CDMA)",
      @"iPhone5,3":    @"iPhone 5c(GSM)",
      @"iPhone5,4":    @"iPhone 5c(GSM+CDMA)",
      @"iPhone6,1":    @"iPhone 5s(GSM)",
      @"iPhone6,2":    @"iPhone 5s(GSM+CDMA)",
      @"iPhone7,1":    @"iPhone 6 Plus",
      @"iPhone7,2":    @"iPhone 6",
      @"iPhone8,1":    @"iPhone 6s",
      @"iPhone8,2":    @"iPhone 6s Plus",
      @"iPhone8,4":    @"iPhone SE",
      @"iPhone9,1":    @"iPhone 7",
      @"iPhone9,3":    @"iPhone 7",
      @"iPhone9,2":    @"iPhone 7 Plus",
      @"iPhone9,4":    @"iPhone 7 Plus",
      
      
      @"iPad1,1":  @"iPad",
      @"iPad2,1":  @"iPad 2(WiFi)",
      @"iPad2,2":  @"iPad 2(GSM)",
      @"iPad2,3":  @"iPad 2(CDMA)",
      @"iPad2,4":  @"iPad 2(WiFi Rev A)",
      @"iPad2,5":  @"iPad Mini 1st Gen(WiFi)",
      @"iPad2,6":  @"iPad Mini 1st Gen(GSM)",
      @"iPad2,7":  @"iPad Mini 1st Gen(GSM+CDMA)",
      @"iPad3,1":  @"iPad 3(WiFi)",
      @"iPad3,2":  @"iPad 3(GSM+CDMA)",
      @"iPad3,3":  @"iPad 3(GSM)",
      @"iPad3,4":  @"iPad 4(WiFi)",
      @"iPad3,5":  @"iPad 4(GSM)",
      @"iPad3,6":  @"iPad 4(GSM+CDMA)",
      @"iPad4,1":  @"iPad Air(WiFi)",
      @"iPad4,2":  @"iPad Air(WiFi+Cellular)",
      @"iPad4,3":  @"iPad Air(WiFi+LTE - China)",
      @"iPad4,4":  @"iPad Mini 2(WiFi)",
      @"iPad4,5":  @"iPad Mini 2(WiFi+Cellular)",
      @"iPad4,6":  @"iPad Mini 2(WiFi+Cellular - China)",
      @"iPad4,7":  @"iPad Mini 3(WiFi)",
      @"iPad4,8":  @"iPad Mini 3(WiFi+Cellular)",
      @"iPad4,9":  @"iPad Mini 3(WiFi+Cellular - China)",
      @"iPad5,1":  @"iPad mini 4",
      @"iPad5,2":  @"iPad mini 4",
      @"iPad5,3":  @"iPad Air 2(WiFi)",
      @"iPad5,4":  @"iPad Air 2(WiFi+Cellular)",
      @"iPad6,7":  @"iPad Pro (12.9 inch)",
      @"iPad6,8":  @"iPad Pro (12.9 inch)",
      @"iPad6,3":  @"iPad Pro (9.7 inch)",
      @"iPad6,4":  @"iPad Pro (9.7 inch)",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      @"iPod7,1":  @"iPod 6th Gen",
      
      };
    NSString *deviceName = commonNamesDictionary[machineName];
    if (!deviceName) { deviceName = machineName; }
    return deviceName;
}

+(BOOL)isiOS10{
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0");
}

+(void)initiatePendingTasks{
    [FDLocalNotification post:HOTLINE_NOTIFICATION_PERFORM_PENDING_TASKS];
}

+(BOOL)hasInitConfig{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSManagedObjectContext *ctx = [KonotorDataManager sharedInstance].mainObjectContext;
    return [store checkItemWithKey:HOTLINE_DEFAULTS_APP_ID] && [store checkItemWithKey:HOTLINE_DEFAULTS_APP_KEY] && ctx != nil;
}

+(void)unreadCountInternalHandler:(void (^)(NSInteger count))completion{
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannelsWithCompletion:^(NSArray *channelInfos, NSError *error) {
        NSInteger result = 0;
        for (HLChannelInfo *channel in channelInfos) {
            if (channel.unreadMessages > 0) result = result + channel.unreadMessages;
        }
        completion(result);
    }];
}

@end
