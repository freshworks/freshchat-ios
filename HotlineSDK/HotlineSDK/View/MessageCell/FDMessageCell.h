//
//  FDMessageCell.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDAudioMessageUnit.h"
#import "FDPictureMessageView.h"
#import "FDActionButton.h"
#import "Konotor.h"

#define KONOTOR_TEXTMESSAGE_MAXWIDTH 260.0
//TODO:  Fix this to use theme font instead of KONOTOR_MESSAGETEXT_FONT - Rex
#define KONOTOR_PROFILEIMAGE_DIMENSION 40.0
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING 10
#define KONOTOR_HORIZONTAL_PADDING 5
#define KONOTOR_VERTICAL_PADDING 2
#define KONOTOR_USERNAMEFIELD_HEIGHT 18
#define KONOTOR_TIMEFIELD_HEIGHT 16
#define KONOTOR_IMAGE_MAXHEIGHT 300
#define KONOTOR_IMAGE_MAXWIDTH 240
//TODO: Clean up and read from theme - Rex
#define KONOTOR_USERMESSAGE_TEXT_COLOR ([UIColor whiteColor])
#define KONOTOR_OTHERMESSAGE_TEXT_COLOR ([UIColor blackColor])
#define KONOTOR_USERTIMESTAMP_COLOR KONOTOR_LIGHTGRAY_COLOR
#define KONOTOR_OTHERTIMESTAMP_COLOR ([UIColor darkGrayColor])
#define KONOTOR_USERNAME_TEXT_COLOR ([UIColor whiteColor])
#define KONOTOR_OTHERNAME_TEXT_COLOR ([UIColor darkGrayColor])
#define KONOTOR_LIGHTGRAY_COLOR ([UIColor colorWithRed:0.9 green:0.9 blue:0.91 alpha:1.0])
#define KONOTOR_SHOW_TIMESTAMP YES
#define KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME NO
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING 20

@class FDAudioMessageUnit;
@class FDPictureMessageView;
@class FDMessageCell;

@protocol FDMessageCellDelegate <NSObject>

-(void)messageCell:(FDMessageCell *)cell pictureTapped:(UIImage *)image;
-(void)messageCell:(FDMessageCell *)cell openActionUrl:(id)sender;


@end

@interface FDMessageCell : UITableViewCell

@property (nonatomic, strong) KonotorMessageData *messageData;

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
@property (strong, nonatomic) FDPictureMessageView* messagePictureImageView;
@property (strong, nonatomic) FDActionButton* messageActionButton;
@property (strong, nonatomic) UIFont *messageTextFont;

+(BOOL) hasButtonForURL:(NSString*)actionURL articleID:(NSNumber*)articleID;


@property (nonatomic, weak) id<FDMessageCellDelegate> delegate;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<FDMessageCellDelegate>)delegate;
- (void) drawMessageViewForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView withWidth:(float)width;
+ (float) getHeightForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView;
+ (float) getWidthForMessage:(KonotorMessageData*)message;

@end

@interface TapOnPictureRecognizer : UITapGestureRecognizer
@property (strong, nonatomic) UIImage* image;
@property (strong, nonatomic) NSURL* imageURL;
@property (nonatomic) float height,width;

@end
