//
//  FDPlistManager.m
//  HotlineSDK
//
//  Created by user on 23/09/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDPlistManager.h"
#import "HLMacros.h"

@interface FDPlistManager ()

@property (strong, nonatomic) NSMutableDictionary *plist;

@end

@implementation FDPlistManager

+ (instancetype)sharedInstance{
    static FDPlistManager *sharedPlistManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlistManager = [[self alloc]init];
    });
    return sharedPlistManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        self.plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }
    return self;
}

-(BOOL)isiOS10{
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0");
}

-(BOOL)canAccessMic{
    if ([self isiOS10]) {
        return [self.plist objectForKey:@"NSMicrophoneUsageDescription"];
    }else{
        return YES;
    }
}

-(BOOL)canAccessPhotoLibrary{
    if ([self isiOS10]) {
        return [self.plist objectForKey:@"NSPhotoLibraryUsageDescription"];
    }else{
        return YES;
    }
}

-(BOOL)canAccessCamera{
    if ([self isiOS10]) {
        return [self.plist objectForKey:@"NSCameraUsageDescription"];
    }else{
        return YES;
    }
}

@end
