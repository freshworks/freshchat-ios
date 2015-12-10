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
@property (strong,nonatomic) NSString * themeName;

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
    NSString *path = [[NSBundle mainBundle] pathForResource:theme ofType:@"plist"];
    if (!path) {
        NSBundle *HLResourcesBundle = [self getHLResourceBundle];
        path = [HLResourcesBundle pathForResource:theme ofType:@"plist" inDirectory:FD_THEMES_DIR];
    }
    return path;
}

-(NSBundle *)getHLResourceBundle{
    NSBundle *HLResourcesBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"HLResources" withExtension:@"bundle"]];
    return HLResourcesBundle;
}


+(UIImage *)getImageFromMHBundleWithName:(NSString *)imageName{
    NSString *pathPrefix        = @"HLResources.bundle/Images/";
    NSString *imageNameWithPath = [NSString stringWithFormat:@"%@%@",pathPrefix,imageName];
    return [UIImage imageNamed:imageNameWithPath];
}

-(UIImage *)getImageWithKey:(NSString *)key{
    NSString *keypath = [NSString stringWithFormat:@"Images.%@",key];
    NSString *imageName = [self.themePreferences valueForKeyPath:[NSString stringWithFormat:@"Images.%@",key]];
    UIImage *image = [UIImage imageNamed:imageName];
    return image;
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
    return [self getFontWithKey:@"Dialogues.DialogueLabel" andDefaultSize:14];
}

//Yes Button

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


-(UIColor *)dialogueBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"Dialogues.DialogueBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_DIALOGUES_BACKGROUND_COLOR];
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
    return [self getFontWithKey:@"TableView.Title" andDefaultSize:FD_FONT_SIZE_MEDIUM];
}

-(UIColor *)tableViewCellTitleFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.TitleFontColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIFont *)tableViewCellDetailFont{
    return [self getFontWithKey:@"TableView.Detail" andDefaultSize:FD_FONT_SIZE_MEDIUM];
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
    return color ? color : [HLTheme colorWithHex:@"F2F2F2"];
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
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
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
    return [self getFontWithKey:@"GridViewCell.CategoryTitle" andDefaultSize:14];
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


@end