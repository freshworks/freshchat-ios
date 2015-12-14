//
//  HLTheme.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLTheme : NSObject

#define FAQ_GRID_VIEW_SEARCH_BUTTON_IMAGE @"SearchButton"
#define INPUT_BAR_INNER_TEXT_VIEW_IMAGE @"TextViewInner"
#define INPUT_BAR_OUTER_TEXT_VIEW_IMAGE @"TextViewOuter"
#define INPUT_BAR_ATTACHMENT_ICON @"Upload"
#define INPUT_BAR_SEND_ICON @"Send"

+ (instancetype)sharedInstance;
+(UIImage *)getImageFromMHBundleWithName:(NSString *)imageName;
-(UIColor *)searchBarInnerBackgroundColor;
-(UIColor *)gridViewItemBackgroundColor;
+(UIColor *)colorWithHex:(NSString *)value;

//Search Bar
-(UIFont *)searchBarFont;
-(UIFont *)searchBarCancelButtonFont;
-(UIColor *)searchBarFontColor;
-(UIColor *)searchBarOuterBackgroundColor;
-(UIColor *)searchBarCancelButtonColor;
-(UIColor *)searchBarCursorColor;

//Table View
-(UIFont *)tableViewCellFont;
-(UIColor *)tableViewCellFontColor;
-(UIFont *)tableViewCellTitleFont;
-(UIColor *)tableViewCellTitleFontColor;
-(UIFont *)tableViewCellDetailFont;
-(UIColor *)tableViewCellDetailFontColor;
-(UIColor *)tableViewCellBackgroundColor;
-(UIColor *)tableViewCellImageBackgroundColor;
-(UIColor *)tableViewCellSeparatorColor;
-(UIColor *)timeDetailTextColor;
-(UIFont *)conversationsTimeDetailFont;

//Table View Section
-(UIFont *)tableViewSectionHeaderFont;
-(UIColor *)tableViewSectionHeaderFontColor;
-(UIColor *)tableViewSectionHeaderBackgroundColor;
-(CGFloat)tableViewSectionHeaderHeight;

//Overall SDK
-(UIColor *)backgroundColorSDK;
-(UIColor *)badgeButtonBackgroundColor;
-(UIColor *)badgeButtonTitleColor;
-(UIColor *)noItemsFoundMessageColor;

//Talk to us button
-(UIFont *)talkToUsButtonFont;
-(UIColor *)talkToUsButtonColor;

//Dialogues
-(UIColor *)getButtontextColorForKey:(NSString *)key;
-(UIFont *)dialogueTitleFont;
-(UIColor *)dialogueTitleTextColor;
-(UIFont *)dialogueYesButtonFont;
-(UIColor *)dialogueYesButtonTextColor;
-(UIColor *)dialogueYesButtonBackgroundColor;
-(UIColor *)dialogueNoButtonBackgroundColor;
-(UIFont *)dialogueNoButtonFont;
-(UIColor *)dialogueNoButtonTextColor;
-(UIColor *)dialogueBackgroundColor;

//Messagecell & Conversation UI
-(UIColor *)inputTextFontColor;
-(UIColor *)sendButtonColor;
-(UIColor *)conversationViewTitleTextColor;
-(UIColor *)conversationViewBackgroundColor;
-(UIColor *)actionButtonTextColor;
-(UIColor *)actionButtonColor;
-(UIColor *)businessMessageTextColor;
-(UIColor *)userMessageTextColor;
-(UIColor *)hyperlinkColor;
-(BOOL)alwaysPollForMessages;
-(BOOL)showsBusinessProfileImage;
-(BOOL)showsUserProfileImage;
-(BOOL)showsBusinessMessageSenderName;
-(BOOL)showsUserMessageSenderName;
-(NSString *)textInputHintText;
-(NSString *)businessProfileImageName;
-(NSString *)userProfileImageName;
-(NSString *)businessMessageSenderName;
-(NSString *)userMessageSenderName;
-(NSString *)businessChatBubbleImageName;
-(NSString *)userChatBubbleImageName;
-(NSString *)chatBubbleFontName;
-(NSString *)conversationUIFontName;
-(float)chatBubbleFontSize;
-(int)pollingTimeChatInFocus;
-(int)pollingTimeChatNotInFocus;


//Grid View

-(UIColor *)itemBackgroundColor;
-(UIColor *)itemSeparatorColor;
-(UIFont *)contactUsFont;
-(UIColor *)contactUsFontColor;

//Grid View Cell
-(UIFont *)categoryTitleFont;
-(UIColor *)categoryTitleFontColor;
-(UIColor *)imageViewItemBackgroundColor;

//Conversation List View
-(UIColor *)conversationListViewBackgroundColor;
-(UIFont *)channelTitleFont;
-(UIColor *)channelTitleFontColor;
-(UIFont *)channelDescriptionFontl;
-(UIColor *)channelDescriptionFontColor;
-(UIFont *)lastUpdatedFont;
-(UIColor *)lastUpdatedFontColor;

//Voice Recording Prompt
-(UIFont *)voiceRecordingTimeLabelFont;

-(UIImage *)getImageWithKey:(NSString *)key;

@end