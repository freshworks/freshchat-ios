//
//  FDAttachmentImageViewController.h
//  FreshdeskSDK
//
//  Created by balaji on 27/10/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDGrowingTextView.h"
#import "FDNoteContent.h"

@class FDAttachmentImageViewController;

@protocol AttachmentImageControllerDelegate <NSObject>

@required

-(void)attachmentController:(FDAttachmentImageViewController *)controller didFinishEditingContent:(FDNoteContent *)content withCompletion:(void (^)(NSError *))completion;

@end

@interface FDAttachmentImageViewController : UIViewController {
    UIView *containerView;
    FDGrowingTextView *captionView;
    UIImageView *entryImageView;
    UIImageView *imageView;
}

@property (strong, nonatomic) id<AttachmentImageControllerDelegate> delegate;

-(instancetype)initWithPickedImage:(UIImage *)pickedImageFromGallery;

@end