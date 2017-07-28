//
//  HLMessageCell.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "HLMessageCell.h"
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


@implementation HLMessageCell

@synthesize isAgentMessage,showsProfile,showsSenderName,customFontName,
            showsTimeStamp,showsUploadStatus,sentImage,sendingImage,
            messageSentTimeLabel,chatBubbleImageView,uploadStatusImageView,
            profileImageView,senderNameLabel,messageTextFont;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<HLMessageCellDelegate>)delegate{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.delegate = delegate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}

+(BOOL) showAgentAvatarLabel{
    static BOOL SHOW_AGENT_AVATAR_LABEL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SHOW_AGENT_AVATAR_LABEL = [HLLocalization isNotEmpty:LOC_MESSAGES_AGENT_LABEL_TEXT];
    });
    return SHOW_AGENT_AVATAR_LABEL;
}

- (void) initCell{
    
    self.maxcontentWidth = (NSInteger) self.contentView.frame.size.width - ((self.contentView.frame.size.width/100)*30) ;
    self.sentImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    self.sendingImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    self.showsProfile = YES;
    self.showsSenderName= NO;
    self.customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    self.showsUploadStatus=YES;
    self.showsTimeStamp=YES;
    self.chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    self.senderNameLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    
    [senderNameLabel setFont:[[HLTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[HLTheme sharedInstance] agentNameTextColor];
    [senderNameLabel setEditable:NO];
    [senderNameLabel setScrollEnabled:NO];
    [senderNameLabel setSelectable:NO];
    
    messageSentTimeLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    [messageSentTimeLabel setFont:[[HLTheme sharedInstance] getChatbubbleTimeFont]];
    [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
    [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
    [messageSentTimeLabel setEditable:NO];
    [messageSentTimeLabel setSelectable:NO];
    [messageSentTimeLabel setScrollEnabled:NO];
    messageSentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;

    profileImageView=[[UIImageView alloc] initWithFrame:CGRectZero];

    uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
    [uploadStatusImageView setImage:sentImage];
    uploadStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
}


- (void) drawMessageViewForMessage:(MessageData*)currentMessage parentView:(UIView*)parentView {
    
    [self clearAllSubviews];
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    FDSecureStore *store = [FDSecureStore sharedInstance];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    BOOL isAgentAvatarEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    BOOL isUserAvatarEnabled = FALSE;//Set Default as false will use it in later versions
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    UIImage *otherChatBubble = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_LEFT];
    UIImage *userChatBubble = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_RIGHT];
    UIEdgeInsets otherChatBubbleInsets= [[HLTheme sharedInstance] getAgentBubbleInsets];
    UIEdgeInsets userChatBubbleInsets= [[HLTheme sharedInstance] getUserBubbleInsets];
    
    isAgentMessage = [Konotor isUserMe:[currentMessage messageUserType]]?NO:YES; //Changed
    showsProfile = isAgentMessage?isAgentAvatarEnabled:isUserAvatarEnabled;
    
    UIView *contentEncloser = [[UIView alloc]init];
    contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    
    profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
    profileImageView.clipsToBounds = YES;
    profileImageView.contentMode = UIViewContentModeScaleAspectFit;
    profileImageView.layer.cornerRadius=KONOTOR_PROFILEIMAGE_DIMENSION/2;
    
    chatBubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    chatBubbleImageView.clipsToBounds = YES;
    
    [contentEncloser setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    
    [self.contentView addSubview:contentEncloser];
    [contentEncloser addSubview:chatBubbleImageView];
    [views setObject:contentEncloser forKey:@"contentEncloser"];
    [views setObject:chatBubbleImageView forKey:@"chatBubbleImageView"];
    
    if(isAgentMessage){ //Agent Message
        [chatBubbleImageView setImage:[otherChatBubble resizableImageWithCapInsets:otherChatBubbleInsets]];
    }
    else{ //User Message
        if([currentMessage uploadStatus].integerValue==2)  {
            [uploadStatusImageView setImage:sentImage];
        }
        else {
            [uploadStatusImageView setImage:sendingImage];
        }
        [views setObject:uploadStatusImageView forKey:@"uploadStatusImageView"];
        [contentEncloser addSubview:uploadStatusImageView];
        [chatBubbleImageView setImage:[userChatBubble resizableImageWithCapInsets:userChatBubbleInsets]];
    }
    
    showsSenderName = isAgentMessage && [HLMessageCell showAgentAvatarLabel]; //Buid considering always false
    if(showsSenderName){
        senderNameLabel.text=HLLocalizedString(LOC_MESSAGES_AGENT_LABEL_TEXT);
        //[views setObject:senderNameLabel forKey:@"senderNameLabel"]; Constraints not yet set.
    }
    
    
    if(showsProfile){
        if(isAgentMessage){
            profileImageView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
        }else{
            profileImageView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_USER];
        }
        profileImageView.frame = CGRectMake(0, 0, 40, 40);
        [self.contentView addSubview:profileImageView];
        [views setObject:profileImageView forKey:@"profileImageView"];
    }
    
    if(!currentMessage.isWelcomeMessage){
        messageSentTimeLabel.text = [FDStringUtil stringRepresentationForDate:date];
        messageSentTimeLabel.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [contentEncloser addSubview:messageSentTimeLabel];
        [views setObject:messageSentTimeLabel forKey:@"messageSentTimeLabel"]; //Constraints not yet set.
    }
    
    for(int i=0; i<currentMessage.fragments.count; i++) {
        FragmentData *fragment = currentMessage.fragments[i];
        if ([fragment.type isEqualToString:@"1"]) {
            //HTML
            FDHtmlFragment *htmlFragment = [[FDHtmlFragment alloc]initWithFragment:fragment];
            [views setObject:htmlFragment forKey:[@"text_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:htmlFragment];
            [fragmensViewArr addObject:[@"text_" stringByAppendingFormat:@"%d",i]];
            NSLog(@"HTML");
        } else if([fragment.type isEqualToString:@"2"]) {
            //IMAGE
            FDImageFragment *imageFragment = [[FDImageFragment alloc]initWithFragment:fragment ofMessage:currentMessage];
            imageFragment.delegate = self.delegate;
            [views setObject:imageFragment forKey:[@"image_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:imageFragment];
            [fragmensViewArr addObject:[@"image_" stringByAppendingFormat:@"%d",i]];
            NSLog(@"IMAGE");
        } else if([fragment.type isEqualToString:@"3"]) {
            //AUDIO
            //Skip now
            NSLog(@"AUDIO");
        } else if([fragment.type isEqualToString:@"4"]) {
            //VIDEO
            //Skip now
            NSLog(@"VIDEO");
        } else if([fragment.type isEqualToString:@"5"]) {
            //BTN
            FDFileFragment *fileFragment = [[FDFileFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            NSLog(@"BUTTON");
        } else if([fragment.type isEqualToString:@"6"]) {
            //FILE
            FDFileFragment *fileFragment = [[FDFileFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            NSLog(@"FILE");
        }
    }
    
    //All details are in contentview but no constrains set
    
    
    NSString *leftPadding = isAgentMessage ? @"10": @"(>=5)";
    NSString *rightPadding = isAgentMessage ? @"(>=5)": @"10";
    
    if(showsProfile) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[profileImageView(40)]-5-[contentEncloser]-%@-|",rightPadding] options:0 metrics:nil views:views]]; //Correct
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[profileImageView(40)]-5-|" options:0 metrics:nil views:views]];
    } else {
        if(isAgentMessage) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[contentEncloser]-%@-|",rightPadding] options:0 metrics:nil views: views]];
        } else {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-%@-[contentEncloser]-5-|",leftPadding] options:0 metrics:nil views: views]];
        }
    }
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
            if (isAgentMessage) {
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-(>=10)-[%@(%@)]-(>=5)-|",str,imageHeight];
                [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            } else {
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-(>=5)-[%@(%@)]-(>=10)-|",str,imageHeight];
                [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            }
            NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:imageFragment
                                                                                attribute:NSLayoutAttributeCenterX
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:contentEncloser
                                                                                attribute:NSLayoutAttributeCenterX
                                                                               multiplier:1
                                                                                 constant:0];
            [contentEncloser addConstraint:centerConstraint];
            
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(%@)]",str,imageWidth]];
        } else if([str containsString:@"text_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(>=0)]",str]];
        } else if([str containsString:@"button_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(>=50)]-%@-|",leftPadding,str,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(>=30)]",str]];
        }
    }
    
    if(!currentMessage.isWelcomeMessage) { //Show time for non welcome messages.
        [veriticalConstraint appendString:@"-5-[messageSentTimeLabel(20)]"];
        if(isAgentMessage) { //Show only time
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"H:|-5-[messageSentTimeLabel]-(>=5)-|" options:0 metrics:nil views:views]];
        } else { //Show time and upload status
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"H:|-(>=5)-[messageSentTimeLabel]-1-[uploadStatusImageView(10)]-10-|" options:0 metrics:nil views:views]];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"V:[uploadStatusImageView(10)]-5-|" options:0 metrics:nil views:views]];
        }
    }
    
    [veriticalConstraint appendString:@"-5-|"];
    //Constraints for details inside contentEncloser is done.
    if(![veriticalConstraint isEqualToString:@"V:|-5-|"]) {
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : veriticalConstraint options:0 metrics:nil views:views]];
    }
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
    self.tag=[currentMessage.messageId hash];
}

-(void) clearAllSubviews {
    NSArray *subViewArr = [self.contentView subviews];
    for (int i=0; i<[subViewArr count]; i++) {
        [subViewArr[i] removeFromSuperview];
    }
    
}

@end
