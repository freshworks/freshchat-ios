//
//  FDNewTicketViewController.h
//  FreshdeskSDK
//
//  Created by balaji on 29/04/14.
//  Copyright (c) 2014 balaji. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FDAttachmentImageViewController;

@interface FDNewTicketViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSString         *ticketDescription;
@property (strong, nonatomic) UIViewController *sourceController;

- (instancetype)initWithModalPresentationType:(BOOL)isModalPresentation;

@end
