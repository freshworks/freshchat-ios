//
//  FDTheme.h
//  Mobihelp
//
//  Created by Aravinth Chandran on 23/06/14.
//  Copyright (c) 2014 balaji. All rights reserved.
//

#ifndef FreshdeskSDK_FDTheme_h
#define FreshdeskSDK_FDTheme_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FDTheme : NSObject

@property (strong, nonatomic) NSString *themeName;

#pragma mark - Mobihelp Images

#define MOBIHELP_IMAGE_PROGRESS_HUD_SUCCESS        @"FDSuccess"
#define MOBIHELP_IMAGE_PROGRESS_HUD_ERROR          @"FDError"
#define MOBIHELP_IMAGE_PROGRESS_HUD_ANGLE_MASK     @"FDAngleMask"
#define MOBIHELP_IMAGE_CHAT_VIEW_RIGHT_BUBBLE      @"RightBubble"
#define MOBIHELP_IMAGE_CHAT_VIEW_LEFT_BUBBLE       @"LeftBubble"
#define MOBIHELP_IMAGE_NAV_BAR_COMPOSE_BUTTON      @"ComposeButton"
#define MOBIHELP_IMAGE_NAV_BAR_SEARCH_BUTTON       @"SearchButton"
#define MOBIHELP_IMAGE_MESSAGE_BAR_ATTACHMENT_PIN  @"AttachmentPin"
#define MOBIHELP_IMAGE_MESSAGE_BAR_INNER_TEXT_VIEW @"TextViewInner"
#define MOBIHELP_IMAGE_MESSAGE_BAR_OUTER_TEXT_VIEW @"TextViewOuter"

+(instancetype)sharedInstance;
-(NSDictionary *)getThemePreferences;
-(NSBundle *)getMHResourceBundle;

//Overall SDK
-(UIColor *)backgroundColorSDK;
-(UIColor *)badgeButtonBackgroundColor;
-(UIColor *)badgeButtonTitleColor;
-(UIColor *)talkToUsButtonColor;
-(NSString *)talkToUsButtonFontName;
-(CGFloat)talkToUsButtonFontSize;
-(UIColor *)noItemsFoundMessageColor;

//MyConversations Cell
-(NSString *)myConversationsCellFontName;
-(UIColor *)myConversationsCellFontColor;
-(CGFloat)myConversationsCellFontSize;
-(UIColor *)myConversationsCellBackgroundColor;

//Navigation Bar
-(UIColor *)navigationBarBackground;
-(UIColor *)navigationBarTitleColor;
-(NSString *)navigationBarTitleFontName;
-(CGFloat)navigationBarTitleFontSize;
-(UIColor *)navigationBarButtonColor;
-(NSString *)navigationBarButtonFontName;
-(CGFloat)navigationBarButtonFontSize;

//Feedback View
-(NSString *)feedbackViewFontName;
-(UIColor *)feedbackViewFontColor;
-(CGFloat)feedbackViewFontSize;
-(UIColor *)feedbackViewUserFieldBackgroundColor;
-(UIColor *)feedbackViewTicketBodyBackgroundColor;
-(UIColor *)feedbackViewUserFieldPlaceholderColor;
-(UIColor *)feedbackViewTicketBodyPlaceholderColor;

//Search Bar
-(NSString *)searchBarFontName;
-(UIColor *)searchBarFontColor;
-(CGFloat)searchBarFontSize;
-(UIColor *)searchBarInnerBackgroundColor;
-(UIColor *)searchBarOuterBackgroundColor;
-(UIColor *)searchBarCancelButtonColor;
-(NSString *)searchBarCancelButtonFontName;
-(CGFloat)searchBarCancelButtonFontSize;
-(UIColor *)searchBarCursorColor;

//Table View
-(UIColor *)tableViewCellBackgroundColor;
-(UIColor *)tableViewCellSeparatorColor;
-(UIColor *)tableViewCellFontColor;
-(CGFloat)tableViewCellFontSize;
-(NSString *)tableViewCellFontName;
-(UIColor *)timeDetailTextColor;

//Table View Section
-(NSString *)tableViewSectionHeaderFontName;
-(CGFloat)tableViewSectionFontSize;
-(UIColor *)tableViewSectionHeaderFontColor;
-(UIColor *)tableViewSectionHeaderBackgroundColor;
-(CGFloat)tableViewSectionHeaderHeight;

//Conversations View
-(UIColor *)conversationsViewCellBackgroundColor;
-(UIColor *)conversationsViewCellSeparatorColor;
-(UIColor *)conversationsViewCellFontColor;
-(CGFloat)conversationsViewCellFontSize;
-(NSString *)conversationsViewCellFontName;
-(UIColor *)conversationsTimeDetailTextColor;

//ConversationsUI
-(NSString *)chatBubbleFontName;
-(CGFloat)chatBubbleFontSize;
-(UIColor *)noteUpdateTimeStatusColor;
-(UIColor *)sentMessageFontColor;
-(UIColor *)receivedMessageFontColor;
-(UIColor *)hyperlinkColor;
-(UIColor *)sendButtonColor;
-(UIColor *)rateOnAppStoreButtonTintColor;
-(UIColor *)rateOnAppStoreLabelColor;
-(NSString *)rateOnAppStoreLabelFontName;
-(CGFloat)rateOnAppStoreLabelFontSize;
-(UIColor *)inputTextFontColor;

//Theme Images helper
+(UIImage *)getImageFromMHBundleWithName:(NSString *)imageName;
-(UIImage *)getThemedImageFromMHBundleWithName:(NSString *)imageName;

// Articles UI
-(NSString *)normalizeCssContent;

//Dialogues
-(UIColor *)dialogueTitleTextColor;
-(UIFont *)dialogueTitleFont;
-(UIColor *)dialogueButtonTextColor;
-(UIFont *)dialogueButtonFont;
-(UIColor *)dialogueBackgroundColor;

@end

#endif