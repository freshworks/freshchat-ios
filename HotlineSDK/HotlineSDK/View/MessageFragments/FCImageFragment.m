//
//  FDImageFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FCImageFragment.h"
#import "FCImagePreviewController.h"

#define DEFAULT_THUMBNAIL_HEIGHT 225
#define DEFAULT_THUMBNAIL_WIDTH 225

#define MIN_THUMBNAIL_HEIGHT 75
#define MIN_THUMBNAIL_WIDTH 75


@implementation FCImageFragment

    -(id) initWithFragment: (FragmentData *) fragment ofMessage:(FCMessageData*)message {
        self = [super init];
        if(self) {
            self.fragmentData = fragment;
            self.contentMode = UIViewContentModeScaleAspectFit;
            self.translatesAutoresizingMaskIntoConstraints = NO;
            self.clipsToBounds = YES;
            self.backgroundColor = [UIColor clearColor];
            self.userInteractionEnabled = YES;
            NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
            __block BOOL imageToBeDownloaded = true;
            if ( !fragment.binaryData1 || !fragment.binaryData2) { //Data needed to be downloaded
                [fragment storeImageDataOfMessage:message withCompletion:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImage *sampleImage = [UIImage imageWithData:fragment.binaryData2];
                        self.image = sampleImage;
                        imageToBeDownloaded = false;
                    });
                }];
            } else {
                imageToBeDownloaded = false;
            }
            int thumbnailHeight = DEFAULT_THUMBNAIL_HEIGHT;
            int thumbnailWidth =  DEFAULT_THUMBNAIL_WIDTH ;
            if(extraJSONDict[@"thumbnail"]) {
                NSDictionary *thumbnailDict = extraJSONDict[@"thumbnail"];
                
                if(thumbnailDict[@"height"] && thumbnailDict[@"width"]) {
                    if ([thumbnailDict[@"height"] intValue] <= DEFAULT_THUMBNAIL_HEIGHT) {
                        thumbnailHeight = [thumbnailDict[@"height"] intValue];
                    }
                    if([thumbnailDict[@"height"] intValue] <= MIN_THUMBNAIL_HEIGHT) {
                        thumbnailHeight = MIN_THUMBNAIL_HEIGHT;
                    }
                    
                    if ([thumbnailDict[@"width"] intValue] <= DEFAULT_THUMBNAIL_WIDTH) {
                        thumbnailWidth = [thumbnailDict[@"width"] intValue];
                    }
                    if([thumbnailDict[@"width"] intValue] <= MIN_THUMBNAIL_WIDTH) {
                        thumbnailWidth = MIN_THUMBNAIL_WIDTH;
                    }                    
                    
                }
                if (imageToBeDownloaded) {
                    [self setImage:[[FCTheme sharedInstance ] getImageWithKey:IMAGE_PLACEHOLDER]];
                    //NSLog(@"FRAGMENT::Setting the PLACEHOLDER::::");
                } else {
                    [self setImage:[UIImage imageWithData:fragment.binaryData2]];
                    //NSLog(@"FRAGMENT:: Setting the thumbnail image::::");
                }
                self.imgFrame = CGRectMake(0, 0, thumbnailWidth, thumbnailHeight);
            } else {
                if (imageToBeDownloaded) {
                    [self setImage:[[FCTheme sharedInstance ] getImageWithKey:IMAGE_PLACEHOLDER]];
                } else {
                    //NSLog(@"FRAGMENT::Setting the original image::::");
                    [self setImage:[UIImage imageWithData:fragment.binaryData1]]; //Set the original image
                }
                self.imgFrame = CGRectMake(0, 0, thumbnailWidth, thumbnailHeight);
            }
            [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(showImagePreview:)]];
        }
        return self;
    }

    -(void) showImagePreview:(id) sender {
        if (self.delegate != nil) {
            [self.delegate performActionOn:self.fragmentData];
        }
    }
@end
