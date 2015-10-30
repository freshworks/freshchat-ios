//
//  FDPictureMessageUnit.h
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 30/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDMessageCell.h"
#import "Konotor.h"


@interface FDPictureMessageUnit : UIImageView

@property (strong, nonatomic) KonotorMessageData* message;

- (void) setUpPictureMessageInteractionsForMessage:(KonotorMessageData*)message;
+ (CGSize) getSizeForImageFromMessage:(KonotorMessageData*) message;

@end
