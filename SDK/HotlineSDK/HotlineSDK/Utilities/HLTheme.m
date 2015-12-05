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
@property (strong, nonatomic) NSString *themeName;

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
        self.systemFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSystemFont:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

-(NSBundle *)getHLResourceBundle{
    NSBundle *MHResourcesBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"HLResources" withExtension:@"bundle"]];
    return MHResourcesBundle;
}

-(NSString *)getPathForTheme:(NSString *)theme{
    NSString *path = [[NSBundle mainBundle] pathForResource:theme ofType:@"plist"];
    if (!path) {
        NSBundle *MHResourcesBundle = [self getHLResourceBundle];
        path = [MHResourcesBundle pathForResource:theme ofType:@"plist" inDirectory:FD_THEMES_DIR];
    }
    return path;
}

//when setting a theme, check if that theme file exist, if yes update the theme preferences else throw exception.
-(void)setThemeName:(NSString *)themeName{
    NSString *themeFilePath = [self getPathForTheme:themeName];
    if (themeFilePath) {
        _themeName = themeName;
        NSData *plistData = [[NSFileManager defaultManager] contentsAtPath:themeFilePath];
        [self updateThemePreferencesWithData:plistData];
    }else{
        NSString *exceptionName   = @"MOBIHELP_SDK_INVALID_THEME_FILE";
        NSString *reason          = @"You are attempting to set a theme file \"%@\" that is not linked with the project through MHResourcesBundle";
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

+(UIImage *)getImageFromMHBundleWithName:(NSString *)imageName{
    NSString *pathPrefix        = @"HLResources.bundle/Images/";
    NSString *imageNameWithPath = [NSString stringWithFormat:@"%@%@",pathPrefix,imageName];
    return [UIImage imageNamed:imageNameWithPath];
}

-(UIColor *)gridViewItemBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.ItemBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:@"FFFFFF"];
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
    UIColor *color = [self getColorForKeyPath:@"Dialogues.DialogueLabelFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)dialogueTitleFont{
    return [self getFontWithKey:@"Dialogues.DialogueLabel" andDefaultSize:23];
}

-(UIColor *)dialogueButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.ButtonFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_BUTTON_FONT_COLOR];
}

-(UIFont *)dialogueButtonFont{
    return [self getFontWithKey:@"Dialogues.Button" andDefaultSize:20];
}

-(UIColor *)dialogueBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.DialogueBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
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

#pragma mark - Table View

-(UIFont *)tableViewCellFont{
    return [self getFontWithKey:@"TableView." andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)tableViewCellFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.FontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

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

-(UIColor *)tableViewCellImageBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.ImageViewBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}


-(UIColor *)tableViewCellSeparatorColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellSeparatorColor"];
    return color ? color : [HLTheme colorWithHex:FD_TABLEVIEW_SEPARATOR_COLOR];
}

-(UIColor *)timeDetailTextColor {
    UIColor *color = [self getColorForKeyPath:@"TableView.TimeDetailTextColor"];
    return color ? color : [UIColor lightGrayColor];
}

#pragma mark - Overall SDK

-(UIColor *)backgroundColorSDK{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_BACKGROUND_COLOR];
}

-(UIColor *)talkToUsButtonColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.TalkToUsButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_BUTTON_COLOR];
}

-(UIFont *)talkToUsButtonFont{
    return [self getFontWithKey:@"OverallSettings.TalkToUsButton" andDefaultSize:FD_FONT_SIZE_LARGE];
}

-(UIColor *)badgeButtonBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.UnreadBadgeColor"];
    return color ? color : [HLTheme colorWithHex:FD_BADGE_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)badgeButtonTitleColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.UnreadBadgeTitleColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)noItemsFoundMessageColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.NoItemsFoundMessageColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)inputTextFontColor{
    return [UIColor blackColor];
}

-(UIColor *)sendButtonColor{
    return [UIColor blueColor];
}

/* Additions by Sri - to be checked */
-(UIColor *)conversationViewTitleTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ConversationViewTitleTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_CONVERSATIONVIEWTITLETEXTCOLOR];
}
-(UIColor *)conversationViewBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ConversationViewBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_CONVERSATIONVIEWBACKGROUNDCOLOR];
}
-(UIColor *)actionButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ActionButtonTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_ACTIONBUTTONTEXTCOLOR];
}
-(UIColor *)actionButtonColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ActionButtonColor"];
    return color ? color : [HLTheme colorWithHex:FD_ACTIONBUTTONCOLOR];
}
-(UIColor *)businessMessageTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.BusinessMessageTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_BUSINESSMESSAGETEXTCOLOR];
}
-(UIColor *)userMessageTextColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.UserMessageTextColor"];
    return color ? color : [HLTheme colorWithHex:FD_USERMESSAGETEXTCOLOR];
}
-(UIColor *)hyperlinkColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.HyperlinkColor"];
    return color ? color : [HLTheme colorWithHex:FD_HYPERLINKCOLOR];
}
-(BOOL)alwaysPollForMessages{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.AlwaysPollForMessages"];
}
-(BOOL)showsBusinessProfileImage{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.ShowsBusinessProfileImage"];
}
-(BOOL)showsUserProfileImage{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.ShowsUserProfileImage"];
}
-(BOOL)showsBusinessMessageSenderName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.showsBusinessMessageSenderName"];
}
-(BOOL)showsUserMessageSenderName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.ShowsUserMessageSenderName"];
}
-(NSString *)textInputHintText{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.TextInputHintText"];
}
-(NSString *)businessProfileImageName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.BusinessProfileImageName"];
}
-(NSString *)userProfileImageName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.BusinessProfileImageName"];
}
-(NSString *)businessMessageSenderName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.UserProfileImageName"];
}
-(NSString *)userMessageSenderName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.UserMessageSenderName"];
}
-(NSString *)businessChatBubbleImageName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.BusinessChatBubbleImageName"];
}
-(NSString *)userChatBubbleImageName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.UserChatBubbleImageName"];
}
-(NSString *)chatBubbleFontName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.ChatBubbleFontName"];
}
-(NSString *)conversationUIFontName{
    return [self.themePreferences valueForKeyPath:@"ConversationsUI.ConversationUIFontName"];
}
-(float)chatBubbleFontSize{
   return [[self.themePreferences valueForKeyPath:@"ConversationsUI.ChatBubbleFontSize"] floatValue];
}
-(int)pollingTimeChatInFocus{
    return [[self.themePreferences valueForKeyPath:@"ConversationsUI.PollingTimeChatInFocus"] intValue];
}
-(int)pollingTimeChatNotInFocus{
    return [[self.themePreferences valueForKeyPath:@"ConversationsUI.PollingTimeChatNotInFocus"] intValue];
}



#pragma mark - Grid View

-(UIColor *)itemBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.ItemBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)itemSeparatorColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.ItemSeparatorColor"];
    return color ? color : [HLTheme colorWithHex:FD_FAQS_ITEM_SEPARATOR_COLOR];
}

-(UIFont *)contactUsFont{
    return [self getFontWithKey:@"GridView.ContactUs" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)contactUsFontColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.ContactUsFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

#pragma mark - Grid View Cell

-(UIFont *)categoryTitleFont{
    return [self getFontWithKey:@"GridViewCell.CategoryTitle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)categoryTitleFontColor{
    UIColor *color = [self getColorForKeyPath:@"GridViewCell.CategoryTitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIColor *)imageViewItemBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"GridViewCell.ImageViewbackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

#pragma mark - Conversation List View

-(UIColor *)conversationListViewBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationListView.BackgroundColor"];
    return color ? color : [HLTheme colorWithHex:@"FFFFFF"];
}

-(UIFont *)channelTitleFont{
    return [self getFontWithKey:@"GridView.ChannelTitle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelTitleFontColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.ChannelTitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)channelDescriptionFont{
    return [self getFontWithKey:@"GridView.ChannelDescription" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelDescriptionFontColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.ChannelDescriptionFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)lastUpdatedFont{
    return [self getFontWithKey:@"GridView.LastUpdated" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)lastUpdatedFontColor{
    UIColor *color = [self getColorForKeyPath:@"GridView.LastUpdatedFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

#pragma mark - Voice Recording Prompt

-(UIFont *)voiceRecordingTimeLabelFont{
    return [self getFontWithKey:@"GridViewCell.CategoryTitle" andDefaultSize:13];
}


@end