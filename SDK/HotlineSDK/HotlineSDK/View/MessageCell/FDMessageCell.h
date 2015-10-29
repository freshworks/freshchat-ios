//
//  FDMessageCell.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDAudioMessageUnit.h"
#import "FDActionButton.h"
#import "Konotor.h"

#define KONOTOR_TEXTMESSAGE_MAXWIDTH 260.0
#define KONOTOR_MESSAGETEXT_FONT ([UIFont systemFontOfSize:16.0])
#define KONOTOR_PROFILEIMAGE_DIMENSION 40.0

#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_INSET 16
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET 14
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_RIGHT_INSET 28
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_BOTTOM_INSET 36
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING 10

#define KONOTOR_HORIZONTAL_PADDING 5
#define KONOTOR_VERTICAL_PADDING 2

#define KONOTOR_USERNAMEFIELD_HEIGHT 18
#define KONOTOR_TIMEFIELD_HEIGHT 16


@class FDAudioMessageUnit;

@interface FDMessageCell : UITableViewCell

/* customization options */
@property (nonatomic) BOOL isSenderOther;
@property (nonatomic) BOOL showsProfile;
@property (nonatomic) BOOL showsSenderName;
@property (nonatomic) BOOL showsTimeStamp;
@property (nonatomic) BOOL showsUploadStatus;
@property (strong, nonatomic) NSString* customFontName;
@property (strong, nonatomic) UIImage* sentImage;
@property (strong, nonatomic) UIImage* sendingImage;



/* message cell UI elements */
@property (nonatomic) CGRect messageTextBoxRect;
@property (nonatomic) CGRect messageContentViewRect;
@property (strong, nonatomic) UIImageView* chatCalloutImageView;
@property (strong, nonatomic) UITextView* messageTextView;
@property (strong, nonatomic) FDAudioMessageUnit* audioItem;
@property (strong, nonatomic) UIImageView* profileImageView;
@property (strong, nonatomic) UITextView* senderNameLabel;
@property (strong, nonatomic) UITextView* messageSentTimeLabel;
@property (strong, nonatomic) UIImageView* uploadStatusImageView;
@property (strong, nonatomic) UIImageView* messagePictureImageView;
@property (strong, nonatomic) FDActionButton* messageActionButton;

- (void) initCell;
- (void) drawMessageViewForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView;
+ (float) getHeightForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView;


@end
