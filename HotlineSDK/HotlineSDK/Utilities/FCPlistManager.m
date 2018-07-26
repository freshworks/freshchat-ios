//
//  FDPlistManager.m
//  HotlineSDK
//
//  Created by user on 23/09/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FCPlistManager.h"
#import "FCMacros.h"
#import "FCUtilities.h"
#import "FCSecureStore.h"

@interface FCPlistManager ()

@property (strong, nonatomic) NSMutableDictionary *plist;
@property (strong, nonatomic) FCSecureStore *secStore;

@end

@implementation FCPlistManager

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        self.plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        self.secStore = [FCSecureStore sharedInstance];
    }
    return self;
}

-(BOOL)micUsageEnabled{
    //return [self checkPermissionKeyForiOS10:@"NSMicrophoneUsageDescription"];
    return false;
}

-(BOOL)photoLibraryUsageEnabled{
    return [self checkPermissionKeyForiOS10:@"NSPhotoLibraryUsageDescription"];
}

-(BOOL)cameraUsageEnabled{
    return [self checkPermissionKeyForiOS10:@"NSCameraUsageDescription"];
}

-(BOOL)checkPermissionKeyForiOS10:(NSString *)key{
    if ([FCUtilities isiOS10]) {
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
