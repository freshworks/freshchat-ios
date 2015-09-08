//
//  FDDeviceInfo.m
//  FreshdeskSDK
//
//  Created by Aravinth on 12/08/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDDeviceInfo.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "FDReachability.h"
#import <sys/utsname.h>
#import "FDMacros.h"
#import "FDConstants.h"
#import "FDSecureStore.h"

@implementation FDDeviceInfo

#pragma mark - Device Information

+(NSString *)batteryLevel {
    float batteryLevel = [[UIDevice currentDevice]batteryLevel];
    FDLog(@"battery level %f",batteryLevel);
    if (batteryLevel>=0) {
        return [NSString stringWithFormat:@"%0.2f%%",100*[[UIDevice currentDevice] batteryLevel]];
    }else{
        return @"Unknown";
    }
}

+(NSString *)batteryState{
    UIDevice *device = [UIDevice currentDevice];
    [device setBatteryMonitoringEnabled:YES];
    NSInteger batteryStateValue = [device batteryState];
    NSString *batteryState;
    if (batteryStateValue == 1) { batteryState      = @"Unplugged and Discharging"; }
    else if (batteryStateValue == 2) { batteryState = @"Plugged and Charging"; }
    else if (batteryStateValue == 3) { batteryState = @"Plugged and Fully Charged"; }
    else { batteryState = @"Unknown"; }
    return batteryState;
}

+(NSString *)deviceMake{
    return @"Apple";
}

+ (NSString*)deviceModelName{
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
      @"iPad5,3":  @"iPad Air 2(WiFi)",
      @"iPad5,4":  @"iPad Air 2(WiFi+Cellular)",
      
      @"iPod1,1":  @"iPod 1st Gen",
      @"iPod2,1":  @"iPod 2nd Gen",
      @"iPod3,1":  @"iPod 3rd Gen",
      @"iPod4,1":  @"iPod 4th Gen",
      @"iPod5,1":  @"iPod 5th Gen",
      
      };
    NSString *deviceName = commonNamesDictionary[machineName];
    if (!deviceName) { deviceName = machineName; }
    return deviceName;
}

+(NSString *)screenOrientation{
    NSString *screenOrientation;
    NSInteger screenOrientationValue= [[UIApplication sharedApplication] statusBarOrientation];
    if (screenOrientationValue == 1) { screenOrientation      = @"Portrait"; }
    else if (screenOrientationValue == 2) { screenOrientation = @"Portrait Upside down"; }
    else if (screenOrientationValue == 3) { screenOrientation = @"Landscape Left"; }
    else if (screenOrientationValue == 4) { screenOrientation = @"Landscape Right"; }
    else if (screenOrientationValue == 5) { screenOrientation = @"Face up"; }
    else if (screenOrientationValue == 6) { screenOrientation = @"Face down"; }
    else { screenOrientation = @"Unknown"; }
    return screenOrientation;
}

+(NSString *)storageSpaceInternal {
    uint64_t totalSpace     = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error          = nil;
    NSString *spaceAvailable;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes     = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace                          = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace                      = [freeFileSystemSizeInBytes unsignedLongLongValue];
        spaceAvailable = [NSString stringWithFormat:@"%lluMB/%lluMB",((totalFreeSpace/1024ll)/1024ll),((totalSpace/1024ll)/1024ll)];
    } else {
        FDLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return spaceAvailable;
}

#pragma mark - App Information

+(NSString *)appIdentifier{ return [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"]; }

+(NSString *)appLocale{ return [[[NSBundle mainBundle]preferredLocalizations] lastObject]; }

+(NSString *)appName{
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    if (appName) {
        return appName;
    }else{
        return [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    }
}

+(NSString *)appVersion{
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    if ([appVersion length] == 0){
        appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        appVersion = [@"BundleVersion-" stringByAppendingString:appVersion];
    }

    return appVersion ? appVersion : @"Could not be determined";
}

+(NSString *)mobihelpSDKVersion {return  MOBIHELP_SDK_VERSION; }


#pragma mark - Mobile Network Information

+(NSString *)mobileNetworkCountryCode{ return [[[[CTTelephonyNetworkInfo alloc] init]subscriberCellularProvider]mobileCountryCode]; }

+(NSString *)mobileNetworkOperatorName{ return [[[[CTTelephonyNetworkInfo alloc] init]subscriberCellularProvider]mobileNetworkCode]; }

+(NSString *)mobileNetworkType{
    NSString* connectedNetworkType;
    FDReachability *reachability = [FDReachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    if(status == NotReachable){ connectedNetworkType = @"Unknown"; }
    else if (status == ReachableViaWiFi) { connectedNetworkType = @"WiFi"; }
    else if (status == ReachableViaWWAN) {
        if ([netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
            connectedNetworkType = @"GPRS";
        }
        if ([netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
            connectedNetworkType = @"EDGE";
        }
        if ([netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyWCDMA"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyHSDPA"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyHSUPA"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMA1x"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"] || [netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyeHRPD"]) {
            connectedNetworkType = @"3G";
        }
        if ([netinfo.currentRadioAccessTechnology isEqualToString:@"CTRadioAccessTechnologyLTE"]) {
            connectedNetworkType = @"LTE";
        }
        [NSNotificationCenter.defaultCenter addObserverForName:CTRadioAccessTechnologyDidChangeNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:^(NSNotification *note)
         {
         }];
    }
    return connectedNetworkType;
}

#pragma mark - OS Information

+(NSString *)osVersion{
    NSString *osVersion = [[UIDevice currentDevice]systemVersion];
    return osVersion ? osVersion : @"Could not be determined";
}

+(NSString *)osName{
    return @"iOS";
}
+(NSString *)osLocale{ return [[NSLocale currentLocale]localeIdentifier]; }
+(NSString *)osLanguage{ return [[NSLocale preferredLanguages] lastObject]; }

#pragma mark - Collect Info

+(NSDictionary *)collectDeviceAndAppInfo{
    
    NSMutableDictionary *info      = [[NSMutableDictionary alloc]init];
    NSString *appIdentifier        = [self appIdentifier];
    NSString *appLocale            = [self appLocale];
    NSString *appName              = [self appName];
    NSString *appVersion           = [self appVersion];
    NSString *SDKVersion           = [self mobihelpSDKVersion];
    NSString *batteryLevel         = [self batteryLevel];
    NSString *batteryState         = [self batteryState];
    NSString *deviceMake           = [self deviceMake];
    NSString *deviceModel          = [self deviceModelName];
    NSString *screenOrintation     = [self screenOrientation];
    NSString *storageSpaceInternal = [self storageSpaceInternal];
    NSString *networkCountryCode   = [self mobileNetworkCountryCode];
    NSString *networkOperatorName  = [self mobileNetworkOperatorName];
    NSString *networkType          = [self mobileNetworkType];
    NSString *osName               = [self osName];
    NSString *osLocale             = [self osLocale];
    NSString *osVersion            = [self osVersion];

    BOOL enhancedPrivacy = [[FDSecureStore sharedInstance] boolValueForKey:MOBIHELP_DEFAULTS_IS_ENHANCED_PRIVACY_ENABLED];
    if (enhancedPrivacy) {
        networkCountryCode = nil;
        networkOperatorName = nil;
        appLocale=nil;
    }
    
    if (appIdentifier) info[@"app_identifier"]                    = appIdentifier;
    if (appLocale) info[@"app_locale"]                            = appLocale;
    if (appName)info[@"app_name"]                                 = appName;
    if (appVersion) info[@"app_version"]                          = appVersion;
    if (SDKVersion) info[@"mobihelp_sdk_version"]                 = SDKVersion;
    if (batteryLevel) info[@"battery_level"]                      = batteryLevel;
    if (batteryState) info[@"battery_status"]                     = batteryState;
    if (deviceMake) info[@"device_make"]                          = deviceMake;
    if (deviceModel) info[@"device_model"]                        = deviceModel;
    if (screenOrintation) info[@"screen_orientation"]             = screenOrintation;
    if (storageSpaceInternal) info[@"storage_space_internal"]     = storageSpaceInternal;
    if (networkCountryCode) info[@"mobile_network_country_code"]  = networkCountryCode;
    if (networkOperatorName)info[@"mobile_network_operator_name"] = networkOperatorName;
    if (networkType)info[@"mobile_network_type"]                  = networkType;
    if (osName)info[@"os"]                                        = osName;
    if (osLocale)info[@"os_locale"]                               = osLocale;
    if (osVersion) info[@"os_version"]                            = osVersion;
    return info;
}

@end