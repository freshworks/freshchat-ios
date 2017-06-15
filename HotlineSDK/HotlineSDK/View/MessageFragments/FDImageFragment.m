//
//  FDImageFragment.m
//  HotlineSDK
//
//  Created by user on 07/06/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "FDImageFragment.h"
#import "FDImagePreviewController.h"

@implementation FDImageFragment

    -(id) initWithFragment: (FragmentData *) fragment ofMessage:(MessageData*)message {
        self = [super init];
        if(self) {
            self.fragmentData = fragment;
            self.translatesAutoresizingMaskIntoConstraints = NO;
            self.clipsToBounds = YES;
            self.backgroundColor = [UIColor whiteColor];
            self.contentMode = UIViewContentModeCenter;
            self.userInteractionEnabled = YES;
            NSData *extraJSONData = [fragment.extraJSON dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *extraJSONDict = [NSJSONSerialization JSONObjectWithData:extraJSONData options:0 error:nil];
            __block BOOL imageToBeDownloaded = true;
            if( !fragment.binaryData1 || !fragment.binaryData2) { //Data needed to be downloaded
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
            
            if(extraJSONDict[@"thumbnail"]) {
                NSDictionary *thumbnailDict = extraJSONDict[@"thumbnail"];
                NSNumber *thumbnailHeight = thumbnailDict[@"height"] < 200 ? thumbnailDict[@"height"] : @200 ;
                NSNumber *thumbnailWidth =  thumbnailDict[@"width"] < 200 ? thumbnailDict[@"width"] : @200 ;
                if (imageToBeDownloaded) {
                    [self setImage:[[HLTheme sharedInstance ] getImageWithKey:IMAGE_PLACEHOLDER]];
                } else {
                    [self setImage:[UIImage imageWithData:fragment.binaryData2]];
                }
                self.imgFrame = CGRectMake(0, 0, [thumbnailWidth floatValue], [thumbnailHeight floatValue]);
            } else {
                NSNumber *thumbnailHeight = extraJSONDict[@"height"] < 200 ? extraJSONDict[@"height"] : @200 ;
                NSNumber *thumbnailWidth =  extraJSONDict[@"width"] < 200 ? extraJSONDict[@"width"] : @200 ;
                if (imageToBeDownloaded) {
                    [self setImage:[[HLTheme sharedInstance ] getImageWithKey:IMAGE_PLACEHOLDER]];
                } else {
                    [self setImage:[UIImage imageWithData:fragment.binaryData1]];
                }
                self.imgFrame = CGRectMake(0, 0, [thumbnailWidth floatValue], [thumbnailHeight floatValue]);
            }
            UITapGestureRecognizer *imageClick = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(showImagePreview:)];
            [self addGestureRecognizer:imageClick];
            
        }
        return self;
    }

    -(void) showImagePreview:(id) sender {
        [self.delegate perfomAction:self.fragmentData];
    }
@end
