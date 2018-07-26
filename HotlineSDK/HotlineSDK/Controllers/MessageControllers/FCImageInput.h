//
//  KonotorImageInput.h
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 10/03/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FCMessageHelper.h"

@interface FCImageInput : NSObject <UIAlertViewDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UITextViewDelegate>

- (instancetype) initWithConversation:(FCConversations *)conversation onChannel:(FCChannels *)channel;
- (void) showInputOptions:(UIViewController*) viewController;
- (void) dismissAttachmentActionSheet;

@end
