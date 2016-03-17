//
//  HLTheme.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLTheme.h"
#import "FDThemeConstants.h"

@interface HLTheme ()

@property (strong, nonatomic) NSMutableDictionary *themePreferences;
@property (strong, nonatomic) UIFont *systemFont;

@end

@implementation HLTheme

+ (instancetype)sharedInstance{
    static HLTheme *sharedHLTheme = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHLTheme = [[self alloc]init];
    });
    return sharedHLTheme;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.themeName = FD_DEFAULT_THEME_NAME;
        self.systemFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSystemFont:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

-(void)setThemeName:(NSString *)themeName{
    NSString *themeFilePath = [self getPathForTheme:themeName];
    if (themeFilePath) {
        _themeName = themeName;
        NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:themeFilePath];
        [self updateThemePreferencesWithData:plistData];
    }else{
        NSString *exceptionName   = @"HOTLINE_SDK_INVALID_THEME_FILE";
        NSString *reason          = @"You are attempting to set a theme file \"%@\" that is not linked with the project through HLResourcesBundle";
        NSString *exceptionReason = [NSString stringWithFormat:reason,themeName];
        [[[NSException alloc]initWithName:exceptionName reason:exceptionReason userInfo:nil]raise];
    }
}

-(void)updateThemePreferencesWithData:(NSData *)plistData{
    NSString *errorDescription;
    NSPropertyListFormat plistFormat;
    NSDictionary *immutablePlistInfo = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListMutableContainers format:&plistFormat errorDescription:&errorDescription];
    if (immutablePlistInfo) {
        self.themePreferences = [NSMutableDictionary dictionaryWithDictionary:immutablePlistInfo];
    }
}

-(NSString *)getPathForTheme:(NSString *)theme{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:theme ofType:@"plist"];
    if (!path) {
        NSBundle *HLResourcesBundle = [self getHLResourceBundle];
        path = [HLResourcesBundle pathForResource:theme ofType:@"plist" inDirectory:FD_THEMES_DIR];
    }
    return path;
}

-(NSBundle *)getHLResourceBundle{
    NSBundle *HLResourcesBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"HLResources" withExtension:@"bundle"]];
    return HLResourcesBundle;
}

-(UIImage *)getImageWithKey:(NSString *)key{
    NSString *imageName = [self.themePreferences valueForKeyPath:[NSString stringWithFormat:@"Images.%@",key]];
    UIImage *image = [UIImage imageNamed:imageName];
    return image;
}

-(UIColor *)getColorForKeyPath:(NSString *)path{
    NSString *hexString = [self.themePreferences valueForKeyPath:path];
    return hexString ? [HLTheme colorWithHex:hexString] : nil;
}

+(UIColor *)colorWithHex:(NSString *)value{
    unsigned hexNum;
    NSScanner *scanner = [NSScanner scannerWithString:value];
    if (![scanner scanHexInt: &hexNum]) return nil;
    return [self colorWithRGBHex:hexNum];
}

+(UIColor *)colorWithRGBHex:(uint32_t)hex{
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    return [UIColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:1.0f];
}

#pragma mark - Navigation Bar

- (UIColor *) navigationBarBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"NavigationBar.BackgroundColor"];
    return color ?color : [HLTheme colorWithHex:FD_NAVIGATION_BAR_BACKGROUND];
}

-(UIFont *)navigationBarTitleFont{
    return [self getFontWithKey:@"NavigationBar.Title" andDefaultSize:17];
}

-(UIColor *)navigationBarTitleColor{
        UIColor *color = [self getColorForKeyPath:@"NavigationBar.TitleColor"];
        return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}


-(UIColor *)navigationBarButtonColor{
    UIColor *color = [self getColorForKeyPath:@"NavigationBar.ButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_BUTTON_COLOR];
}


-(UIFont *)navigationBarButtonFont{
    return [self getFontWithKey:@"NavigationBar.Button" andDefaultSize:17];
}

#pragma mark - Search Bar

-(UIFont *)searchBarFont{
    return [self getFontWithKey:@"SearchBar." andDefaultSize:FD_FONT_SIZE_NORMAL];
}

-(UIColor *)searchBarFontColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.FontColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)searchBarInnerBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.InnerBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)searchBarOuterBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.OuterBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_SEARCH_BAR_OUTER_BACKGROUND_COLOR];
}

-(UIColor *)searchBarCancelButtonColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.CancelButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_BUTTON_COLOR];
}

-(UIFont *)searchBarCancelButtonFont{
    return [self getFontWithKey:@"SearchBar.CancelButton" andDefaultSize:FD_FONT_SIZE_NORMAL];
}

-(UIColor *)searchBarCursorColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.CursorColor"];
    return color ? color : [HLTheme colorWithHex:FD_BUTTON_COLOR];
}

#pragma mark - Dialogue box

-(UIColor *)dialogueTitleTextColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.LabelFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)dialogueTitleFont{
    return [self getFontWithKey:@"Dialogues.Label" andDefaultSize:14];
}

-(UIColor *)dialogueYesButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.YesButtonFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_FONT_COLOR];
}

-(UIFont *)dialogueYesButtonFont{
    return [self getFontWithKey:@"Dialogues.YesButton" andDefaultSize:14];
}

-(UIColor *)dialogueYesButtonBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.YesButtonBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_BACKGROUND_COLOR];
}

//No Button

-(UIColor *)dialogueNoButtonBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.NoButtonBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)dialogueNoButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.NoButtonFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_FONT_COLOR];
}

-(UIFont *)dialogueNoButtonFont{
    return [self getFontWithKey:@"Dialogues.NoButton" andDefaultSize:14];
}

-(UIColor *)dialogueNoButtonBorderColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.NoButtonBorderColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_BORDER_COLOR];
}

-(UIColor *)dialogueYesButtonBorderColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.YesButtonBorderColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_BORDER_COLOR];
}

-(UIColor *)dialogueBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_BACKGROUND_COLOR];
}

-(UIColor *)dialogueButtonColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.ButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUE_BUTTON_COLOR];
}

-(UIFont *)getFontWithKey:(NSString *)key andDefaultSize:(CGFloat)defaultSize {
    NSString *preferredFontName; CGFloat preferredFontSize;
    NSString *fontNameValue = [self.themePreferences valueForKeyPath:[key stringByAppendingString:@"FontName"]];
    NSString *fontSizeValue = [self.themePreferences valueForKeyPath:[key stringByAppendingString:@"FontSize"]];
    
    if (([fontNameValue caseInsensitiveCompare:@"SYS_DEFAULT_FONT_NAME"] == NSOrderedSame) || (fontNameValue == nil) ){
        preferredFontName = self.systemFont.familyName;
    }else{
        preferredFontName = fontNameValue;
    }
    
    if ([fontSizeValue caseInsensitiveCompare:@"DEFAULT_FONT_SIZE"] == NSOrderedSame ) {
        preferredFontSize = defaultSize;
    }else{
        if (fontSizeValue) {
            preferredFontSize = [fontSizeValue floatValue];
        }else{
            preferredFontSize = defaultSize;
        }
    }
    return [UIFont fontWithName:preferredFontName size:preferredFontSize];
}

- (UIEdgeInsets) getInsetWithKey :(NSString *)chatOwner{
    
    float resolution = [UIScreen mainScreen].scale;
    
    float topInset = [[self.themePreferences valueForKeyPath:[chatOwner stringByAppendingString:@"Top"]] floatValue] *resolution;
    float leftInset = [[self.themePreferences valueForKeyPath:[chatOwner stringByAppendingString:@"Left"]] floatValue] * resolution;
    float bottomInset = [[self.themePreferences valueForKeyPath:[chatOwner stringByAppendingString:@"Bottom"]] floatValue] * resolution;
    float rightInset = [[self.themePreferences valueForKeyPath:[chatOwner stringByAppendingString:@"Right"]] floatValue] * resolution;
    UIEdgeInsets bubbleInset = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);
    return bubbleInset;
}


#pragma mark - Table View

-(UIFont *)tableViewCellTitleFont{
    return [self getFontWithKey:@"TableView.Title" andDefaultSize:14];
}

-(UIColor *)tableViewCellTitleFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.TitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)tableViewCellDetailFont{
    return [self getFontWithKey:@"TableView.Detail" andDefaultSize:14];
}

-(UIColor *)tableViewCellDetailFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.DetailFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIColor *)tableViewCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}


-(UIColor *)tableViewCellSeparatorColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellSeparatorColor"];
    return color ? color : [HLTheme colorWithHex:@"F2F2F2"];
}

#pragma mark - Notifictaion

-(UIColor *)notificationBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Notification.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)notificationTitleTextColor{
    UIColor *color = [self getColorForKeyPath:@"Notification.ChannelTitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)notificationMessageTextColor{
    UIColor *color = [self getColorForKeyPath:@"Notification.MessageFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIFont *)notificationTitleFont{
    return [self getFontWithKey:@"Notification.ChannelTitle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIFont *)notificationMessageFont{
    return [self getFontWithKey:@"Notification.Message" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

#pragma mark - Article list

-(UIColor *)articleListFontColor{
    UIColor *color = [self getColorForKeyPath:@"ArticlesList.TitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_ARTICLE_LIST_FONT_COLOR];
}

-(UIFont *)articleListFont{
    return [self getFontWithKey:@"ArticlesList.Title" andDefaultSize:14];
}

#pragma mark - Overall SDK

-(UIColor *)backgroundColorSDK{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_BACKGROUND_COLOR];
}

-(UIColor *)talkToUsButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.TalkToUsButtonFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)talkToUsButtonBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.TalkToUsButtonBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_TALK_TO_US_BG_COLOR];
}

-(UIFont *)talkToUsButtonFont{
    return [self getFontWithKey:@"OverallSettings.TalkToUsButton" andDefaultSize:FD_FONT_SIZE_LARGE];
}

-(UIColor *)noItemsFoundMessageColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.NoItemsFoundMessageColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)inputTextFontColor{
    return [UIColor blackColor];
}

-(UIFont *)inputTextFont{
    return [self getFontWithKey:@"ConversationsUI.InputText" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *)sendButtonColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.SendButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_SEND_BUTTON_COLOR];
}

-(UIColor *)actionButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ActionButtonTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_ACTION_BUTTON_TEXT_COLOR];
}

-(UIColor *)actionButtonSelectedTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ActionButtonSelectedTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_ACTION_BUTTON_TEXT_COLOR];
}

-(UIColor *)actionButtonColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ActionButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_ACTION_BUTTON_COLOR];
}

-(UIColor *)actionButtonBorderColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ActionButtonBorderColor"];
    return color ? color : [HLTheme colorWithHex:FD_ACTION_BUTTON_COLOR];
}


-(UIColor *)hyperlinkColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.HyperlinkColor"];
    return color ? color : [HLTheme colorWithHex:FD_HYPERLINKCOLOR];
}

-(UIFont *)getChatBubbleMessageFont{
    return [self getFontWithKey:@"ConversationsUI.ChatBubbleMessage" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIFont *)getChatbubbleTimeFont{
    return [self getFontWithKey:@"ConversationsUI.ChatBubbleTime" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(NSString *)conversationUIFontName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.ConversationUIFontName"];
}

- (UIColor *) agentMessageFontColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.AgentMessageTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}
- (UIColor *) userMessageFontColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.UserMessageTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}


#pragma mark - Grid View
-(UIColor *)gridViewCellBorderColor{
    UIColor *color = [self getColorForKeyPath:@"GridViewCell.BorderColor"];
    return color ? color : [HLTheme colorWithHex:FD_FAQS_ITEM_SEPARATOR_COLOR];
}


#pragma mark - Grid View Cell
-(UIFont *)gridViewCellTitleFont{
    return [self getFontWithKey:@"GridViewCell.Title" andDefaultSize:14];
}

-(UIColor *)gridViewCellTitleFontColor{
    UIColor *color = [self getColorForKeyPath:@"GridViewCell.TitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIColor *)gridViewCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"GridViewCell.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)gridViewImageBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"GridViewCell.ImageViewBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

#pragma mark - Conversation Banner

- (UIColor *) conversationOverlayBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.Banner.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

- (UIFont *) conversationOverlayTextFont{
    return [self getFontWithKey:@"ConversationsUI.Banner.Message" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

- (UIColor *) conversationOverlayTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.Banner.MessageTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}


#pragma mark - Channel List View

-(UIColor *)channelListCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.cellBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIFont *)channelTitleFont{
    return [self getFontWithKey:@"ChannelListView.ChannelTitle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelTitleFontColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.ChannelTitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)channelDescriptionFont{
    return [self getFontWithKey:@"ChannelListView.ChannelDescription" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelDescriptionFontColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.ChannelDescriptionFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)channelLastUpdatedFont{
    return [self getFontWithKey:@"ChannelListView.LastUpdatedTime" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *)channelLastUpdatedFontColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.LastUpdatedTimeFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)badgeButtonFont{
    return [self getFontWithKey:@"ChannelListView.UnreadBadge" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)badgeButtonBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.UnreadBadgeColor"];
    return color ? color : [HLTheme colorWithHex:FD_BADGE_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)badgeButtonTitleColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.UnreadBadgeTitleColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)channelIconPalceholderImageBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ChannelListView.ChannelIconPlaceholderBackgroundColor"];
    return color ? color : [UIColor darkGrayColor];
}

-(UIFont *)channelIconPlaceholderImageCharFont{
    return [self getFontWithKey:@"ChannelListView.ChannelIconPlaceholderChar" andDefaultSize:FD_FONT_SIZE_LARGE];
}


#pragma mark - Footer Settings

- (NSString *) getFooterSecretKey{
    return [self.themePreferences valueForKeyPath:@"FooterView.HotlineDisableFrame"];
}

#pragma mark chat bubble inset

- (UIEdgeInsets) getAgentBubbleInsets{
    return [self getInsetWithKey:@"ChatBubbleInsets.AgentBubble"];
}

- (UIEdgeInsets) getUserBubbleInsets{
    return [self getInsetWithKey:@"ChatBubbleInsets.UserBubble"];
}

#pragma mark - Voice Recording Prompt

-(UIFont *)voiceRecordingTimeLabelFont{
    return [self getFontWithKey:@"GridViewCell.CategoryTitle" andDefaultSize:13];
}

-(NSString *)getCssFileContent:(NSString *)key{
    NSBundle *hlResourceBundle = [self getHLResourceBundle];
    NSString  *cssFilePath = [hlResourceBundle pathForResource:key ofType:@"css" inDirectory:FD_THEMES_DIR];
    NSData *cssContent = [NSData dataWithContentsOfFile:cssFilePath];
    return [[NSString alloc]initWithData:cssContent encoding:NSUTF8StringEncoding];
}

@end