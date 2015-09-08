/*
 PTSMessagingCell.m
 
 Copyright (C) 2012 pontius software GmbH
 
 This program is free software: you can redistribute and/or modify
 it under the terms of the Createive Commons (CC BY-SA 3.0) license
*/

#import "FDMessagingCell.h"
#import "FDSecureStore.h"
#import "FDUtilities.h"
#import "FDMacros.h"
#import "FDArticle.h"
#import "MobiHelpDatabase.h"

@interface FDMessagingCell ()

@property (strong, nonatomic) UIView   *rateUsView;
@property (strong, nonatomic) FDButton *rateInAppStore;
@property (strong, nonatomic) UILabel  *rateUsMessage;
@property (strong, nonatomic) FDTheme  *theme;
@property (strong, nonatomic) FDSecureStore *secureStore;
@property (strong, nonatomic) NSLayoutConstraint *ratingMessageHeightConstraint;

@end

@implementation FDMessagingCell

static CGFloat textMarginHorizontal = 15.0f;
static CGFloat textMarginVertical   = 7.5f;

@synthesize sent, sentMessageLabel, receivedMessageLabel, sourceLabel, imagePreview, messageView, timeLabel, avatarImageView, balloonView, messageLabelFont = _messageLabelFont, source, ratingMessageHeightConstraint;


#pragma mark - Lazy Instantiations

-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}


#pragma mark Static methods

+(CGFloat)textMarginHorizontal {
    return textMarginHorizontal;
}

+(CGFloat)textMarginVertical {
    return textMarginVertical;
}

+(CGFloat)maxTextWidth {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)? 220.0f : 400.0f;
}

-(UIFont *)messageLabelFont{
    if(!_messageLabelFont){
        _messageLabelFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    }
    return _messageLabelFont;
}

-(void)setMessageLabelFont:(UIFont *)messageLabelFont{
    _messageLabelFont = messageLabelFont;
    self.sentMessageLabel.font = messageLabelFont;
    self.receivedMessageLabel.font = messageLabelFont;
}

+(CGSize)imageSize:(CGSize)imgSize forTextSize:(CGSize)txtSize {
    return CGSizeAspectFit(imgSize, CGSizeMake(MAX(txtSize.width,150), 150));
}

+(CGSize)messageSize:(NSString*)message forFont:(UIFont *)messageFont{
        NSDictionary *preferredAttributes = @{
                                              NSFontAttributeName:[UIFont fontWithName:messageFont.fontName size:messageFont.pointSize]
                                              };
        return [message boundingRectWithSize:CGSizeMake([FDMessagingCell maxTextWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:preferredAttributes context:nil].size;
        
}

+(CGSize)rateOnAppStoreLabelSize:(NSString*)ratingMessage forFont:(UIFont *)reviewFont {
    NSDictionary *preferredAttributes = @{
                                          NSFontAttributeName:[UIFont fontWithName:reviewFont.fontName size:reviewFont.pointSize]
                                          };
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)]) {
            return [ratingMessage boundingRectWithSize:CGSizeMake([UIScreen mainScreen].nativeBounds.size.height/ceilf([UIScreen mainScreen].nativeScale) - 20.0f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:preferredAttributes context:nil].size;
        }
        
        else {
            return [ratingMessage boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.height, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:preferredAttributes context:nil].size;
        }
    }

    else {
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(nativeBounds)]) {
            return [ratingMessage boundingRectWithSize:CGSizeMake([UIScreen mainScreen].nativeBounds.size.width/ceilf([UIScreen mainScreen].nativeScale) - 20.0f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:preferredAttributes context:nil].size;
        }
        
        else {
            return [ratingMessage boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:preferredAttributes context:nil].size;
        }
    }
}


+(UIImage*)balloonImage:(BOOL)sent isSelected:(BOOL)selected {
    FDTheme *theme = [FDTheme sharedInstance];
    UIImage *rightBubbleImage = [theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_CHAT_VIEW_RIGHT_BUBBLE];
    UIImage *leftBubbleImage  = [theme getThemedImageFromMHBundleWithName:MOBIHELP_IMAGE_CHAT_VIEW_LEFT_BUBBLE];
    [rightBubbleImage stretchableImageWithLeftCapWidth:24 topCapHeight:15];
    if (sent) {
        return [rightBubbleImage stretchableImageWithLeftCapWidth:24 topCapHeight:15];
    }else{
        return [leftBubbleImage stretchableImageWithLeftCapWidth:24 topCapHeight:15];
    }
}

#pragma mark Object-Lifecycle/Memory management

-(id)initMessagingCellWithReuseIdentifier:(NSString*)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        /*Selection-Style of the TableViewCell will be 'None' as it implements its own selection-style.*/
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        /*Now the basic view-lements are initialized...*/
        
        balloonView = [[UIImageView alloc] initWithFrame:CGRectZero];
        balloonView.userInteractionEnabled = YES;
        
        sentMessageLabel = [[FDSTTweetLabel alloc] initWithFrame:CGRectZero andTextColor:[self.theme sentMessageFontColor]];
        
        __weak typeof(self) weakSelf = self;
        
        [sentMessageLabel setDetectionBlock:^(STTweetHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
            if ([string hasPrefix:protocol]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
            }
            
            else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@",protocol,string]]];
            }
        }];
        
        receivedMessageLabel = [[FDSTTweetLabel alloc] initWithFrame:CGRectZero andTextColor:[self.theme receivedMessageFontColor]];
        
        [receivedMessageLabel setDetectionBlock:^(STTweetHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
            if ([string hasPrefix:protocol]) {
                [weakSelf openDeeplink:string];
            }
            
            else {
                [weakSelf openDeeplink:[NSString stringWithFormat:@"%@://%@",protocol,string]];
            }
        }];
        
        imagePreview = [[UIImageView alloc] initWithImage:nil];

        sourceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        avatarImageView = [[UIImageView alloc] initWithImage:nil];
       
        /*Message-Label*/
        self.sentMessageLabel.backgroundColor = [UIColor clearColor];
        self.receivedMessageLabel.backgroundColor = [UIColor clearColor];
        
        /*Source-Label*/
        self.sourceLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:11.0f];
        self.sourceLabel.textColor = [UIColor darkGrayColor];
        self.sourceLabel.backgroundColor = [UIColor clearColor];

        /*Time-Label*/
        self.timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.0f];
        self.timeLabel.textColor = [UIColor darkGrayColor];
        self.timeLabel.backgroundColor = [UIColor clearColor];

        /*...and adds them to the view.*/
        [self addSubview: self.balloonView];
    
        [self addSubview: self.sentMessageLabel];
        [self addSubview:self.receivedMessageLabel];
        
        [self addSubview: self.imagePreview];
        
        [self addSubview: self.sourceLabel];
        [self addSubview: self.timeLabel];
        [self addSubview: self.avatarImageView];
    }
    return self;
}

-(id)initRatingCellWithReuseIdentifier:(NSString*)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.rateUsView = [[UIView alloc] init];
        self.rateUsView.backgroundColor = [self.theme backgroundColorSDK];
        [self addSubview:self.rateUsView];
        [self.rateUsView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        self.rateUsMessage = [[UILabel alloc] init];
        self.rateUsMessage.font = [UIFont fontWithName:[self.theme rateOnAppStoreLabelFontName] size:[self.theme rateOnAppStoreLabelFontSize]];
        UIColor *rateUsMessageTextColor = [self.theme rateOnAppStoreLabelColor];
        self.rateUsMessage.textColor = rateUsMessageTextColor;
        self.rateUsMessage.text = FDLocalizedString(@"Review Label Text" );
        self.rateUsMessage.textAlignment = NSTextAlignmentCenter;
        self.rateUsMessage.numberOfLines = 0;
        self.rateUsMessage.lineBreakMode = NSLineBreakByWordWrapping;
        [self.rateUsMessage setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.rateUsView addSubview:self.rateUsMessage];
        
        self.rateInAppStore = [FDButton buttonWithType:UIButtonTypeRoundedRect];
        self.rateInAppStore.translatesAutoresizingMaskIntoConstraints = NO;
        self.rateInAppStore.userInteractionEnabled = YES;
        [self.rateInAppStore addTarget:self action:@selector(ratingButtonTapped:) forControlEvents:UIControlEventAllTouchEvents];
        [self.rateInAppStore setTitle:FDLocalizedString(@"Review Button Text" ) forState:UIControlStateNormal];
        UIColor *rateUsButtonTintColor = [self.theme rateOnAppStoreButtonTintColor];
        [self.rateInAppStore setTitleColor:rateUsButtonTintColor forState:UIControlStateNormal];
        [self.rateInAppStore setTitleEdgeInsets:UIEdgeInsetsMake(5, 10, 5, 10)];
        self.rateInAppStore.backgroundColor = [UIColor clearColor];
        self.rateInAppStore.layer.borderWidth = 1.0f;
        self.rateInAppStore.layer.cornerRadius = 5.0f;
        self.rateInAppStore.layer.borderColor = [rateUsButtonTintColor CGColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.rateInAppStore.titleLabel.numberOfLines = 1;
        self.rateInAppStore.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.rateInAppStore.titleLabel.lineBreakMode = NSLineBreakByClipping;
        self.rateInAppStore.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.rateUsView addSubview: self.rateInAppStore];
        
        UIFont *reviewLabelFont = [UIFont fontWithName:[self.theme rateOnAppStoreLabelFontName] size:[self.theme rateOnAppStoreLabelFontSize]];
        CGSize ratingMessageSize = [FDMessagingCell rateOnAppStoreLabelSize:FDLocalizedString(@"Review Label Text") forFont:reviewLabelFont];
        
        ratingMessageHeightConstraint = [NSLayoutConstraint constraintWithItem:self.rateUsMessage
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:(ratingMessageSize.height)];

        [self layoutReviewCell];
    }
    
    return self;
}

-(void)ratingButtonTapped:(UIButton*)button{
    NSString *appStoreID = [self.secureStore objectForKey:MOBIHELP_DEFAULTS_APP_STORE_ID];
    NSString *reviewURL  = [NSString stringWithFormat:@"https://itunes.apple.com/app/%@",appStoreID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
}


#pragma mark Layouting

- (void)layoutSubviews {
    
    if ([self.source isEqualToNumber:@11]) {
        UIFont *reviewLabelFont = [UIFont fontWithName:[self.theme rateOnAppStoreLabelFontName] size:[self.theme rateOnAppStoreLabelFontSize]];
        CGSize ratingMessageSize = [FDMessagingCell rateOnAppStoreLabelSize:FDLocalizedString(@"Review Label Text") forFont:reviewLabelFont];
        
        ratingMessageHeightConstraint.constant = ratingMessageSize.height;

    }
    /*This method layouts the TableViewCell. It calculates the frame for the different subviews, to set the layout according to size and orientation.*/
    
    /*Calculates the size of the message. */
    
    CGSize textSize;
    CGSize imageSize;

    if (self.sent == YES) {
        textSize = [FDMessagingCell messageSize:self.sentMessageLabel.text forFont:[UIFont fontWithName:[self.theme chatBubbleFontName] size:[self.theme chatBubbleFontSize]]];
    }
    
    else {
        textSize = [FDMessagingCell messageSize:self.receivedMessageLabel.text forFont:[UIFont fontWithName:[self.theme chatBubbleFontName] size:[self.theme chatBubbleFontSize]]];
    }
    
    if (self.imagePreview.image != nil) {
        
        imageSize = CGSizeAspectFit(self.imagePreview.image.size, CGSizeMake(MAX(textSize.width,150), 150));

    }
    
    else {
        imageSize = CGSizeZero;
    }
    
    /*Calculates the size of the source text.*/
    CGSize maximumLabelSize = CGSizeMake([FDMessagingCell maxTextWidth], MAXFLOAT);
    
    CGSize sourceSize = [self.sourceLabel.text boundingRectWithSize:maximumLabelSize options:0 attributes:nil context:nil].size;

    CGSize dateSize = [self.timeLabel.text boundingRectWithSize:maximumLabelSize options:0 attributes:nil context:nil].size;

    /*Initializes the different frames , that need to be calculated.*/
    CGRect ballonViewFrame = CGRectZero;
    CGRect sentMessageLabelFrame = CGRectZero;
    CGRect receivedMessageLabelFrame = CGRectZero;
    CGRect imagePreviewFrame = CGRectZero;
    CGRect sourceLabelFrame = CGRectZero;
    CGRect timeLabelFrame = CGRectZero;
    CGRect avatarImageFrame = CGRectZero;

    if (self.sent == YES) {
        
        sourceLabelFrame = CGRectMake(self.frame.size.width - sourceSize.width - textMarginHorizontal, ballonViewFrame.origin.y + ballonViewFrame.size.height, sourceSize.width, sourceSize.height);
        
        if (self.imagePreview.image != nil) {
            ballonViewFrame = CGRectMake(self.frame.size.width - (MAX(textSize.width,imageSize.width) + 2*textMarginHorizontal) - 10.0f, sourceLabelFrame.size.height + 2, MAX(textSize.width,imageSize.width) + 2*textMarginHorizontal, textSize.height + imageSize.height + 2*textMarginVertical);

            sentMessageLabelFrame = CGRectMake(ballonViewFrame.origin.x + (ballonViewFrame.size.width - MAX(imageSize.width,textSize.width) )/2 - textMarginHorizontal/2,  ballonViewFrame.origin.y + imageSize.height + textMarginVertical, MAX(imageSize.width,textSize.width) + textMarginHorizontal/2, textSize.height + 2*textMarginVertical);
        }
        
        else {
            ballonViewFrame = CGRectMake(self.frame.size.width - (textSize.width + 2*textMarginHorizontal) - 10.0f, sourceLabelFrame.size.height + 2, textSize.width + 2*textMarginHorizontal, textSize.height + 2*textMarginVertical);
            
            sentMessageLabelFrame = CGRectMake(self.frame.size.width - (textSize.width + textMarginHorizontal) - 2 - 10.0f - 2,  ballonViewFrame.origin.y + textMarginVertical/2, textSize.width+1, textSize.height + 2*textMarginVertical);
        }
        
        timeLabelFrame = CGRectMake(self.frame.size.width - dateSize.width - textMarginHorizontal + 14.0f, ballonViewFrame.origin.y + ballonViewFrame.size.height, dateSize.width, dateSize.height);

        imagePreviewFrame = CGRectMake(ballonViewFrame.origin.x + (ballonViewFrame.size.width - imageSize.width)/2 - 9.0f,  ballonViewFrame.origin.y + textMarginVertical - 2, imageSize.width+10, imageSize.height+2);
        
        avatarImageFrame = CGRectMake(5.0f, sourceLabelFrame.size.height, 50.0f, 50.0f);
        
        self.sentMessageLabel.frame = sentMessageLabelFrame;
        self.receivedMessageLabel.frame = CGRectZero;
        
    } else {
        
        sourceLabelFrame = CGRectMake(textMarginHorizontal, 0.0f, sourceSize.width, sourceSize.height);
    
        ballonViewFrame = CGRectMake(10.0f, sourceLabelFrame.size.height + 2, textSize.width + 2*textMarginHorizontal, textSize.height + 2*textMarginVertical);
    
        timeLabelFrame = CGRectMake(textMarginHorizontal + 4.0f, ballonViewFrame.origin.y + ballonViewFrame.size.height, dateSize.width, dateSize.height);

        receivedMessageLabelFrame = CGRectMake(textMarginHorizontal + 2 + 10.0f + 2, ballonViewFrame.origin.y + textMarginVertical/2, textSize.width+1, textSize.height + 2*textMarginVertical);
        
        
        avatarImageFrame = CGRectMake(self.frame.size.width - 55.0f, sourceLabelFrame.size.height, 50.0f, 50.0f);
        
        self.receivedMessageLabel.frame = receivedMessageLabelFrame;
        self.sentMessageLabel.frame = CGRectZero;
    }
    self.balloonView.image = [FDMessagingCell balloonImage:self.sent isSelected:self.selected];
    
    /*Sets the pre-initialized frames  for the balloonView and messageView.*/
    self.balloonView.frame = ballonViewFrame;

    /*If shown (and loaded), sets the frame for the ImagePreview*/
    if (self.imagePreview.image != nil) {
        self.imagePreview.frame = imagePreviewFrame;
    }

    /*If shown (and loaded), sets the frame for the avatarImageView*/
    if (self.avatarImageView.image != nil) {
        self.avatarImageView.frame = avatarImageFrame;
    }
    
    /*If there is next for the sourceLabel, sets the frame of the sourceLabel.*/
    
    if (self.sourceLabel.text != nil) {
        self.sourceLabel.frame = sourceLabelFrame;
    }

    if (self.timeLabel.text != nil) {
        self.timeLabel.frame = timeLabelFrame;
    }
}

- (void)layoutReviewCell {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsView
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsView
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsView
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsView
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1.0
                                                      constant:0.0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsMessage
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.rateUsView
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsMessage
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.rateUsView
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1.0
                                                      constant:5.0]];
    
//    UIFont *reviewLabelFont = [UIFont fontWithName:[self.theme rateOnAppStoreLabelFontName] size:[self.theme rateOnAppStoreLabelFontSize]];
//    CGSize ratingMessageSize = [FDMessagingCell rateOnAppStoreLabelSize:FDLocalizedString(@"Review Label Text") forFont:reviewLabelFont];
    
    [self addConstraint:ratingMessageHeightConstraint];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateUsMessage
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.rateUsView
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1.0
                                                      constant:-5.0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateInAppStore
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.rateUsMessage
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:10.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateInAppStore
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.rateUsView
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1.0
                                                      constant:20.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateInAppStore
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1.0
                                                      constant:40.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rateInAppStore
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.rateUsView
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1.0
                                                      constant:-20.0]];
}

CGSize CGSizeAspectFit(CGSize aspectRatio, CGSize boundingSize)
{
    float mW = boundingSize.width / aspectRatio.width;
    float mH = boundingSize.height / aspectRatio.height;
    if( mH < mW )
        boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
    else if( mW < mH )
        boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
    return boundingSize;
}

- (void)openDeeplink:(NSString *)URL {
    [self.delegate receiveSolutionLinkTap:URL];
}


@end
