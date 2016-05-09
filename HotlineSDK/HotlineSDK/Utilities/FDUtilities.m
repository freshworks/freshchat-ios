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
#import "HLLocalization.h"
#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>

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

+(BOOL)isUserRegistered{
    return [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_IS_USER_REGISTERED];
}

+(NSString *) getUUIDLookupKey{
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSString *appID = [store objectForKey:HOTLINE_DEFAULTS_APP_ID];
    NSString *uuIdLookupKey = [NSString stringWithFormat:@"%@-%@", appID ,HOTLINE_DEFAULTS_DEVICE_UUID ];
    return uuIdLookupKey;
}


/* This function gets the user-alias from persisted secure store for new customers (Hotline),
 it also migrates the key from [Konotor SDK to Hotline SDK] if exists */
+(NSString *)getUserAlias{
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

+(NSString *)generateUserAlias{
    NSString *userAlias;
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
            FDLog(@"New Hotline User");
        }
        [FDUtilities storeUserAlias:userAlias];
    }
    else {
        FDLog(@"Existing Konotor user");
    }
    userAlias = [persistedStore objectForKey:uuIdLookupKey];
    return userAlias;
}

+(void)storeUserAlias:(NSString *)alias{
    FDSecureStore *persistedStore = [FDSecureStore persistedStoreInstance];
    [persistedStore setObject:alias forKey:[FDUtilities getUUIDLookupKey]];
}



+(NSString *) getKeyForObject:(NSObject *) object {
    if(object){
        return [NSString stringWithFormat:@"%lu" , (unsigned long)[object hash]];
    }
    return @"nil";
}

+(NSString *)getAdID{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *adId = [secureStore objectForKey:HOTLINE_DEFAULTS_ADID];
    if (!adId) {
        adId = [self setAdId];
    }
    return adId;
}

+(NSString *)setAdId{
    FDSecureStore *secureStore = [FDSecureStore sharedInstance];
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    [secureStore setObject:adId forKey:HOTLINE_DEFAULTS_ADID];
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
    [properties setValue:[device model] forKey:@"model"];
    
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

+(NSString *)getBaseURL{
    NSString *baseURL = [[FDSecureStore sharedInstance]objectForKey:HOTLINE_DEFAULTS_DOMAIN];
    return [NSString stringWithFormat:@"%@%@%@",@"https://",baseURL,@"/app/"];
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

+(void) PostNotificationWithName :(NSString *) notName withObject: (id) object{
    NSNotification* not=[NSNotification notificationWithName:notName object:object];
    [[NSNotificationCenter defaultCenter] postNotification:not];
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

+(NSString *)appName{
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    if (appName) {
        return appName;
    }else{
        return [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    }
}

static NSString *DEFAULT_LANG = @"en";
static NSString *DEFAULT_BUNDLE_NAME = @"HLLocalizationPod";
static NSString *DEFAULT_LOCALIZATION_TABLE = @"HLLocalizable";

+(NSString *)localize:(NSString *)key{
    
    NSString *bundleName = [[FDSecureStore sharedInstance]objectForKey:HOTLINE_DEFAULTS_STRINGS_BUNDLE];
    
    NSBundle *bundle = [self bundleWithName:bundleName ? bundleName : DEFAULT_BUNDLE_NAME andLang:[self getPreferredLang]];
    
    NSString *localizedString = NSLocalizedStringWithDefaultValue(key, DEFAULT_LOCALIZATION_TABLE, bundle, nil, nil);
    
    BOOL isLocalized = [self isKey:key localized:localizedString];
    
    if (!isLocalized) {
        NSBundle *projectLevelBundle = [self bundleWithName:bundleName andLang:DEFAULT_LANG];
        
        localizedString = NSLocalizedStringWithDefaultValue(key, DEFAULT_LOCALIZATION_TABLE, projectLevelBundle, nil, nil);
        
        isLocalized = [self isKey:key localized:localizedString];
        
        if (!isLocalized) {
            NSBundle *podBundle = [self bundleWithName:DEFAULT_BUNDLE_NAME andLang:DEFAULT_LANG];
            
            localizedString = NSLocalizedStringWithDefaultValue(key, DEFAULT_LOCALIZATION_TABLE, podBundle, nil, nil);
        }
        
    }
    return localizedString;
}

+(NSBundle *)bundleWithName:(NSString *)bundleName andLang:(NSString *)langCode{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:bundleName ofType:@"bundle"]];
    return [NSBundle bundleWithPath:[bundle pathForResource:langCode ofType:@"lproj"]];
}

+(NSString *)getPreferredLang{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0]; //sample "en-US"
    NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:language];
    return [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"]; //sample "en"
}

+(BOOL)isKey:(NSString *)key localized:(NSString *)value{
    return ![key isEqualToString:value];
}

@end