//
//  FDPictureMessageUnit.h
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 30/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDMessageCell.h"
#import "Message.h"

@interface FDPictureMessageView : UIImageView

@property (strong, nonatomic) MessageData* message;

- (void) setUpPictureMessageInteractionsForMessage:(MessageData*)message withMessageWidth:(float)messageWidth;
+ (CGSize) getSizeForImageFromMessage:(MessageData*) message;

@end
