//
//  FDTheme.m
//  Mobihelp
//
//  Created by Aravinth Chandran on 23/06/14.
//  Copyright (c) 2014 balaji. All rights reserved.
//

#import "FDTheme.h"
#import "FDUtilities.h"
#import "FDConstants.h"
#import "FDThemeConstants.h"

@interface FDTheme ()

@property (strong, nonatomic) NSMutableDictionary *themePreferences;

@end

@implementation FDTheme

#pragma mark - Shared Instance

+ (instancetype)sharedInstance{
    static FDTheme *sharedFDTheme = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFDTheme = [[self alloc]init];
    });
    return sharedFDTheme;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.themeName = MOBIHELP_DEFAULT_THEME;
    }
    return self;
}

-(NSBundle *)getMHResourceBundle{
    NSBundle *MHResourcesBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"MHResources" withExtension:@"bundle"]];
    return MHResourcesBundle;
}

-(NSString *)getPathForTheme:(NSString *)theme{
    NSString *path = [[NSBundle mainBundle] pathForResource:theme ofType:@"plist"];
    if (!path) {
        NSBundle *MHResourcesBundle = [self getMHResourceBundle];
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

-(UIImage *)getThemedImageFromMHBundleWithName:(NSString *)imageName{
    NSString *pathPrefix = @"MHResources.bundle/Images/";
    NSString *imageNameWithPath = [NSString stringWithFormat:@"%@%@%@",pathPrefix,imageName,self.themeName];
    return [UIImage imageNamed:imageNameWithPath];
}

+(UIImage *)getImageFromMHBundleWithName:(NSString *)imageName{
    NSString *pathPrefix        = @"MHResources.bundle/Images/";
    NSString *imageNameWithPath = [NSString stringWithFormat:@"%@%@",pathPrefix,imageName];
    return [UIImage imageNamed:imageNameWithPath];
}

-(NSDictionary *)getThemePreferences{
    return self.themePreferences;
}

-(UIColor *)getColorForKeyPath:(NSString *)path{
    NSString *hexString = [self.themePreferences valueForKeyPath:path];
    return hexString ? [FDUtilities colorWithHex:hexString] : nil;
}

#pragma mark - Overall SDK

-(UIColor *)backgroundColorSDK{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.BackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BACKGROUND_COLOR];
}

-(UIColor *)talkToUsButtonColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.TalkToUsButtonColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BUTTON_COLOR];
}

-(NSString *)talkToUsButtonFontName {
    NSString *fontName = [self.themePreferences valueForKeyPath:@"OverallSettings.TalkToUsButtonFontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(CGFloat)talkToUsButtonFontSize {
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"OverallSettings.TalkToUsButtonFontSize"] floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_LARGE;
}

-(UIColor *)badgeButtonBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.UnreadBadgeColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BADGE_BUTTON_BACKGROUND_COLOR];
}

-(UIColor *)badgeButtonTitleColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.UnreadBadgeTitleColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)noItemsFoundMessageColor{
    UIColor *color = [self getColorForKeyPath:@"OverallSettings.NoItemsFoundMessageColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_BLACK];
}

#pragma mark - MyConversations Cell

-(NSString *)myConversationsCellFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"MyConversationsCell.FontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(UIColor *)myConversationsCellFontColor{
    UIColor *color = [self getColorForKeyPath:@"MyConversationsCell.FontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(CGFloat)myConversationsCellFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"MyConversationsCell.FontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_NORMAL;
}

-(UIColor *)myConversationsCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"MyConversationsCell.BackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

#pragma mark - Navigation Bar

-(UIColor *)navigationBarTitleColor{
    UIColor *color = [self getColorForKeyPath:@"NavigationBar.TitleColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_BLACK];
}

-(NSString *)navigationBarTitleFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"NavigationBar.TitleFontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(CGFloat)navigationBarTitleFontSize {
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"NavigationBar.TitleFontSize"] floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_MEDIUM;
}

-(UIColor *)navigationBarButtonColor{
    UIColor *color = [self getColorForKeyPath:@"NavigationBar.ButtonColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BUTTON_COLOR];
}

-(NSString *)navigationBarButtonFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"NavigationBar.ButtonFontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(CGFloat)navigationBarButtonFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"NavigationBar.ButtonFontSize"] floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_MEDIUM;
}

-(UIColor *)navigationBarBackground{
    UIColor *color = [self getColorForKeyPath:@"NavigationBar.BackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_NAVIGATION_BAR_BACKGROUND];
}

#pragma mark - Feedback View

-(NSString *)feedbackViewFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"FeedbackView.FontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(UIColor *)feedbackViewFontColor{
    UIColor *color = [self getColorForKeyPath:@"FeedbackView.FontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_BLACK];
}

-(CGFloat)feedbackViewFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"FeedbackView.FontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_NORMAL;
}

-(UIColor *)feedbackViewTicketBodyBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"FeedbackView.TicketBodyBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BACKGROUND_COLOR];
}

-(UIColor *)feedbackViewUserFieldBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"FeedbackView.UserFieldBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_FEEDBACK_VIEW_USER_FIELD_BACKGROUND_COLOR];
}

-(UIColor *)feedbackViewUserFieldPlaceholderColor{
    UIColor *color = [self getColorForKeyPath:@"FeedbackView.UserFieldPlaceholderColor"];
    return color ? color : [FDUtilities colorWithHex:FD_FEEDBACK_VIEW_PLACEHOLDER_COLOR];
}

-(UIColor *)feedbackViewTicketBodyPlaceholderColor{
    UIColor *color = [self getColorForKeyPath:@"FeedbackView.TicketBodyPlaceholderColor"];
    return color ? color : [FDUtilities colorWithHex:FD_FEEDBACK_VIEW_PLACEHOLDER_COLOR];
}


#pragma mark - Search Bar

-(NSString *)searchBarFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"SearchBar.FontName"];
    return fontName ? fontName : FD_SEARCH_BAR_FONT;
}


-(CGFloat)searchBarFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"SearchBar.FontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_NORMAL;
}

-(UIColor *)searchBarFontColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.FontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_BLACK];
}

-(UIColor *)searchBarInnerBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.InnerBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)searchBarOuterBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.OuterBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_SEARCH_BAR_OUTER_BACKGROUND_COLOR];
}

-(UIColor *)searchBarCancelButtonColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.CancelButtonColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BUTTON_COLOR];
}

-(NSString *)searchBarCancelButtonFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"SearchBar.CancelButtonFontName"];
    return fontName ? fontName : FD_SEARCH_BAR_FONT;
}

-(CGFloat)searchBarCancelButtonFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"SearchBar.CancelButtonFontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_NORMAL;
}

-(UIColor *)searchBarCursorColor{
    UIColor *color = [self getColorForKeyPath:@"SearchBar.CursorColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BUTTON_COLOR];
}

#pragma mark - Table View

-(NSString *)tableViewCellFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"TableView.FontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(UIColor *)tableViewCellFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.FontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(CGFloat)tableViewCellFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"TableView.FontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_MEDIUM;
}

-(UIColor *)tableViewCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)tableViewCellSeparatorColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellSeparatorColor"];
    return color ? color : [UIColor lightGrayColor];
}

-(UIColor *)timeDetailTextColor {
    UIColor *color = [self getColorForKeyPath:@"TableView.TimeDetailTextColor"];
    return color ? color : [UIColor lightGrayColor];
}

//Table View Section Header

-(NSString *)tableViewSectionHeaderFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"TableView.SectionHeaderTitleFont"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(CGFloat)tableViewSectionFontSize {
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"TableView.SectionHeaderTitleFontSize"] floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_NORMAL;
}

-(UIColor *)tableViewSectionHeaderFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.SectionHeaderTitleColor"];
    return color ? color : [FDUtilities colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIColor *)tableViewSectionHeaderBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.SectionHeaderBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BACKGROUND_COLOR];
}

-(CGFloat)tableViewSectionHeaderHeight {
    CGFloat height = [[self.themePreferences valueForKeyPath:@"TableView.SectionHeaderHeight"] floatValue];
    return height ? height : 20.0f;
}


#pragma mark - Conversations View

-(NSString *)conversationsViewCellFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"ConversationsView.FontName"];
    return fontName ? fontName : [self tableViewCellFontName];
}

-(UIColor *)conversationsViewCellFontColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsView.FontColor"];
    return color ? color : [self tableViewCellFontColor];
}

-(CGFloat)conversationsViewCellFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"ConversationsView.FontSize"]floatValue];
    return fontSize ? fontSize : [self tableViewCellFontSize];
}

-(UIColor *)conversationsViewCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsView.CellBackgroundColor"];
    return color ? color : [self tableViewCellBackgroundColor];
}

-(UIColor *)conversationsViewCellSeparatorColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsView.CellSeparatorColor"];
    return color ? color : [self tableViewCellSeparatorColor];
}

-(UIColor *)conversationsTimeDetailTextColor {
    UIColor *color = [self getColorForKeyPath:@"ConversationsView.TimeDetailTextColor"];
    return color ? color : [self timeDetailTextColor];
}

#pragma mark - ConversationsUI

-(NSString *)chatBubbleFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"ConversationsUI.ChatBubbleFontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(CGFloat)chatBubbleFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"ConversationsUI.ChatBubbleFontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_NORMAL;
}

-(UIColor *)noteUpdateTimeStatusColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.LastUpdatedTimeColor"];
    return color ? color : [FDUtilities colorWithHex:FD_CONVERSATIONS_UI_LAST_UPDATED_TIME_COLOR];
}

-(UIColor *)sentMessageFontColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.SentMessageFontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)receivedMessageFontColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.ReceivedMessageFontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_CONVERSATIONS_UI_RECEIVED_MESSAGE_FONT_COLOR];
}

-(UIColor *)hyperlinkColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.HyperlinkColor"];
    return color ? color : [FDUtilities colorWithHex:FD_CONVERSATIONS_UI_HYPERLINK_COLOR];
}

-(UIColor *)sendButtonColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.SendButtonColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BUTTON_COLOR];
}

-(UIColor *)rateOnAppStoreButtonTintColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.RateOnAppStoreButtonTintColor"];
    return color ? color : [FDUtilities colorWithHex:FD_BUTTON_COLOR];
}

-(UIColor *)rateOnAppStoreLabelColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.RateOnAppStoreLabelColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

-(NSString *)rateOnAppStoreLabelFontName{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"ConversationsUI.RateOnAppStoreLabelFontName"];
    return fontName ? fontName : FD_DEFAULT_FONT;
}

-(CGFloat)rateOnAppStoreLabelFontSize{
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"ConversationsUI.RateOnAppStoreLabelFontSize"]floatValue];
    return fontSize ? fontSize : FD_FONT_SIZE_SMALL;
}

-(UIColor *)inputTextFontColor{
    UIColor *color = [self getColorForKeyPath:@"ConversationsUI.InputTextFontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_BLACK];
}

-(NSString *)normalizeCssContent{
    NSBundle *mhResourceBundle = [self getMHResourceBundle];
    NSString  *cssFilePath = [mhResourceBundle pathForResource:@"normalize" ofType:@"css" inDirectory:FD_THEMES_DIR];
    NSData *cssContent = [NSData dataWithContentsOfFile:cssFilePath];
    return [[NSString alloc]initWithData:cssContent encoding:NSUTF8StringEncoding];
}

#pragma mark - Dialogue box

-(UIColor *)dialogueTitleTextColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.DialogueLabelFontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_BLACK];
}

-(UIFont *)dialogueTitleFont{
    
    NSString *fontName = [self.themePreferences valueForKeyPath:@"Dialogues.DialogueLabelFontName"];
    if (!fontName) {
        fontName = FD_DEFAULT_FONT;
    }
    
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"Dialogues.DialogueLabelFontSize"] floatValue];
    if (!fontSize) {
        fontSize = 23.0f;
    }
    
    return [UIFont fontWithName:fontName size:fontSize];
}

-(UIColor *)dialogueButtonTextColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.ButtonFontColor"];
    return color ? color : [FDUtilities colorWithHex:FD_DIALOGUES_BUTTON_FONT_COLOR];
}

-(UIFont *)dialogueButtonFont{
    NSString *fontName = [self.themePreferences valueForKeyPath:@"Dialogues.ButtonFontName"];
    
    if (!fontName) {
        fontName =  FD_DEFAULT_FONT;
    }
    
    CGFloat fontSize = [[self.themePreferences valueForKeyPath:@"Dialogues.ButtonFontSize"] floatValue];
    
    if (!fontSize) {
        fontSize = 20.0f;
    }
    
    return [UIFont fontWithName:fontName size:fontSize];
}

-(UIColor *)dialogueBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.DialogueBackgroundColor"];
    return color ? color : [FDUtilities colorWithHex:FD_COLOR_WHITE];
}

@end