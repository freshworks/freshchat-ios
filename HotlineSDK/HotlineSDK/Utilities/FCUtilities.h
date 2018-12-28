//
//  FDUtilities.h
//  FreshdeskSDK
//
//  Created by balaji on 15/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#ifndef FreshdeskSDK_FDUtilities_h
#define FreshdeskSDK_FDUtilities_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCStringUtil.h"
#import "FreshchatSDK.h"
#import "FCMessageController.h"
#import "FCResponseInfo.h"
#import "FCAttributedText.h"

#define FRESHCHAT_USER_RESTORE_STATE @"com.freshworks.freshchat_user_restore_state"

@interface FreshchatUser()
    @property (nonatomic) BOOL isRestoring;
    @property (strong, nonatomic, readwrite) NSString *externalID;
    @property (strong, nonatomic, readwrite) NSString *restoreID;
    @property (strong, nonatomic, readwrite) NSString *jwtToken;
@end


@interface FCUtilities : NSObject

+(NSString *)currentUserAlias;
+(void) removeUUIDWithAppID:(NSString *)appID;
+(void) removeUUID;
+(void) resetAlias;
+(NSString *)getUserAliasWithCreate;
+(NSString *)generateUserAlias;
+(void) resetDataAndRestoreWithExternalID: (NSString *) externalID withRestoreID: (NSString *)restoreID withCompletion:(void (^)())completion;
+(void) resetDataAndRestoreWithJwtToken: (NSString *) jwtIdToken withCompletion:(void (^)())completion;
+ (void) resetNavigationStackWithController:(UIViewController *)controller currentController:(UIViewController *)currentController;

+(UIImage *)imageWithColor:(UIColor *)color;
+(NSString *) getKeyForObject:(NSObject *) object;
+(NSString *)getAdID;
+(NSString *)generateOfflineMessageAlias;
+(NSDictionary *)deviceInfoProperties;
+(void)setActivityIndicator:(BOOL)isVisible;
+(UIViewController*) topMostController;

+(void) AlertView:(NSString *)alertviewstring FromModule:(NSString *)pModule;
+ (BOOL) isPoweredByFooterViewHidden;
+(NSNumber *)getLastUpdatedTimeForKey:(NSString *)key;
+(NSString *)appName;
+(NSString*)deviceModelName;
+(NSString *) getTracker;
+(NSString *) returnLibraryPathForDir : (NSString *) directory;
+(NSDictionary*) filterValidUserPropEntries :(NSDictionary*) userDict;
+(NSArray *) convertTagsArrayToLowerCase : (NSArray *)tags;
+ (BOOL) hasNotchDisplay;
+(BOOL)isiOS10;
+ (BOOL)isDeviceLanguageRTL;

+ (void)initiatePendingTasks;
+ (BOOL)hasInitConfig;
+ (void)unreadCountInternalHandler:(void (^)(NSInteger count))completion;
+ (void) showAlertViewWithTitle : (NSString *)title message : (NSString *)message andCancelText : (NSString *) cancelText;
+ (BOOL) containsHTMLContent: (NSString *)content;
+ (BOOL) containsString: (NSString *)original andTarget:(NSString *)target;
+ (BOOL) canMakeSessionCall;
+ (BOOL) canMakeDAUCall;
+ (BOOL) canMakeRemoteConfigCall;
+ (BOOL) isRemoteConfigFetched;
+ (BOOL) canMakeTypicallyRepliesCall;
+ (NSTimeInterval) getCurrentTimeInMillis;
+ (NSString *) getReplyResponseForTime :(NSInteger)timeInSec andType: (enum ResponseTimeType) type;
+ (void) updateUserWithExternalID: (NSString *) externalID withRestoreID: (NSString *)restoreID;
+ (void)postUnreadCountNotification;
+ (void) updateUserWithData : (NSDictionary*) userDict;
+ (void) updateUserAlias: (NSString *) userAlias;
+ (NSString *) appendFirstName :(NSString *)firstName withLastName:(NSString *) lastName;
+ (UIColor *) invertColor :(UIColor *)color;
+ (BOOL)isValidUUIDForKey : (NSString *)key;
+ (void) handleGDPRForResponse :(FCResponseInfo *)responseInfo;
+ (void) updateAccountDeletedStatusAs :(BOOL) state;
+ (BOOL) isAccountDeleted;
+ (NSString *) getLocalizedPositiveFeedCSATQues;
+ (NSMutableAttributedString *) getAttributedContentForString :(NSString *)strVal withFont :(UIFont *) font;
+ (void) loadImageAndPlaceholderBgWithUrl:(NSString *)url forView:(UIImageView *)imageView withColor: (UIColor*)color andName:(NSString *)channelName;
+ (void) cacheImageWithUrl : (NSString *) url;
+ (NSString *) applyRegexForInputText :(NSString *) inputText;
+ (void) processResetChanges;
+ (void) addFlagToDisableUserPropUpdate;
+ (void) removeFlagToDisableUserPropUpdate;
+ (BOOL) canUpdateUserProperties;
+ (BOOL) handleLink : (NSURL *)url faqOptions: (FAQOptions *)faqOptions navigationController:(UIViewController *) navController handleFreshchatLinks:(BOOL) handleFreshchatLinks;

@end

#endif
