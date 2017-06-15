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
#import "Message.h"

#define KONOTOR_PROFILEIMAGE_DIMENSION 40.0
#define KONOTOR_HORIZONTAL_PADDING 5
#define KONOTOR_TEXTMESSAGE_MAXWIDTH 260.0
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING 10

@class FDAudioMessageUnit;
@class FDPictureMessageView;
@class FDMessageCell;

@protocol FDMessageCellDelegate <NSObject>

-(void)messageCell:(Fragment *)cell pictureTapped:(UIImage *)image;
-(void)messageCell:(Fragment *)cell openActionUrl:(id)sender;
-(void)perfomAction:(FragmentData *)fragment;

@end

@interface FDMessageCell : UITableViewCell

@property (nonatomic, strong) MessageData *messageData;

/* customization options */
@property (nonatomic) BOOL isAgentMessage;
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
@property (strong, nonatomic) UIImageView* chatBubbleImageView;
@property (strong, nonatomic) UITextView* messageTextView;
@property (strong, nonatomic) FDAudioMessageUnit* audioItem;
@property (strong, nonatomic) UIImageView* profileImageView;
@property (strong, nonatomic) UITextView* senderNameLabel;
@property (strong, nonatomic) UITextView* messageSentTimeLabel;
@property (strong, nonatomic) UIImageView* uploadStatusImageView;
@property (strong, nonatomic) FDPictureMessageView* messagePictureImageView;
@property (strong, nonatomic) FDActionButton* messageActionButton;
@property (strong, nonatomic) UIFont *messageTextFont;
@property (nonatomic) NSInteger maxcontentWidth;

+(BOOL) hasButtonForURL:(NSString*)actionURL articleID:(NSNumber*)articleID;


@property (nonatomic, weak) id<FDMessageCellDelegate> delegate;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<FDMessageCellDelegate>)delegate;
- (void) drawMessageViewForMessage:(MessageData *)currentMessage parentView:(UIView*)parentView withWidth:(float)width;
+ (float) getHeightForMessage:(MessageData *)currentMessage parentView:(UIView*)parentView;
+ (float) getWidthForMessage:(MessageData *)message;

@end

@interface TapOnPictureRecognizer : UITapGestureRecognizer
@property (strong, nonatomic) UIImage* image;
@property (strong, nonatomic) NSURL* imageURL;
@property (nonatomic) float height,width;

@end
