//
//  STTweetLabel.h
//  STTweetLabel
//
//  Created by Sebastien Thiebaud on 09/29/13.
//  Copyright (c) 2013 Sebastien Thiebaud. All rights reserved.
//

typedef enum {
    STTweetHandle = 0,
    STTweetHashtag,
    STTweetLink
} STTweetHotWord;

#import <UIKit/UIKit.h>

@interface FDSTTweetLabel : UILabel

@property (nonatomic, strong) NSArray *validProtocols;
@property (nonatomic, assign) BOOL leftToRight;
@property (nonatomic, assign) BOOL textSelectable;
@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, assign) BOOL sent;
@property (nonatomic, strong) NSDictionary *attributesText;
@property (nonatomic, copy) void (^detectionBlock)(STTweetHotWord hotWord, NSString *string, NSString *protocol, NSRange range);

- (id)initWithFrame:(CGRect)frame andTextColor:(UIColor *)textColor;
- (void)setAttributes:(NSDictionary *)attributes;
- (void)setAttributes:(NSDictionary *)attributes hotWord:(STTweetHotWord)hotWord;

- (NSDictionary *)attributes;
- (NSDictionary *)attributesForHotWord:(STTweetHotWord)hotWord;

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width;

@end
