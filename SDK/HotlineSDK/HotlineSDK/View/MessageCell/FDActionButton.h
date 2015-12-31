//
//  FDActionButton.h
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

#define KONOTOR_ACTIONBUTTON_HEIGHT 30
#define KONOTOR_BUTTON_DEFAULTACTIONLABEL (@"View")

@interface FDActionButton : UIButton
@property (strong, nonatomic) NSString* actionUrlString;
@property (strong, nonatomic) NSNumber* articleID;

- (void) setupWithLabel:(NSString*)actionLabel frame:(CGRect)messageFrame;
- (void) setUpStyle;

@end
