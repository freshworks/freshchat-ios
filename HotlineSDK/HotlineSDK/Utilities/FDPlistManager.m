//
//  FDPlistManager.m
//  HotlineSDK
//
//  Created by user on 23/09/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDPlistManager.h"
#import "HLMacros.h"
#import "FDUtilities.h"
#import "FDSecureStore.h"

@interface FDPlistManager ()

@property (strong, nonatomic) NSMutableDictionary *plist;

@end

@implementation FDPlistManager

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        self.plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }
    return self;
}


-(BOOL)checkOption:(NSString *)option forKey:(NSString *)key{
    BOOL isOptionPreferred = [[FDSecureStore sharedInstance] boolValueForKey:option];

    if ([FDUtilities isiOS10]) {
        return [self.plist objectForKey:key] && isOptionPreferred;
    }else{
        return isOptionPreferred;
    }
    
}

-(BOOL)micUsageEnabled{
    return [self checkOption:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED forKey:@"NSMicrophoneUsageDescription"];
}

-(BOOL)photoLibraryUsageEnabled{
    return [self checkOption:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED forKey:@"NSPhotoLibraryUsageDescription"];
}

-(BOOL)cameraUsageEnabled{
    return [self checkOption:HOTLINE_DEFAULTS_PICTURE_MESSAGE_ENABLED forKey:@"NSCameraUsageDescription"];
}

@end