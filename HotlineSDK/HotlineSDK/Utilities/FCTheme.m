//
//  HLTheme.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FCTheme.h"
#import "FDThemeConstants.h"
#define SDK_THEME_VERSION @"1.0"
#import "HLMacros.h"

@interface FCTheme ()

@property (strong, nonatomic) NSMutableDictionary *themePreferences;
@property (strong, nonatomic) UIFont *systemFont;

@end

@implementation FCTheme

+ (instancetype)sharedInstance{
    static FCTheme *sharedHLTheme = nil;
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
        self.systemFont = [self sdkFont];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSystemFont:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
}

-(void)refreshSystemFont:(NSNotification *)notification{
    self.systemFont = [self sdkFont];
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

- (NSTextAlignment) getTextAlignmentForKey:(NSString *) value{
    if([[value lowercaseString] isEqualToString:@"right"] || [value isEqualToString:@"NSTextAlignmentRight"]){
        return NSTextAlignmentRight;
    }
    else if([[value lowercaseString] isEqualToString:@"center"] || [value isEqualToString:@"NSTextAlignmentCenter"]){
        return NSTextAlignmentCenter;
    }
    return NSTextAlignmentLeft;
}

-(NSString *)getPathForTheme:(NSString *)theme{
    NSString *fileExt = [theme rangeOfString:@".plist"].location != NSNotFound ? nil : @".plist";
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:theme ofType:fileExt];
    if (!path) {
        NSBundle *hlResourcesBundle = [self getHLResourceBundle];
        path = [hlResourcesBundle pathForResource:theme ofType:fileExt inDirectory:FD_THEMES_DIR];
    }
    return path;
}

-(NSBundle *)getHLResourceBundle{
    NSBundle *hlResourcesBundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"FCResources" withExtension:@"bundle"]];
    return hlResourcesBundle;
}

-(UIImage *)getImageWithKey:(NSString *)key{
    NSString *imageName = [self.themePreferences valueForKeyPath:[NSString stringWithFormat:@"Images.%@",key]];
    UIImage *image = [UIImage imageNamed:imageName];
    return image;
}

/*
 User message padding
 */

-(NSString *)userMessageLeftPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.UserMessageLeft"];
}

-(NSString *)userMessageRightPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.UserMessageRight"];
}

-(NSString *)userMessageTopPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.UserMessageTop"];
}

-(NSString *)userMessageBottomPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.UserMessageBottom"];
}

/*
 Agent message padding
 */

-(NSString *)agentMessageLeftPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.AgentMessageLeft"];
}

-(NSString *)agentMessageRightPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.AgentMessageRight"];
}

-(NSString *)agentMessageTopPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.AgentMessageTop"];
}

-(NSString *)agentMessageBottomPadding {
    return [self.themePreferences valueForKeyPath:@"ConversationDetail.MessagePadding.AgentMessageBottom"];
}

-(UIImage *)getImageValueWithKey:(NSString *)key{
    NSString *imageName = [self.themePreferences valueForKeyPath:[NSString stringWithFormat:@"%@",key]];
    UIImage *image = [UIImage imageNamed:imageName];
    return image;
}


-(UIColor *)getColorForKeyPath:(NSString *)path{
    NSString *hexString = [self.themePreferences valueForKeyPath:path];
    return hexString ? [FCTheme colorWithHex:hexString] : nil;
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
-(UIColor *)getColorValueForKeyPath:(NSString *)path{
    NSString *hexString = [self.themePreferences valueForKeyPath:path];
    return hexString ? [FCTheme colorValueWithHex:hexString] : nil;
}
+(UIColor *)colorValueWithHex:(NSString *)value{
    if(value.length == 0){
        return nil;
    }
    unsigned hexNum;
    NSScanner *scanner = [NSScanner scannerWithString:value];
    [scanner setScanLocation:1];
    if (![scanner scanHexInt: &hexNum]) return nil;
    return [self colorWithRGBHex:hexNum];
    
}


#pragma mark - Navigation Bar

- (UIColor *) navigationBarBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"NavigationBar.NavigationBarStyle.background"];
    return color ?color : [FCTheme colorWithHex:FD_NAVIGATION_BAR_BACKGROUND];
}

-(UIFont *)navigationBarTitleFont{
    return [self getFontValueWithKey:@"NavigationBar.TitleTextStyle" andDefaultSize:17];
}

-(UIColor *)navigationBarTitleColor{
        UIColor *color = [self getColorValueForKeyPath:@"NavigationBar.TitleTextStyle.textColor"];
        return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}


-(UIColor *)navigationBarButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"NavigationBar.ActionButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_BUTTON_COLOR];
}

-(UIFont *)navigationBarButtonFont{
    return [self getFontValueWithKey:@"NavigationBar.ActionButtonStyle" andDefaultSize:17];
}

#pragma mark - Status Bar

-(UIStatusBarStyle)statusBarStyle{
    NSString *statusBarStyle = [self.themePreferences valueForKeyPath:@"Miscellaneous.StatusBarStyle.StatusBarBackground"];
    if([statusBarStyle isEqualToString:@"UIStatusBarStyleLightContent"]){
        return UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

#pragma mark - progress bar

- (UIColor *) progressBarColor{
    UIColor *color = [self getColorValueForKeyPath:@"Miscellaneous.ProgressBarStyle.progressBarColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_GRAY];
}

#pragma mark - Search Bar

-(UIFont *)searchBarFont{
    return [self getFontValueWithKey:@"SearchBar.SearchQueryTextStyle" andDefaultSize:FD_FONT_SIZE_NORMAL];
}

-(UIColor *)searchBarFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"SearchBar.SearchQueryTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)searchBarTextViewBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"SearchBar.SearchQueryTextStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)searchBarInnerBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"SearchBar.SearchQueryTextStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)searchBarOuterBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"SearchBar.SearchBarStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_SEARCH_BAR_OUTER_BACKGROUND_COLOR];
}

-(UIColor *)searchBarCancelButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"SearchBar.CancelButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_BUTTON_COLOR];
}

-(UIFont *)searchBarCancelButtonFont{
    return [self getFontValueWithKey:@"SearchBar.CancelButtonStyle" andDefaultSize:FD_FONT_SIZE_NORMAL];
}

-(UIColor *)searchBarCursorColor{
    UIColor *color = [self getColorValueForKeyPath:@"SearchBar.SearchQueryTextStyle.textCursorColor"];
    return color ? color : [FCTheme colorWithHex:FD_BUTTON_COLOR];
}

#pragma mark - Dialogue box

-(UIColor *)dialogueTitleTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQVotingPromptTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)dialogueTitleFont{
    return [self getFontValueWithKey:@"FAQDetail.FAQVotingPromptTextStyle" andDefaultSize:14];
}

-(UIColor *)dialogueYesButtonTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQUpvoteButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_FONT_COLOR];
}

-(UIFont *)dialogueYesButtonFont{
    return [self getFontValueWithKey:@"FAQDetail.FAQUpvoteButtonStyle" andDefaultSize:14];
}

-(UIColor *)dialogueYesButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQUpvoteButtonStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

//Image message attach

-(UIFont *)imgAttachBackButtonFont{
    return [self getFontValueWithKey:@"ConversationDetail.BackButtonStyle" andDefaultSize:16];
}

-(UIColor *)imgAttachBackButtonFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.BackButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_BACKGROUND_COLOR];
}

//No Button

-(UIColor *)dialogueNoButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQDownvoteButtonStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)dialogueNoButtonTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQDownvoteButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_FONT_COLOR];
}

-(UIFont *)dialogueNoButtonFont{
    return [self getFontValueWithKey:@"FAQDetail.FAQDownvoteButtonStyle" andDefaultSize:14];
}

-(UIColor *)dialogueNoButtonBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQDownvoteButtonStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_BORDER_COLOR];
}

-(UIColor *)dialogueYesButtonBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQUpvoteButtonStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_BORDER_COLOR];
}

-(UIColor *)dialogueBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQDetail.FAQVotingPromptViewStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_BACKGROUND_COLOR];
}

-(UIColor *)dialogueButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"Miscellaneous.ContactUsTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUE_BUTTON_COLOR];
}


#pragma mark Cust Sat dialogue

-(UIColor *)custSatDialogueTitleTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionPromptTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)custSatDialogueTitleFont{
    return [self getFontValueWithKey:@"ConversationDetail.ChatResolutionPromptTextStyle" andDefaultSize:14];
}

-(UIColor *)custSatDialogueYesButtonTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionPositiveButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_FONT_COLOR];
}

-(UIFont *)custSatDialogueYesButtonFont{
    return [self getFontValueWithKey:@"ConversationDetail.ChatResolutionPositiveButtonStyle" andDefaultSize:14];
}

-(UIColor *)custSatDialogueYesButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionPositiveButtonStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_BACKGROUND_COLOR];
}

//No Button

-(UIColor *)custSatDialogueNoButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionNegativeButtonStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)custSatDialogueNoButtonTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionNegativeButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_FONT_COLOR];
}

-(UIFont *)custSatDialogueNoButtonFont{
    return [self getFontValueWithKey:@"ConversationDetail.ChatResolutionNegativeButtonStyle" andDefaultSize:14];
}

-(UIColor *)custSatDialogueNoButtonBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionNegativeButtonStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_NO_BUTTON_BORDER_COLOR];
}

-(UIColor *)custSatDialogueYesButtonBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionPositiveButtonStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_YES_BUTTON_BORDER_COLOR];
}

-(UIColor *)custSatDialogueBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionPromptViewStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUES_BACKGROUND_COLOR];
}

-(UIColor *)custSatDialogueButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"CustSatDialogue.ButtonColor"];
    return color ? color : [FCTheme colorWithHex:FD_DIALOGUE_BUTTON_COLOR];
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
    UIFont *font = [UIFont fontWithName:preferredFontName size:preferredFontSize];
    if(font != nil) {
        return font;
    }
    return [UIFont fontWithName:self.systemFont.fontName size:preferredFontSize];
}

-(UIFont *)getFontValueWithKey:(NSString *)key andDefaultSize:(CGFloat)defaultSize {
    NSString *preferredFontName; CGFloat preferredFontSize;
    NSString *fontNameValue = [self.themePreferences valueForKeyPath:[key stringByAppendingString:@".fontName"]];
    NSString *fontSizeValue = [self.themePreferences valueForKeyPath:[key stringByAppendingString:@".textSize"]];
    
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
    UIFont *font = [UIFont fontWithName:preferredFontName size:preferredFontSize];
    if(font != nil) {
        return font;
    }
    return [UIFont fontWithName:self.systemFont.fontName size:preferredFontSize];
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

- (int)numberOfChannelListDescriptionLines{
    int linesNo = [[self.themePreferences valueForKeyPath:@"ChannelList.ChannelDescriptionTextStyle.maxLines"] intValue];
    return MIN(linesNo, 2);
}

- (int)numberOfCategoryListDescriptionLines{
    int linesNo = [[self.themePreferences valueForKeyPath:@"FAQCategoryList.FAQCategoryDescriptionTextStyle.maxLines"] intValue];
    return MIN(linesNo, 2);
}

#pragma mark - Notifictaion

-(UIColor *)notificationBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"Notification.NotificationStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)notificationTitleTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"Notification.TitleTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)notificationMessageTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"Notification.BodyTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIFont *)notificationTitleFont{
    return [self getFontValueWithKey:@"Notification.TitleTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIFont *)notificationMessageFont{
    return [self getFontValueWithKey:@"Notification.BodyTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)notificationChannelIconBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"Notification.IconStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)notificationChannelIconBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"Notification.IconStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

#pragma mark - Article list

-(UIColor *)articleListFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQList.FAQTitleTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)articleListFont{
    return [self getFontValueWithKey:@"FAQList.FAQTitleTextStyle" andDefaultSize:14];
}

-(UIColor *)articleListBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQList.FAQListStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)articleListCellSeperatorColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQList.FAQListItemStyle.dividerColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_GRAY];
}

-(UIColor *)articleListCellBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQList.FAQListItemStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

#pragma mark - Overall SDK

-(UIColor *)talkToUsButtonTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"Miscellaneous.ContactUsTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)talkToUsButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"Miscellaneous.ContactUsTextStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_TALK_TO_US_BG_COLOR];
}

-(UIFont *)talkToUsButtonFont{
    return [self getFontValueWithKey:@"Miscellaneous.ContactUsTextStyle" andDefaultSize:FD_FONT_SIZE_LARGE];
}

-(UIColor *)noItemsFoundMessageColor{
    UIColor *color = [self getColorValueForKeyPath:@"Miscellaneous.NoItemsFoundMessageColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(NSString *)getArticleDetailCSSFileName{
    NSString *filename = [self.themePreferences valueForKeyPath:@"Miscellaneous.ArticleDetailCSSFileName"];
    if (!filename) {
        filename = FD_DEFAULT_ARTICLE_DETAIL_CSS_FILENAME;
    }
    return filename;
}

-(UIColor *) imagePreviewScreenBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"Miscellaneous.ImagePreviewStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *) sdkFont {
    NSString *sdkFontString = [self.themePreferences valueForKeyPath:@"Miscellaneous.DefaultGlobalFont"];
    UIFont *sysFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *sdkFont = [UIFont fontWithName:sdkFontString size:sysFont.pointSize];
    if(sdkFont) {
        return sdkFont;
    }
    return sysFont;
}


-(UIFont *)responseTimeExpectationsFontName{
    return [self getFontValueWithKey:@"NavigationBar.SubTitleTextStyle" andDefaultSize:12];
}

-(UIColor *)responseTimeExpectationsFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"NavigationBar.SubTitleTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)inputTextFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyInputViewStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)inputTextFont{
    return [self getFontValueWithKey:@"ConversationDetail.MessageReplyInputViewStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *) inputTextfieldBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyInputViewStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)inputTextCursorColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyInputViewStyle.textCursorColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLUE];
}

-(UIColor *)inputToolbarBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyViewStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_GRAY];
}

-(UIColor *) inputToolbarDividerColor{
    
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyViewStyle.dividerColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)inputTextBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyInputViewStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)inputTextPlaceholderFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyInputViewStyle.textColorHint"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_GRAY];
}

-(UIColor *)sendButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageReplyInputViewStyle.buttonColor"];
    return color ? color : [FCTheme colorWithHex:FD_SEND_BUTTON_COLOR];
}

-(UIColor *)actionButtonTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageButtonStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_ACTION_BUTTON_TEXT_COLOR];
}

-(UIFont *) actionButtonFont{
    return [self getFontValueWithKey:@"ConversationDetail.MessageButtonStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *)actionButtonSelectedColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageButtonStyle.selectedColor"];
    return color ? color : [FCTheme colorWithHex:FD_ACTION_BUTTON_TEXT_COLOR];
}

-(UIColor *)actionButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageButtonStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_ACTION_BUTTON_COLOR];
}

-(UIColor *)actionButtonBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.MessageButtonStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_ACTION_BUTTON_COLOR];
}


-(UIColor *)agentHyperlinkColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.TeamMemberMessageTextStyle.textColorLink"];
    return color ? color : [FCTheme colorWithHex:FD_HYPERLINKCOLOR];
}

-(UIColor *)userHyperlinkColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.UserMessageTextStyle.textColorLink"];
    return color ? color : [FCTheme colorWithHex:FD_HYPERLINKCOLOR];
}

-(UIFont *)getChatBubbleMessageFont{
    return [self getFontWithKey:@"ConversationsUI.ChatBubbleMessage" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIFont *)agentMessageFont{
    return [self getFontValueWithKey:@"ConversationDetail.TeamMemberMessageTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIFont *)userMessageFont{
    return [self getFontValueWithKey:@"ConversationDetail.UserMessageTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIFont *)agentMessageTimeFont{
    return [self getFontValueWithKey:@"ConversationDetail.TeamMemberMessageTimeTextStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIFont *)getUserMessageTimeFont{
    return [self getFontValueWithKey:@"ConversationDetail.UserMessageTimeTextStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *)agentMessageTimeFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.TeamMemberMessageTimeTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}
-(UIColor *)getUserMessageTimeFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.UserMessageTimeTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

- (UIColor *) agentMessageFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.TeamMemberMessageTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}
- (UIColor *) userMessageFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.UserMessageTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)agentNameFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.TeamMemberNameTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)agentNameFont{
    return [self getFontValueWithKey:@"ConversationDetail.TeamMemberNameTextStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(NSTextAlignment) userMessageTextAlignment{
    return [self getTextAlignmentForKey:trimString([self.themePreferences valueForKeyPath:@"ConversationDetail.UserMessageTextStyle.textAlignment"])];
}

-(NSTextAlignment) agentMessageTextAlignment{
    return [self getTextAlignmentForKey:trimString([self.themePreferences valueForKeyPath:@"ConversationDetail.TeamMemberMessageTextStyle.textAlignment"])];
}

-(id) getMessageDetailBackgroundComponent{
    NSString *bgComponent = [self.themePreferences valueForKeyPath:@"ConversationDetail.MessageListStyle.background"];
    if(([bgComponent hasPrefix:@"#"]) && (bgComponent.length == 7)){
        UIColor *color = [FCTheme colorValueWithHex:bgComponent];
        return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
    }
    else{
        return [UIImage imageNamed:bgComponent];;
    }
    return nil;
}

#pragma mark - Grid View Cell
-(UIFont *)faqCategoryTitleFont{
    return [self getFontValueWithKey:@"FAQCategoryList.FAQCategoryNameTextStyle" andDefaultSize:14];
}

-(UIColor *)faqCategoryTitleFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryNameTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIColor *)faqCategoryBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryListStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)gridViewCardBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryListItemStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *) gridViewCardShadowColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryListItemStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *) faqPlaceholderIconBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryAltIconStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLUE];
}
-(UIFont *) faqPlaceholderIconFont{
    return [self getFontValueWithKey:@"FAQCategoryList.FAQCategoryAltIconStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)faqListCellSeparatorColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryListItemStyle.dividerColor"];
    return color ? color : [FCTheme colorWithHex:@"F2F2F2"];
}

-(UIColor *)faqListCellSelectedColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryListItemStyle.backgroundSelected"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIFont *)faqCategoryDetailFont{
    return [self getFontValueWithKey:@"FAQCategoryList.FAQCategoryDescriptionTextStyle" andDefaultSize:13];
}

-(UIColor *)faqCategoryDetailFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryDescriptionTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:@"F2F2F2"];
}

#pragma mark - Conversation Banner

- (UIColor *) conversationOverlayBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ConversationBannerMessageStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

- (UIFont *) conversationOverlayTextFont{
    return [self getFontValueWithKey:@"ConversationDetail.ConversationBannerMessageStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

- (UIColor *) conversationOverlayTextColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ConversationBannerMessageStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}


#pragma mark - Channel List View

-(UIColor *)channelListCellSeparatorColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelListStyle.dividerColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)channelListCellBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelListItemStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIFont *)channelTitleFont{
    return [self getFontValueWithKey:@"ChannelList.ChannelNameTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelTitleFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelNameTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)channelDescriptionFont{
    return [self getFontValueWithKey:@"ChannelList.ChannelDescriptionTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelDescriptionFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelDescriptionTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)channelLastUpdatedFont{
    return [self getFontValueWithKey:@"ChannelList.ChannelLastUpdatedAtTextStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *)channelLastUpdatedFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelLastUpdatedAtTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)badgeButtonFont{
    return [self getFontValueWithKey:@"ChannelList.ChannelUnreadCountTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)badgeButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelUnreadCountTextStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_BADGE_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)badgeButtonTitleColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelUnreadCountTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)channelIconPlaceholderImageBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelAltIconStyle.background"];
    return color ? color : [UIColor darkGrayColor];
}

-(UIFont *)channelIconPlaceholderImageCharFont{
    return [self getFontValueWithKey:@"ChannelList.ChannelAltIconStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelListBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelListStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)channelCellSelectedColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelListItemStyle.backgroundSelected"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

#pragma mark - Empty Result
-(UIColor *)faqEmptyResultMessageFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQList.FAQListEmptyTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)faqEmptyResultMessageFont{
    return [self getFontValueWithKey:@"FAQList.FAQListEmptyTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)channelEmptyResultMessageFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ChannelList.ChannelListEmptyTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)channelEmptyResultMessageFont{
    return [self getFontValueWithKey:@"ChannelList.ChannelListEmptyTextStyle" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

#pragma mark - Footer Settings

- (NSString *) getFooterSecretKey{
    return [self.themePreferences valueForKeyPath:@"FooterView.FreshchatDisableFrame"];
}

#pragma mark chat bubble inset

- (UIEdgeInsets) getAgentBubbleInsets{
    return [self getInsetWithKey:@"ConversationDetail.ChatBubbleInsets.AgentBubble"];
}

- (UIEdgeInsets) getUserBubbleInsets{
    return [self getInsetWithKey:@"ConversationDetail.ChatBubbleInsets.UserBubble"];
}

#pragma mark - Voice Recording Prompt

-(UIFont *)voiceRecordingTimeLabelFont{
    return [self getFontWithKey:@"FAQCategoryList.GridViewCategoryTitle" andDefaultSize:13];
}

-(NSString *)getCssFileContent:(NSString *)key{
    NSString *fileExt = [key rangeOfString:@".css"].location != NSNotFound ? nil : @".css";
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:key ofType:fileExt];
    if (!filePath) {
        NSBundle *hlResourcesBundle = [self getHLResourceBundle];
        filePath = [hlResourcesBundle pathForResource:key ofType:fileExt inDirectory:FD_THEMES_DIR];
    }
    NSData *cssContent = [NSData dataWithContentsOfFile:filePath];
    return [[NSString alloc]initWithData:cssContent encoding:NSUTF8StringEncoding];
}

-(UIColor *) faqListViewCellBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"FAQCategoryList.FAQCategoryListItemStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

#pragma mark CSAT Prompt

-(UIColor *)csatPromptBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.ChatResolutionPromptViewStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)csatPromptRatingBarColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveyRatingBarStyle.foreground"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_WHITE];    
}

-(UIColor *)csatPromptSubmitButtonColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveySubmitButtonTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_BUTTON_COLOR];
}

-(UIFont *)csatPromptSubmitButtonTitleFont{
    return [self getFontValueWithKey:@"ConversationDetail.CustomerSurveySubmitButtonTextStyle" andDefaultSize:15];
}

-(UIColor *) csatPromptSubmitButtonBackgroundColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveySubmitButtonTextStyle.background"];
    return color ? color : [FCTheme colorWithHex:FD_BUTTON_COLOR];
}

-(UIColor *)csatPromptInputTextFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveyCommentsInputViewStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)csatPromptInputTextFont{
    return [self getFontValueWithKey:@"ConversationDetail.CustomerSurveyCommentsInputViewStyle" andDefaultSize:FD_FONT_SIZE_SMALL];
}

-(UIColor *)csatPromptInputTextBorderColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveyCommentsInputViewStyle.borderColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_GRAY];
}

-(UIColor *)csatPromptHorizontalLineColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveyDialogStyle.dividerColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_GRAY];
}

-(UIFont *)csatPromptQuestionTextFont{
    return [self getFontValueWithKey:@"ConversationDetail.CustomerSurveyQuestionTextStyle" andDefaultSize:15];
}

-(UIColor *)csatPromptQuestionTextFontColor{
    UIColor *color = [self getColorValueForKeyPath:@"ConversationDetail.CustomerSurveyQuestionTextStyle.textColor"];
    return color ? color : [FCTheme colorWithHex:FD_COLOR_BLACK];
}

@end
