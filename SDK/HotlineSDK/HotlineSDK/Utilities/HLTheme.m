//
//  HLTheme.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 30/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLTheme.h"
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

@end
