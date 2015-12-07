//
//  KonotorUser.m
//  Konotor
//
//  Created by Vignesh G on 08/07/13.
//  Copyright (c) 2013 Vignesh G. All rights reserved.
//

#import "KonotorUser.h"
#import "Konotor.h"
#import "KonotorDataManager.h"
#import "WebServices.h"
#import "KonotorApp.h"
#import "KonotorUtil.h"
#import "FDUtilities.h"

@implementation KonotorUser

@dynamic name,email,userAlias,isUserCreatedOnServer,hasConversations,appSpecificIdentifier;

static BOOL KONOTOR_INIT_USER_DONE = NO;
static KonotorUser *gCurrentUser = nil;

+(void)InitUser{
    if(![KonotorApp getAppInitStatus])
        return;
    
    if(!KONOTOR_INIT_USER_DONE){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *urlString = [defaults stringForKey:@"uriForCurrentlyLoggedInKonotorUser"];
        if(urlString){
            NSURL *mouri = [NSURL URLWithString:urlString];
            NSPersistentStoreCoordinator *coord = [[KonotorDataManager sharedInstance]persistentStoreCoordinator];
            NSManagedObjectContext *context = [[KonotorDataManager sharedInstance]mainObjectContext];
            gCurrentUser = (KonotorUser*)[context objectWithID:[coord managedObjectIDForURIRepresentation:mouri]];
            KONOTOR_INIT_USER_DONE = YES;
            [Konotor performSelector:@selector(PerformAllPendingTasks) withObject:nil];
            [KonotorWebServices DAUCall];
        }
        else
        {
            KonotorUser *pUser = (KonotorUser *)[NSEntityDescription insertNewObjectForEntityForName:@"KonotorUser" inManagedObjectContext:[[KonotorDataManager sharedInstance]mainObjectContext]];
            
            pUser.isUserCreatedOnServer = [FDUtilities isRegisteredDevice];
            pUser.userAlias = [FDUtilities getUUID];
            
            [[KonotorDataManager sharedInstance]save];
            gCurrentUser = pUser;
            NSURL *moURI = [[pUser objectID] URIRepresentation];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[moURI absoluteString] forKey:@"uriForCurrentlyLoggedInKonotorUser"];
            [defaults synchronize];
            [KonotorUser CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:@selector(PerformAllPendingTasks) withObject:[Konotor class] withSuccessParameter:nil ifFailure:nil withObject:nil withFailureParameter:nil];
            [KonotorWebServices DAUCall];
            KONOTOR_INIT_USER_DONE = YES;
        }
    }
}

+(BOOL) CreateUserOnServerIfNotPresentandPerformSelectorIfSuccessful:(SEL)SuccessSelector withObject:(id) successObject withSuccessParameter:(id) successParameter
ifFailure:(SEL)failureSelector withObject: (id) failureObject withFailureParameter:(id) failureParameter{
    
    if([KonotorApp isUserBeingCreated]){
        return YES;
    }
    
    [KonotorApp updateUserBeingCreated:YES];
    
    if(gCurrentUser){
        if(![gCurrentUser isUserCreatedOnServer]){
            [KonotorApp updateUserBeingCreated:YES];

            NSUInteger bgtask = [KonotorUtil beginBackgroundExecutionWithExpirationHandler:@selector(HandleUserCreateExpiry:) withParameters:nil forObject:[KonotorWebServices class]];
            
            NSString *pBasePath = [KonotorUtil GetBaseURL];
            
            AFKonotorHTTPClient *httpClient = [[AFKonotorHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:pBasePath]];
            [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
            
            [httpClient setParameterEncoding:AFKonotorJSONParameterEncoding];
            NSMutableDictionary *topLevel=[[NSMutableDictionary alloc]init];
            NSMutableDictionary *sublevel=[[NSMutableDictionary alloc]init];
            NSDictionary *meta = [KonotorUtil deviceInfoProperties];
            
            [sublevel setObject:gCurrentUser.userAlias forKey:@"alias"];
            [sublevel setObject:meta forKey:@"meta"];
            [topLevel setObject:sublevel forKey:@"user"];
            
            NSData *pEncodedJSON;
            NSError *pError;
            pEncodedJSON = [NSJSONSerialization dataWithJSONObject:topLevel  options:NSJSONWritingPrettyPrinted error:&pError];
            NSString *postPath = [NSString stringWithFormat:@"services/app/%@/user?t=%@", [KonotorApp GetAppID],[KonotorApp GetAppKey]];
            
            NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:postPath parameters:nil];
            [request setHTTPBody:pEncodedJSON];
            [KonotorNetworkUtil SetNetworkActivityIndicator:YES];
            AFKonotorHTTPRequestOperation *operation = [[AFKonotorHTTPRequestOperation alloc] initWithRequest:request];
            [operation setCompletionBlockWithSuccess:^(AFKonotorHTTPRequestOperation *operation, id JSON)
             {
                 
                 [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
                 [KonotorUser UserCreatedOnServer];
                 if(successObject)
                 {
                     if([successObject respondsToSelector:SuccessSelector])
                     {
                         [successObject performSelector:SuccessSelector withObject:successParameter];
                     }
                 }

                 [KonotorUtil EndBackgroundExecutionForTask:bgtask];
                 
                 [KonotorApp updateUserBeingCreated:NO];
             }
             failure:^(AFKonotorHTTPRequestOperation *operation, NSError *error){
                 [KonotorNetworkUtil SetNetworkActivityIndicator:NO];
                 [KonotorUtil EndBackgroundExecutionForTask:bgtask];
                 if(failureObject){
                     if([failureObject respondsToSelector:failureSelector])
                         [failureObject performSelector:failureSelector withObject:failureParameter];
                 }
                 [KonotorApp updateUserBeingCreated:NO];
             }];
            [operation start];
        }
        else{
            [KonotorApp updateUserBeingCreated:NO];
        }
        
        return YES;
    }
    
    else
    {
        [KonotorApp updateUserBeingCreated:NO];

    }
    return NO;
}

+(BOOL)isUserPresent{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *urlString = [defaults stringForKey:@"uriForCurrentlyLoggedInKonotorUser"];
    if(urlString){
        return YES;
    }
    return NO;
}

+(NSString *) GetUserAlias{
    NSString *useralias;
    if(gCurrentUser){
        useralias =  [gCurrentUser userAlias];
        return useralias;
    }
    return nil;
}

+(KonotorUser *) GetCurrentlyLoggedInUser{
    if(!gCurrentUser){
        [KonotorUser InitUser];
    }
    return gCurrentUser;
}

+(BOOL) UserCreatedOnServer{
    if(gCurrentUser){
        [gCurrentUser setIsUserCreatedOnServer:YES];
        [[KonotorDataManager sharedInstance]save];
    }
    return YES;
}

+(BOOL) isUserCreatedOnServer{
    if(gCurrentUser){
        return [gCurrentUser isUserCreatedOnServer];
    }
    return NO;
}

+(void)setCustomUserProperty:(NSString *) value forKey: (NSString*) key{
    NSMutableDictionary *sublevel=[[NSMutableDictionary alloc]init];
    NSMutableDictionary *toplevel=[[NSMutableDictionary alloc]init];
    [sublevel setObject:value forKey:key];
    [toplevel setObject:sublevel forKey:@"meta"];
    KonotorCustomProperty *prop = [KonotorCustomProperty CreateNewPropertyForKey:key WithValue:value];
    [KonotorWebServices UpdateUserPropertiesWithDictionary:toplevel withProperty:prop];
}

+(void) setUserIdentifier: (NSString *) UserIdentifier{
    if(gCurrentUser && UserIdentifier){
        if([gCurrentUser appSpecificIdentifier]){
            if(![[gCurrentUser appSpecificIdentifier] isEqualToString:UserIdentifier]){
                [gCurrentUser setAppSpecificIdentifier:UserIdentifier];
            }
            
            else
                return;
        }
        
        else if(![gCurrentUser appSpecificIdentifier])
        {
            [gCurrentUser setAppSpecificIdentifier:UserIdentifier];
            
        }
    }
    
    else
        return;
    
    
    NSMutableDictionary *sublevel=[[NSMutableDictionary alloc]init];
    [sublevel setObject:UserIdentifier forKey:@"identifier"];
    KonotorCustomProperty *prop = [KonotorCustomProperty CreateNewPropertyForKey:@"identifier" WithValue:UserIdentifier];
    [KonotorWebServices UpdateUserPropertiesWithDictionary:sublevel withProperty:prop];
}

+(void) setUserName: (NSString *) fullName
{
    if(gCurrentUser && fullName)
    {
        if([gCurrentUser name])
        {
            if(![[gCurrentUser name] isEqualToString:fullName])
            {
                [gCurrentUser setName:fullName];
            }
            
            else
                return;
        }
        
        else if(![gCurrentUser name])
        {
            [gCurrentUser setName:fullName];
            
        }
    }
    
    else
        return;
    
    
    NSMutableDictionary *sublevel=[[NSMutableDictionary alloc]init];
    [sublevel setObject:fullName forKey:@"name"];
    KonotorCustomProperty *prop = [KonotorCustomProperty CreateNewPropertyForKey:@"name" WithValue:fullName];
    [KonotorWebServices UpdateUserPropertiesWithDictionary:sublevel withProperty:prop];
}

+(void) setUserEmail: (NSString *) email{
    if(gCurrentUser && email){
        if([gCurrentUser email]){
            if(![[gCurrentUser email] isEqualToString:email]){
                [gCurrentUser setEmail:email];
            }
            else
                return;
        }
        else if(![gCurrentUser email])
        {
            [gCurrentUser setEmail:email];
            
        }
    }
    
    else
        return;
    
    
    NSMutableDictionary *sublevel=[[NSMutableDictionary alloc]init];
    [sublevel setObject:email forKey:@"email"];
    KonotorCustomProperty *prop = [KonotorCustomProperty CreateNewPropertyForKey:@"email" WithValue:email];
    [KonotorWebServices UpdateUserPropertiesWithDictionary:sublevel withProperty:prop];
}

@end
