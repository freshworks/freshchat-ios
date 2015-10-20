//
//  HLTheme.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLTheme.h"
#import "FDThemeConstants.h"
#define FD_COLOR_WHITE @"FFFFFF"
#define FD_DIALOGUES_BUTTON_FONT_COLOR @"007AFF"
#define FD_COLOR_BLACK @"000000"

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
        self.systemFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSystemFont:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    return self;
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

-(UIColor *)tableViewCellBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_COLOR_WHITE];
}

-(UIColor *)tableViewCellSeparatorColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.CellSeparatorColor"];
    return color ? color : [UIColor lightGrayColor];
}

-(UIColor *)timeDetailTextColor {
    UIColor *color = [self getColorForKeyPath:@"TableView.TimeDetailTextColor"];
    return color ? color : [UIColor lightGrayColor];
}

-(UIFont *)tableViewSectionHeaderFont{
    return [self getFontWithKey:@"TableView.SectionHeaderTitle" andDefaultSize:FD_FONT_SIZE_NORMAL];
}

-(UIColor *)tableViewSectionHeaderFontColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.SectionHeaderTitleColor"];
    return color ? color : [HLTheme colorWithHex:FD_FEEDBACK_FONT_COLOR];
}

-(UIColor *)tableViewSectionHeaderBackgroundColor{
    UIColor *color = [self getColorForKeyPath:@"TableView.SectionHeaderBackgroundColor"];
    return color ? color : [HLTheme colorWithHex:FD_BACKGROUND_COLOR];
}

-(CGFloat)tableViewSectionHeaderHeight {
    CGFloat height = [[self.themePreferences valueForKeyPath:@"TableView.SectionHeaderHeight"] floatValue];
    return height ? height : 20.0f;
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

@end