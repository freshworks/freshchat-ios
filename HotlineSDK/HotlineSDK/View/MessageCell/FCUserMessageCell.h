//
//  HLUserMessageCell.h
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCMessages.h"
#import "FCProtocols.h"

@interface FCUserMessageCell : UITableViewCell

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<HLMessageCellDelegate>)delegate;
- (void) drawMessageViewForMessage:(FCMessageData *)currentMessage parentView:(UIView*)parentView;

@property (nonatomic) BOOL showsTimeStamp;
@property (nonatomic) BOOL showsUploadStatus;
@property (strong, nonatomic) UIFont *messageTextFont;
@property (strong, nonatomic) NSString* customFontName;
@property (nonatomic) NSInteger maxcontentWidth;
@property (nonatomic, strong) FCMessageData *messageData;
@property (nonatomic, weak) id<HLMessageCellDelegate> delegate;

@property (nonatomic) UIEdgeInsets userChatBubbleInsets;
@property (strong, nonatomic) UIImage *userChatBubble;
@property (strong, nonatomic) UIView* contentEncloser;
@property (strong, nonatomic) UITextView* senderNameLabel;
@property (strong, nonatomic) UILabel* messageSentTimeLabel;
@property (strong, nonatomic) UITextView* messageTextView;
@property (strong, nonatomic) UIImage* sentImage;
@property (strong, nonatomic) UIImage* sendingImage;
@property (strong, nonatomic) UIImageView* uploadStatusImageView;
@property (strong, nonatomic) UIImageView* chatBubbleImageView;

@end
