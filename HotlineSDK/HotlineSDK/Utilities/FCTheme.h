//
//  HLTheme.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IMAGE_SEARCH_ICON @"SearchIcon"
#define IMAGE_ATTACH_ICON @"ConversationDetail.AttachIcon"
#define IMAGE_BUBBLE_CELL_LEFT @"ConversationDetail.ChatBubbleLeft"
#define IMAGE_BUBBLE_CELL_RIGHT @"ConversationDetail.ChatBubbleRight"
#define IMAGE_AUDIO_TOOLBAR_CANCEL @"ConversationDetail.CancelIcon"
#define IMAGE_SEND_ICON @"ConversationDetail.SendIcon"
#define IMAGE_AVATAR_AGENT @"ConversationDetail.TeamMemberAvatarIcon"
#define IMAGE_INPUT_TOOLBAR_MIC @"ConversationDetail.RecordIcon"
#define IMAGE_CONTACT_US_ICON @"ContactUsIcon"
#define IMAGE_CONTACT_US_LIGHT_ICON @"ContactUsLightIcon"
#define IMAGE_BACK_BUTTON @"BackButton"
#define IMAGE_CLOSE_PREVIEW @"CloseImagePreview"
#define IMAGE_MESSAGE_SENDING_ICON @"MessageSending"
#define IMAGE_MESSAGE_SENT_ICON @"MessageSent"
#define IMAGE_PLACEHOLDER @"ImageMessagePlaceholder"
#define IMAGE_AVATAR_USER @"UserAvatarImage"
#define IMAGE_AUDIO_PLAY_BUTTON @"AudioMessagePlayButton"
#define IMAGE_AUDIO_STOP_BUTTON @"AudioMessageStopButton"
#define IMAGE_AUDIO_PROGRESS_BAR_MIN @"AudioProgessBarMin"
#define IMAGE_AUDIO_PROGRESS_BAR_MAX @"AudioProgessBarMax"
#define IMAGE_TABLEVIEW_ACCESSORY_ICON @"TableViewAccessoryIcon"
#define IMAGE_NOTIFICATION_CANCEL_ICON @"Notification.NotificationCancel"
#define IMAGE_CHANNEL_ICON @"ChannelImage"
#define IMAGE_FAQ_ICON @"FAQImage"
#define IMAGE_EMPTY_SEARCH_ICON @"EmptySearchImage"
#define IMAGE_CONVERSATION_BACKGROUND @"ConversationDetail.MessageListStyle.background"
#define IMAGE_SEARCH_BAR_SEARCH_ICON @"SearchBar.SearchBarStyle.searchIcon"
#define IMAGE_SEARCH_BAR_CLEAR_ICON @"SearchBar.SearchBarStyle.clearIcon"

@interface FCTheme : NSObject

@property (strong, nonatomic) NSString *themeName;

+ (instancetype)sharedInstance;
-(void)setThemeName:(NSString *)themeName;
-(UIColor *)searchBarInnerBackgroundColor;
+(UIColor *)colorWithHex:(NSString *)value;

//Search Bar
-(UIFont *)searchBarFont;
-(UIFont *)searchBarCancelButtonFont;
-(UIColor *)searchBarFontColor;
-(UIColor *)searchBarOuterBackgroundColor;
-(UIColor *)searchBarCancelButtonColor;
-(UIColor *)searchBarCursorColor;
-(UIColor *)searchBarTextViewBorderColor;

- (int)numberOfChannelListDescriptionLines;
- (int)numberOfCategoryListDescriptionLines;

//Article Table View
-(UIColor *)articleListFontColor;
-(UIFont *)articleListFont;
-(UIColor *)articleListBackgroundColor;
-(UIColor *)articleListCellSeperatorColor;
-(UIColor *)articleListCellBackgroundColor;

//Overall SDK
-(UIColor *)noItemsFoundMessageColor;
-(UIColor *)channelIconPlaceholderImageBackgroundColor;
-(UIFont *)channelIconPlaceholderImageCharFont;
-(UIColor *) imagePreviewScreenBackgroundColor;
-(UIFont *) sdkFont;

//Talk to us button
-(UIFont *)talkToUsButtonFont;
-(UIColor *)talkToUsButtonTextColor;
-(UIColor *)talkToUsButtonBackgroundColor;

//Dialogues
-(UIFont *)dialogueTitleFont;
-(UIColor *)dialogueTitleTextColor;
-(UIFont *)dialogueYesButtonFont;
-(UIColor *)dialogueYesButtonTextColor;
-(UIColor *)dialogueYesButtonBackgroundColor;
-(UIColor *)dialogueNoButtonBorderColor;
-(UIColor *)dialogueYesButtonBorderColor;
-(UIColor *)dialogueNoButtonBackgroundColor;
-(UIFont *)dialogueNoButtonFont;
-(UIColor *)dialogueNoButtonTextColor;
-(UIColor *)dialogueBackgroundColor;
-(UIColor *)dialogueButtonColor;

//TODO: Need to refractor this, use a common function for article voting and CSAT dialogue

//CSAT Yes No dialogue
-(UIFont *)custSatDialogueTitleFont;
-(UIColor *)custSatDialogueTitleTextColor;
-(UIFont *)custSatDialogueYesButtonFont;
-(UIColor *)custSatDialogueYesButtonTextColor;
-(UIColor *)custSatDialogueYesButtonBackgroundColor;
-(UIColor *)custSatDialogueNoButtonBorderColor;
-(UIColor *)custSatDialogueYesButtonBorderColor;
-(UIColor *)custSatDialogueNoButtonBackgroundColor;
-(UIFont *)custSatDialogueNoButtonFont;
-(UIColor *)custSatDialogueNoButtonTextColor;
-(UIColor *)custSatDialogueBackgroundColor;
-(UIColor *)custSatDialogueButtonColor;

//NavigationBar
-(UIColor *)navigationBarBackgroundColor;
-(UIFont *)navigationBarTitleFont;
-(UIColor *)navigationBarTitleColor;
-(UIColor *)navigationBarButtonColor;
-(UIFont *)navigationBarButtonFont;

//StatusBarStyle
-(UIStatusBarStyle)statusBarStyle;

- (UIColor *) progressBarColor;

//Image message attach
-(UIFont *)imgAttachBackButtonFont;
-(UIColor *)imgAttachBackButtonFontColor;

//Messagecell & Conversation UI
-(UIColor *)inputTextFontColor;
-(UIFont *) inputTextFont;
-(UIColor *) inputTextfieldBackgroundColor;
-(UIColor *)inputTextPlaceholderFontColor;
-(UIColor *)inputTextCursorColor;
-(UIColor *)inputToolbarBackgroundColor;
-(UIColor *)inputTextBorderColor;
-(UIColor *)sendButtonColor;

-(UIFont *) actionButtonFont;
-(UIColor *)actionButtonTextColor;
-(UIColor *)actionButtonSelectedColor;
-(UIColor *)actionButtonColor;
-(UIColor *)actionButtonBorderColor;

-(UIColor *)agentHyperlinkColor;
-(UIColor *)userHyperlinkColor;

-(UIFont *)agentMessageFont;
-(NSTextAlignment) userMessageTextAlignment;
-(NSTextAlignment) agentMessageTextAlignment;
-(UIFont *)userMessageFont;

-(UIFont *)agentMessageTimeFont;
-(UIFont *)getUserMessageTimeFont;

-(UIColor *)agentMessageTimeFontColor;
-(UIColor *)getUserMessageTimeFontColor;

//message detail bg component
-(id) getMessageDetailBackgroundComponent;

-(UIColor *)agentMessageFontColor;
-(UIColor *)userMessageFontColor;
-(UIColor *)agentNameFontColor;
-(UIFont *)agentNameFont;
-(UIFont *)responseTimeExpectationsFontName;
-(UIColor *)responseTimeExpectationsFontColor;

//Notification
-(UIColor *)notificationBackgroundColor;
-(UIColor *)notificationTitleTextColor;
-(UIColor *)notificationMessageTextColor;
-(UIFont *)notificationTitleFont;
-(UIFont *)notificationMessageFont;
-(UIColor *)notificationChannelIconBorderColor;
-(UIColor *)notificationChannelIconBackgroundColor;

//Grid View Cell
-(UIFont *)faqCategoryTitleFont;
-(UIColor *)faqCategoryTitleFontColor;

-(UIColor *)faqCategoryBackgroundColor;
-(UIColor *)gridViewCardBackgroundColor;
-(UIColor *) gridViewCardShadowColor;

-(UIColor *) faqPlaceholderIconBackgroundColor;
-(UIColor *)faqListCellSeparatorColor;

-(UIFont *)faqCategoryDetailFont;
-(UIColor *)faqCategoryDetailFontColor;
-(UIColor *) faqListViewCellBackgroundColor;
-(UIColor *)faqListCellSelectedColor;

//Conversation List View
-(UIColor *)channelListCellBackgroundColor;
-(UIFont *)channelTitleFont;
-(UIColor *)channelTitleFontColor;
-(UIFont *)channelDescriptionFont;
-(UIColor *)channelDescriptionFontColor;
-(UIFont *)channelLastUpdatedFont;
-(UIColor *)channelLastUpdatedFontColor;
-(UIFont *)badgeButtonFont;
-(UIColor *)badgeButtonBackgroundColor;
-(UIColor *)badgeButtonTitleColor;
-(UIColor *)channelListCellSeparatorColor;
-(UIColor *)channelListBackgroundColor;
-(UIColor *)channelCellSelectedColor;

//Message Conversation Overlay

- (UIColor *) conversationOverlayBackgroundColor;
- (UIFont *) conversationOverlayTextFont;
- (UIColor *) conversationOverlayTextColor;

//Empty Result
-(UIColor *)faqEmptyResultMessageFontColor;
-(UIFont *)faqEmptyResultMessageFont;
-(UIColor *)channelEmptyResultMessageFontColor;
-(UIFont *)channelEmptyResultMessageFont;

//Footer
- (NSString *) getFooterSecretKey;

//Chat bubble insets
- (UIEdgeInsets) getAgentBubbleInsets;
- (UIEdgeInsets) getUserBubbleInsets;

//Article detail theme name
-(NSString *)getArticleDetailCSSFileName;

//Voice Recording Prompt
-(UIFont *)voiceRecordingTimeLabelFont;

-(UIImage *)getImageWithKey:(NSString *)key;

-(UIImage *)getImageValueWithKey:(NSString *)key;

-(NSString *)getCssFileContent:(NSString *)key;

//CSAT Prompt
-(UIColor *)csatPromptBackgroundColor;
-(UIColor *)csatPromptRatingBarColor;

-(UIColor *)csatPromptSubmitButtonColor;
-(UIFont *)csatPromptSubmitButtonTitleFont;
-(UIColor *) csatPromptSubmitButtonBackgroundColor;

-(UIColor *)csatPromptHorizontalLineColor;
-(UIFont *)csatPromptQuestionTextFont;
-(UIColor *)csatPromptQuestionTextFontColor;
-(UIFont *)csatPromptInputTextFont;
-(UIColor *)csatPromptInputTextFontColor;
-(UIColor *)csatPromptInputTextBorderColor;

-(NSString *)userMessageLeftPadding;
-(NSString *)userMessageRightPadding;
-(NSString *)userMessageTopPadding;
-(NSString *)userMessageBottomPadding;

-(NSString *)agentMessageLeftPadding;
-(NSString *)agentMessageRightPadding;
-(NSString *)agentMessageTopPadding;
-(NSString *)agentMessageBottomPadding;

@end
