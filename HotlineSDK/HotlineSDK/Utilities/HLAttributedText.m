//
//  HLAttributedText.m
//  HotlineSDK
//
//  Created by user on 01/08/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLAttributedText.h"
#import "FCTheme.h"

@interface HLAttributedText ()

@property (strong, nonatomic) NSMutableDictionary *data;

@end

@implementation HLAttributedText

+ (instancetype)sharedInstance{
    static HLAttributedText *sharedHLAttributedText = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHLAttributedText = [[self alloc]init];
    });
    return sharedHLAttributedText;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.data = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(NSMutableAttributedString *) getAttributedString:(NSString *)string  {
    return self.data[string];
}

-(NSMutableAttributedString *) addAttributedString:(NSString *)string withFont:(UIFont*) font   {
    NSString *HTML = [NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%i\">%@</span>",font.fontName,(int)font.pointSize,string];
    NSMutableAttributedString *attributedTitleString = [[NSMutableAttributedString alloc] initWithData:[HTML dataUsingEncoding:NSUnicodeStringEncoding]
                                                                                               options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                                                    documentAttributes:nil error:nil];
    NSRange range = NSMakeRange(0, attributedTitleString.length);
    [attributedTitleString.mutableString replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:range];
    self.data[string] = attributedTitleString;
    return attributedTitleString;
}


@end
