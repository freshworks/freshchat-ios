//
//  KonotorImageInput.h
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 10/03/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Konotor.h"

@interface KonotorImageInput : NSObject <UIAlertViewDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UITextViewDelegate>



- (instancetype) initWithConversation:(KonotorConversation *)conversation onChannel:(HLChannel *)channel;
- (void) showInputOptions:(UIViewController*) viewController;

@end