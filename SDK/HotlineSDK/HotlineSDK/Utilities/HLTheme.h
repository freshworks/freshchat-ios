//
//  HLTheme.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLTheme : NSObject

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

//Images
-(UIImage *)getImageWithKey:(NSString *)key;

@end
