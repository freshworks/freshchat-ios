//
//  FDAttachmentImageController.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FDAttachmentImageController;

@protocol FDAttachmentImageControllerDelegate <NSObject>

@required

-(void)attachmentController:(FDAttachmentImageController *)controller didFinishSelectingImage:(UIImage *)image withCaption:(NSString *)caption;

@end

@interface FDAttachmentImageController : UIViewController<UITextViewDelegate>

-(instancetype)initWithImage:(UIImage *)image;

@property (weak, nonatomic) id<FDAttachmentImageControllerDelegate> delegate;


@end
