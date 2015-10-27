//
//  FDMessageCell.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDMessageCell : UITableViewCell

@property (strong, nonatomic) UIImageView* chatCalloutImageView;
@property (strong, nonatomic) UITextView* messageTextView;
@property (strong, nonatomic) UIButton* audioPlayButton;
@property (strong, nonatomic) UIImageView* profileImageView;
@property (strong, nonatomic) UILabel* senderNameLabel;
@property (strong, nonatomic) UILabel* messageSentTimeLabel;
@property (strong, nonatomic) UIImageView* uploadStatusImageView;
@property (strong, nonatomic) UIImageView* messagePictureImageView;
@property (strong, nonatomic) UIButton* messageActionButton;


@end
