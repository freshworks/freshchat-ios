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
-(UIFont *)talkToUsButtonFont;
-(UIColor *)backgroundColorSDK;
-(UIColor *)badgeButtonBackgroundColor;
-(UIColor *)badgeButtonTitleColor;
-(UIColor *)talkToUsButtonColor;
-(UIColor *)noItemsFoundMessageColor;

//Dialogues
-(UIColor *)getButtontextColorForKey:(NSString *)key;
-(UIFont *)dialogueTitleFont;
-(UIColor *)dialogueTitleTextColor;
-(UIFont *)dialogueButtonFont;
-(UIColor *)dialogueButtonTextColor;
-(UIColor *)dialogueBackgroundColor;

//Messagecell UI
-(UIColor *)inputTextFontColor;
-(UIColor *)sendButtonColor;

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

@end