//
//  HLMacros.h
//  Hotline
//
//  Created by AravinthChandran .
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Availability.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//===============================================================================================
#pragma mark - System Versioning
//===============================================================================================

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//Detect Device
#define IS_IPAD   ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define IS_IPHONE ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5_OR_5S (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

//Screen Height and width
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

//===============================================================================================
#pragma mark - Utilities
//===============================================================================================

//Calculate time delta in a scope
#define TICK NSDate *startTime = [NSDate date]
#define TOCK NSLog(@"Elapsed Time: %f", -[startTime timeIntervalSinceNow])

//Activity indicator
#define ShowNetworkActivityIndicator() [FCUtilities setActivityIndicator:YES]
#define HideNetworkActivityIndicator() [FCUtilities setActivityIndicator:NO]

//TrimString
#define trimString(str) [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]

//Logging
#ifdef DEBUG
    #define FDLog(fmt, ...) NSLog((@""fmt),##__VA_ARGS__);
#else
    #define FDLog(...)
#endif

//ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"FRESHCHAT: " fmt), ##__VA_ARGS__);

#define BLog(fmt, ...) NSLog((@"FRESHCHAT: " fmt), ##__VA_ARGS__);

//Revert back
//#define BLog(fmt, ...) NSLog((@"FRESHCHAT: " fmt), ##__VA_ARGS__); UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:fmt preferredStyle:UIAlertControllerStyleAlert]; [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]]; UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;     [controller presentViewController:alert animated:YES completion:nil];


#define ADLog(fmt, ...) NSLog((@"FRESHCHAT: %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

//UILog
#ifdef DEBUG
    #define ULog(fmt, ...)  { UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%s\n [Line %d] ", __PRETTY_FUNCTION__, __LINE__] message:[NSString stringWithFormat:fmt, ##__VA_ARGS__]  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil]; [alert show]; }
#else
    #define ULog(...)
#endif
