//
//  FDAttachmentImageController.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCInputToolbarView.h"

@class FCAttachmentImageController;

@protocol FDAttachmentImageControllerDelegate <NSObject>

@required

-(void)attachmentController:(FCAttachmentImageController *)controller didFinishSelectingImage:(UIImage *)image withCaption:(NSString *)caption;

@end

@interface FCAttachmentImageController : UIViewController<FDInputToolbarViewDelegate, UITextViewDelegate>

-(instancetype)initWithImage:(UIImage *)image;

@property (weak, nonatomic) id<FDAttachmentImageControllerDelegate> delegate;


@end
