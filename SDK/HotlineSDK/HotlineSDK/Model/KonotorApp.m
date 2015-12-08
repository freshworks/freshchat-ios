//
//  KonotorApp.m
//  Konotor
//
//  Created by Vignesh G on 19/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorApp.h"
#import "KonotorDataManager.h"
#import "WebServices.h"
#import "KonotorUser.h"

KonotorApp *gkCurrentKonotorApp = nil;
#define KONOTOR_CURRENT_SDK_VERSION @"18"
BOOL KONOTOR_APP_INIT_DONE = FALSE;

@implementation KonotorApp

@dynamic appID;
@dynamic appKey,appVersion,sdkVersion,hasWelcomeMessageDisplayed;
@dynamic deviceToken,deviceTokenUpdatedOnServer,lastUpdatedConversation,audioPermissionGiven;
static BOOL isUserBeingCreated = NO;

+(BOOL) getAppInitStatus{
    return KONOTOR_APP_INIT_DONE;
}

+(BOOL)initWithAppID: (NSString *)AppID WithAppKey: (NSString *) appKey{
    [KonotorDataManager sharedInstance];
    if(!KONOTOR_APP_INIT_DONE){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *urlString = [defaults stringForKey:@"uriForCurrentKonotorApp"];
        if(urlString){
            
            NSURL *mouri = [NSURL URLWithString:urlString];
            NSPersistentStoreCoordinator *coord = [[KonotorDataManager sharedInstance]persistentStoreCoordinator];

            gkCurrentKonotorApp = (KonotorApp*)[[[KonotorDataManager sharedInstance]mainObjectContext] objectWithID:[coord managedObjectIDForURIRepresentation:mouri]];

            [gkCurrentKonotorApp setAppID:AppID];
            [gkCurrentKonotorApp setAppKey:appKey];
            
            [[KonotorDataManager sharedInstance]save];

            if(gkCurrentKonotorApp.deviceTokenUpdatedOnServer == FALSE){
                [KonotorWebServices AddPushDeviceToken:gkCurrentKonotorApp.deviceToken];
            }
            
            KONOTOR_APP_INIT_DONE = YES;
            
        }else{
            
            KonotorApp *currentApp = (KonotorApp *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorApp" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
            [currentApp setAppID:AppID];
            [currentApp setAppKey:appKey];
          
            [currentApp setLastUpdatedConversation:@0];
            
            [[KonotorDataManager sharedInstance]save];
            
            gkCurrentKonotorApp = currentApp;
            
            NSURL *moURI = [[currentApp objectID] URIRepresentation];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[moURI absoluteString] forKey:@"uriForCurrentKonotorApp"];
            [defaults synchronize];
            
            KONOTOR_APP_INIT_DONE = YES;
        }
    }
    return YES;
}


+(NSString *) GetAppID{
    if(gkCurrentKonotorApp){
        return gkCurrentKonotorApp.appID;
    }
    return nil;
}

+(void) addDeviceToken :(NSString *)deviceToken;{
    if(gkCurrentKonotorApp){
        if(![[gkCurrentKonotorApp deviceToken] isEqualToString:deviceToken]){
            gkCurrentKonotorApp.deviceToken = deviceToken;
            gkCurrentKonotorApp.deviceTokenUpdatedOnServer = FALSE;
            [[KonotorDataManager sharedInstance]save];
            [KonotorWebServices AddPushDeviceToken:deviceToken ];
        }
    }
    
}

+(NSString *) getAppVersion{
    if(gkCurrentKonotorApp){
        return gkCurrentKonotorApp.appVersion;
    }
    return nil;
}

+(void) UpdateAppVersion: (NSString *) appVersion{
    if(gkCurrentKonotorApp){
        gkCurrentKonotorApp.appVersion = appVersion;
        [[KonotorDataManager sharedInstance]save];
    }
}

+(void) UpdateSDKVersion: (NSString *) sdkVersion{
    if(gkCurrentKonotorApp){
        gkCurrentKonotorApp.sdkVersion = sdkVersion;
        [[KonotorDataManager sharedInstance]save];
    }
}

+(NSString *) getSDKVersion{
    if(gkCurrentKonotorApp){
        return gkCurrentKonotorApp.sdkVersion;
    }
    return nil;
}

+(void) successfullyUpdatedDeviceTokenOnServer{
    if(gkCurrentKonotorApp){
        gkCurrentKonotorApp.deviceTokenUpdatedOnServer = TRUE;
        [[KonotorDataManager sharedInstance]save];
    }
}

+(BOOL) isDeviceTokenUpdatedOnServer{
    if(gkCurrentKonotorApp){
        return gkCurrentKonotorApp.deviceTokenUpdatedOnServer;
    }
    return YES;
    
}

+(NSString *) GetCachedDeviceToken{
    if(gkCurrentKonotorApp){
         return gkCurrentKonotorApp.deviceToken;
    }
    return nil;
}

+(NSString *) GetAppKey{
    if(gkCurrentKonotorApp){
        return gkCurrentKonotorApp.appKey;
    }
    return nil;
}

+(BOOL) hasWelcomeMessageDisplayed{
    if(gkCurrentKonotorApp){
        return [gkCurrentKonotorApp hasWelcomeMessageDisplayed];
    }
    return YES;
}

+(void) setWelcomeMessageStatus:(BOOL) status{
    if(gkCurrentKonotorApp){
         [gkCurrentKonotorApp setHasWelcomeMessageDisplayed:status];
        [[KonotorDataManager sharedInstance]save];
    }
}

+(BOOL) isUserBeingCreated{
    return isUserBeingCreated;
}

+(void) updateUserBeingCreated:(BOOL) status{
    isUserBeingCreated = status;
}


+(void) updateLastUpdatedConversations:(NSNumber *) lastUpdated{
    if(gkCurrentKonotorApp){
        gkCurrentKonotorApp.lastUpdatedConversation = lastUpdated;
        [[KonotorDataManager sharedInstance]save];
    }
}

+(void) UpdateAppAndSDKVersions{
    NSString *appVersionOnDisk = [KonotorApp getAppVersion];
    NSString *appVersionOnBundle  = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleShortVersionString"];
    
    //first time it will be nil
    if(!appVersionOnDisk){
        if(appVersionOnBundle){
            [KonotorWebServices UpdateAppVersion:appVersionOnBundle];
        }

    // or if the version has changed
    } else if (![appVersionOnBundle isEqualToString:appVersionOnDisk]){
        if(appVersionOnBundle){
            [KonotorWebServices UpdateAppVersion:appVersionOnBundle];
        }
    }
    
    NSString *sdkVersionOnDisk = [KonotorApp getSDKVersion];
    NSString *latestSDKVersion = KONOTOR_CURRENT_SDK_VERSION;
    
    if(!sdkVersionOnDisk){
        if(latestSDKVersion){
            [KonotorWebServices UpdateSdkVersion:latestSDKVersion];
        }
    }else if( ![sdkVersionOnDisk isEqualToString:latestSDKVersion]){
        if(latestSDKVersion){
            [KonotorWebServices UpdateSdkVersion:latestSDKVersion];
        }
    }

}

+(void) SendCachedTokenIfNotUpdated{
    if(![KonotorApp isDeviceTokenUpdatedOnServer]){
        NSString *deviceToken = [KonotorApp GetCachedDeviceToken];
        if(deviceToken){
            [KonotorWebServices AddPushDeviceToken:deviceToken];
        }
    }
}

+(NSNumber*) getLastUpdatedConversationsTimeStamp{
    if(gkCurrentKonotorApp){
        return [gkCurrentKonotorApp lastUpdatedConversation];
        [[KonotorDataManager sharedInstance]save];

    }
    return nil;
}

@end