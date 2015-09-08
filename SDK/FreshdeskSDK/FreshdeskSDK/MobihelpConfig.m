//
//  MobihelpConfig.m
//  FreshdeskSDK
//
//  Created by Aravinth on 29/07/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "Mobihelp.h"
#import "FDSecureStore.h"
#import "FDTheme.h"

@interface MobihelpConfig ()

@property (strong, nonatomic) FDSecureStore *secureStore;

@end

@implementation MobihelpConfig

#pragma mark - Lazy Instantiation

@synthesize feedbackType = _feedbackType;

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(instancetype)initWithDomain:(NSString*)domain withAppKey:(NSString*)appKey andAppSecret:(NSString*)appSecret{
    self = [super init];
    if (self) {
        self.domain                        = domain;
        self.appKey                        = appKey;
        self.appSecret                     = appSecret;
        self.prefetchSolutions             = YES;
        self.enableSSL                     = YES;
        self.enableEnhancedPrivacy         = NO;
        self.enableAutoReply               = NO;
        self.launchCountForAppReviewPrompt = 0;
        self.appStoreId                    = @"";
    }
    return self;
}

-(void)setAppStoreId:(NSString *)appStoreId{
    if ([appStoreId hasPrefix:@"id"]) {
        _appStoreId = appStoreId;
    }else{
        _appStoreId = [NSString stringWithFormat:@"id%@",appStoreId];
    }
}

-(void)setThemeName:(NSString*) themeName {
    [[FDTheme sharedInstance] setThemeName:themeName];
}

-(FEEDBACK_TYPE)feedbackType {
    if( self.enableEnhancedPrivacy){
        return FEEDBACK_TYPE_ANONYMOUS;
    }
    return _feedbackType;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"Domain: %@, AppKey: %@, AppSecret: %@, FeedbackType: %ld CoppaComplianceEnabled: %d", self.domain, self.appKey, self.appSecret, self.feedbackType, self.enableEnhancedPrivacy];
}

@end