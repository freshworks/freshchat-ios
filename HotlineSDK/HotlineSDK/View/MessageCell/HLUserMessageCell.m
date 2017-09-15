//
//  HLUserMessageCell.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "HLUserMessageCell.h"
#import "FDUtilities.h"
#import "HLTheme.h"
#import "HLLocalization.h"
#import "FDSecureStore.h"

#import "FDDeeplinkFragment.h"
#import "FDHtmlFragment.h"
#import "FDImageFragment.h"
#import "FDVideoFragment.h"
#import "FDAudioFragment.h"
#import "FDFileFragment.h"

@implementation HLUserMessageCell

@synthesize messageSentTimeLabel,contentEncloser,maxcontentWidth,customFontName,
            showsTimeStamp,showsUploadStatus,sentImage,sendingImage,
            chatBubbleImageView,uploadStatusImageView,
            profileImageView,senderNameLabel,messageTextFont;

@synthesize userChatBubble,userChatBubbleInsets;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<HLUserMessageCellDelegate>)delegate{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.delegate = delegate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}

- (void) initCell{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenRect = screen.bounds;
    self.maxcontentWidth = (NSInteger) screenRect.size.width - ((screenRect.size.width/100)*20) ;
    self.sentImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    self.sendingImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    self.customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    self.showsUploadStatus=YES;
    self.showsTimeStamp=YES;
    self.chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    self.senderNameLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    contentEncloser = [[UIView alloc] init];
    contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    [contentEncloser setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    [self.contentView addSubview:contentEncloser];
    
    [senderNameLabel setFont:[[HLTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[HLTheme sharedInstance] agentNameFontColor];
    [senderNameLabel setEditable:NO];
    [senderNameLabel setScrollEnabled:NO];
    [senderNameLabel setSelectable:NO];
    
    messageSentTimeLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    messageSentTimeLabel.textColor = [[HLTheme sharedInstance] getChatbubbleTimeFontColor];
    [messageSentTimeLabel setFont:[[HLTheme sharedInstance] getChatbubbleTimeFont]];
    [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
    [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
    [messageSentTimeLabel setEditable:NO];
    [messageSentTimeLabel setSelectable:NO];
    [messageSentTimeLabel setScrollEnabled:NO];
    messageSentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    messageSentTimeLabel.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    profileImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
    profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
    profileImageView.clipsToBounds = YES;
    profileImageView.contentMode = UIViewContentModeScaleAspectFit;
    profileImageView.layer.cornerRadius=KONOTOR_PROFILEIMAGE_DIMENSION/2;
    
    chatBubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    chatBubbleImageView.clipsToBounds = YES;
    
    uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
    [uploadStatusImageView setImage:sentImage];
    uploadStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
    
    userChatBubble = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_RIGHT];
    userChatBubbleInsets= [[HLTheme sharedInstance] getUserBubbleInsets];
    
}


- (void) drawMessageViewForMessage:(MessageData*)currentMessage parentView:(UIView*)parentView {
    
    [self clearAllSubviews];
    
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    
    messageSentTimeLabel.text = [FDStringUtil stringRepresentationForDate:date];
    [chatBubbleImageView setImage:[userChatBubble resizableImageWithCapInsets:userChatBubbleInsets]];
    if([currentMessage uploadStatus].integerValue==2)  {
        [uploadStatusImageView setImage:sentImage];
    }
    else {
        [uploadStatusImageView setImage:sendingImage];
    }
    
    [views setObject:uploadStatusImageView forKey:@"uploadStatusImageView"];
    [views setObject:self.contentEncloser forKey:@"contentEncloser"];
    [views setObject:self.chatBubbleImageView forKey:@"chatBubbleImageView"];
    [views setObject:messageSentTimeLabel forKey:@"messageSentTimeLabel"];
    [contentEncloser addSubview:chatBubbleImageView];
    [contentEncloser addSubview:uploadStatusImageView];
    [contentEncloser addSubview:messageSentTimeLabel];
    [self.contentView addSubview:contentEncloser];
    
    
    for(int i=0; i<currentMessage.fragments.count; i++) {
        FragmentData *fragment = currentMessage.fragments[i];
        if ([fragment.type isEqualToString:@"1"]) {
            //HTML
            FDHtmlFragment *htmlFragment = [[FDHtmlFragment alloc]initWithFragment:fragment];
            htmlFragment.textColor = [[HLTheme sharedInstance] userMessageFontColor];
            [views setObject:htmlFragment forKey:[@"text_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:htmlFragment];
            [fragmensViewArr addObject:[@"text_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"HTML");
        } else if([fragment.type isEqualToString:@"2"]) {
            //IMAGE
            FDImageFragment *imageFragment = [[FDImageFragment alloc]initWithFragment:fragment ofMessage:currentMessage];
            imageFragment.userMessageDelegate = self.delegate;
            [views setObject:imageFragment forKey:[@"image_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:imageFragment];
            [fragmensViewArr addObject:[@"image_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"IMAGE");
        } else if([fragment.type isEqualToString:@"3"]) {
            //Skip now
            //NSLog(@"Audio");
        } else if([fragment.type isEqualToString:@"4"]) {
            //Skip now
            //NSLog(@"Video");
        } else if([fragment.type isEqualToString:@"5"] ) {
            //Skip now
            //NSLog(@"Button");
        } else if([fragment.type isEqualToString:@"6"]) {
            //Skip now
            //NSLog(@"File");
        }
    }
    
    //All details are in contentview but no constrains set
    
    
    NSString *leftPadding = @"(>=5)";
    NSString *rightPadding = @"10";
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[contentEncloser(<=%ld)]-5-|",(long)self.maxcontentWidth] options:0 metrics:nil views: views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[contentEncloser(>=50)]-5-|" options:0 metrics:nil views:views]];
    //Constraints for profileview and contentEncloser are done.
    
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    //Constraints for chatbubble are done.
    

    NSMutableString *veriticalConstraint = [[NSMutableString alloc]initWithString:@"V:|"];
    for(int i=0;i<fragmensViewArr.count;i++) { //Set Constraints here
        NSString *str = fragmensViewArr[i];
        if([str containsString:@"image_"]) {
            FDImageFragment *imageFragment = views[str];
            NSString *imageHeight = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.height];
            NSString *imageWidth = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.width];
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-(>=5)-[%@(%@)]-(>=10)-|",str,imageWidth];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:imageFragment
                                                                                attribute:NSLayoutAttributeCenterX
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:contentEncloser
                                                                                attribute:NSLayoutAttributeCenterX
                                                                               multiplier:1
                                                                                 constant:0];
            [contentEncloser addConstraint:centerConstraint];
            
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(<=%@)]",str,imageHeight]];
        } else if([str containsString:@"text_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(>=0)]",str]];
        }
    }
    
    if(!currentMessage.isWelcomeMessage) { //Show time for non welcome messages.
        [veriticalConstraint appendString:@"-5-[messageSentTimeLabel(<=20)]"];
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"H:|-(>=5)-[messageSentTimeLabel]-1-[uploadStatusImageView(10)]-10-|" options:0 metrics:nil views:views]];
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"V:[uploadStatusImageView(10)]-5-|" options:0 metrics:nil views:views]];
    }
    
    [veriticalConstraint appendString:@"-5-|"];
    //Constraints for details inside contentEncloser is done.
    if(![veriticalConstraint isEqualToString:@"V:|-5-|"]) {
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : veriticalConstraint options:0 metrics:nil views:views]];
    }
    self.tag=[currentMessage.messageId hash];
}

-(void) clearAllSubviews {
    NSArray *subViewArr = [self.contentEncloser subviews];
    for (int i=0; i<[subViewArr count]; i++) {
        [subViewArr[i] removeFromSuperview];
    }
    
}

@end
