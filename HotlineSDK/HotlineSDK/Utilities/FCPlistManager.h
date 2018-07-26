//
//  FDPlistManager.h
//  HotlineSDK
//
//  Created by user on 23/09/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCPlistManager : NSObject

-(BOOL)micUsageEnabled;

-(BOOL)photoLibraryUsageEnabled;

-(BOOL)cameraUsageEnabled;

-(BOOL)isVoiceMessageEnabled;

-(BOOL)isGallerySelectionEnabled;

-(BOOL)isCameraCaptureEnabled;

@end
