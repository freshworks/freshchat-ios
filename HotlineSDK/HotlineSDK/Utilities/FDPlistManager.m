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
@property (strong, nonatomic) FDSecureStore *secStore;

@end

@implementation FDPlistManager

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        self.plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        self.secStore = [FDSecureStore sharedInstance];
    }
    return self;
}

-(BOOL)micUsageEnabled{
    return [self checkPermissionKeyForiOS10:@"NSMicrophoneUsageDescription"];
}

-(BOOL)photoLibraryUsageEnabled{
    return [self checkPermissionKeyForiOS10:@"NSPhotoLibraryUsageDescription"];
}

-(BOOL)cameraUsageEnabled{
    return [self checkPermissionKeyForiOS10:@"NSCameraUsageDescription"];
}

-(BOOL)checkPermissionKeyForiOS10:(NSString *)key{
    if ([FDUtilities isiOS10]) {
        return [self.plist objectForKey:key] ? YES : NO;
    }else{
        return YES;
    }
}


-(BOOL)isVoiceMessageEnabled{
    return ([self.secStore boolValueForKey:HOTLINE_DEFAULTS_VOICE_MESSAGE_ENABLED]
            && [self micUsageEnabled]);
}

-(BOOL)isGallerySelectionEnabled{
    return ([self.secStore boolValueForKey:HOTLINE_DEFAULTS_GALLERY_SELECTION_ENABLED]
            && [self photoLibraryUsageEnabled]);
}

-(BOOL)isCameraCaptureEnabled{
    return ([self.secStore boolValueForKey:HOTLINE_DEFAULTS_CAMERA_CAPTURE_ENABLED]
            && [self cameraUsageEnabled]);
}

@end
