//
//  HLMessageCell.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "HLAgentMessageCell.h"
#import "FDUtilities.h"
#import "FCTheme.h"
#import "HLLocalization.h"
#import "FDSecureStore.h"

#import "FDDeeplinkFragment.h"
#import "FDHtmlFragment.h"
#import "FDImageFragment.h"
#import "FDVideoFragment.h"
#import "FDAudioFragment.h"
#import "FDFileFragment.h"
#import "FDAutolayoutHelper.h"
#import "FDParticipant.h"
#import "FDImageView.h"
#import "FCRemoteConfig.h"
#import "FDSecureStore.h"

@interface HLAgentMessageCell ()

@property (strong, nonatomic) NSLayoutConstraint *senderLabelHeight;
@property (nonatomic, strong) NSString *agentName;
@property (nonatomic, assign) BOOL showRealAvatar;

@end

@implementation HLAgentMessageCell

@synthesize contentEncloser,maxcontentWidth,showsProfile,showsSenderName,customFontName,
            showsTimeStamp,showsUploadStatus,sentImage,sendingImage;
@synthesize messageSentTimeLabel,chatBubbleImageView,uploadStatusImageView,
            profileImageView,senderNameLabel,messageTextFont,agentChatBubble,agentChatBubbleInsets;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<HLMessageCellDelegate>)delegate{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.delegate = delegate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}

-(BOOL) showAgentAvatarLabelWithAlias : (NSString *)alias {
    static BOOL SHOW_AGENT_AVATAR_LABEL;
    FDParticipant *participant = [FDParticipant fetchParticipantForAlias:alias inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    
    if(participant.firstName || participant.lastName){
        self.agentName = [FDUtilities appendFirstName:participant.firstName withLastName:participant.lastName];
        SHOW_AGENT_AVATAR_LABEL = TRUE;
    }
    else if ([HLLocalization isNotEmpty:LOC_MESSAGES_AGENT_LABEL_TEXT]){
        self.agentName = HLLocalizedString(LOC_MESSAGES_AGENT_LABEL_TEXT);
        SHOW_AGENT_AVATAR_LABEL = TRUE;
    }
    else{
        SHOW_AGENT_AVATAR_LABEL = false;
    }
    return SHOW_AGENT_AVATAR_LABEL;
}

- (void) initCell{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenRect = screen.bounds;
    self.maxcontentWidth = (NSInteger) screenRect.size.width - ((screenRect.size.width/100)*20) ;
    self.sentImage=[[FCTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    self.sendingImage=[[FCTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    self.showsProfile = NO;
    self.showsSenderName= NO;
    self.customFontName=[[FCTheme sharedInstance] conversationUIFontName];
    self.showsUploadStatus=YES;
    self.showsTimeStamp=YES;
    self.chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.senderNameLabel=[[UILabel alloc] initWithFrame:CGRectZero];
    contentEncloser = [[UIView alloc] init];
    contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    [contentEncloser setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    
    
    [senderNameLabel setFont:[[FCTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.numberOfLines = 1;
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[FCTheme sharedInstance] agentNameFontColor];
    
    messageSentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    messageSentTimeLabel.numberOfLines = 0;
    messageSentTimeLabel.textColor = [[FCTheme sharedInstance] getChatbubbleTimeFontColor];
    [messageSentTimeLabel setFont:[[FCTheme sharedInstance] getChatbubbleTimeFont]];
    [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
    [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
    messageSentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
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
    
    BOOL isAgentAvatarEnabled = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    if(isAgentAvatarEnabled){
        int agentAvatarRCVal = [FCRemoteConfig sharedInstance].conversationConfig.agentAvatar;
        self.showsProfile = (agentAvatarRCVal <= 2);
        self.showRealAvatar = (agentAvatarRCVal == 1);
    }
    
    agentChatBubble = [[FCTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_LEFT];
    agentChatBubbleInsets= [[FCTheme sharedInstance] getAgentBubbleInsets];

    [chatBubbleImageView setImage:[agentChatBubble resizableImageWithCapInsets:agentChatBubbleInsets]];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
}


- (void) drawMessageViewForMessage:(MessageData*)currentMessage parentView:(UIView*)parentView {
    
    [self clearAllSubviews];
    showsSenderName = [self showAgentAvatarLabelWithAlias:currentMessage.messageUserAlias];
    self.showsProfile = true;
    self.showRealAvatar = true;
    
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    [views setObject:self.contentEncloser forKey:@"contentEncloser"];
    [views setObject:self.chatBubbleImageView forKey:@"chatBubbleImageView"];
    FDParticipant *participant = [FDParticipant fetchParticipantForAlias:currentMessage.messageUserAlias inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    senderNameLabel.text = self.agentName;
    [contentEncloser addSubview:chatBubbleImageView];
    [views setObject:self.senderNameLabel forKey:@"senderLabel"];
    [self.contentView addSubview:senderNameLabel];

    if(showsProfile){
        profileImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
        
        profileImageView.frame = CGRectMake(0, 0, 40, 40);
        [self.contentView addSubview:profileImageView];
        [views setObject:profileImageView forKey:@"profileImageView"];
        
        if(participant.profilePicURL && self.showRealAvatar){
            FDWebImageManager *manager = [FDWebImageManager sharedManager];
            if(participant)
                [manager loadImageWithURL:[NSURL URLWithString:participant.profilePicURL] options:FDWebImageDelayPlaceholder progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                    
                } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, FDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                    if(image && finished){
                        profileImageView.image = image;
                    }
                    else{
                        profileImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
                    }
                }];
        }
        else{
            profileImageView.image = [[FCTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
        }
    }
    
    if(!currentMessage.isWelcomeMessage){
        NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
        messageSentTimeLabel.text = [FDStringUtil stringRepresentationForDate:date];
        [contentEncloser addSubview:messageSentTimeLabel];
        [views setObject:messageSentTimeLabel forKey:@"messageSentTimeLabel"]; //Constraints not yet set.
    }
    
    [self.contentView addSubview:contentEncloser];
    
    
    for(int i=0; i<currentMessage.fragments.count; i++) {
        FragmentData *fragment = currentMessage.fragments[i];
        if ([fragment.type isEqualToString:@"1"]) {
            //HTML
            FDHtmlFragment *htmlFragment = [[FDHtmlFragment alloc]initWithFragment:fragment];
            htmlFragment.textColor = [[FCTheme sharedInstance] agentMessageFontColor];
            [views setObject:htmlFragment forKey:[@"text_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:htmlFragment];
            [fragmensViewArr addObject:[@"text_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"HTML");
        } else if([fragment.type isEqualToString:@"2"]) {
            //IMAGE
            FDImageFragment *imageFragment = [[FDImageFragment alloc]initWithFragment:fragment ofMessage:currentMessage];
            imageFragment.agentMessageDelegate = self.delegate;
            [views setObject:imageFragment forKey:[@"image_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:imageFragment];
            [fragmensViewArr addObject:[@"image_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"IMAGE");
        } else if([fragment.type isEqualToString:@"3"]) {
            //AUDIO
            //Skip now
            //NSLog(@"AUDIO");
        } else if([fragment.type isEqualToString:@"4"]) {
            FDVideoFragment *fileFragment = [[FDVideoFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"VIDEO");
        } else if([fragment.type isEqualToString:@"5"]) {
            FDDeeplinkFragment *fileFragment = [[FDDeeplinkFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            fileFragment.agentMessageDelegate = self.delegate;
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"BUTTON");
        } else if([fragment.type isEqualToString:@"6"]) {
            FDFileFragment *fileFragment = [[FDFileFragment alloc] initWithFragment:fragment];
            [views setObject:fileFragment forKey:[@"button_" stringByAppendingFormat:@"%d",i]];
            [contentEncloser addSubview:fileFragment];
            [fragmensViewArr addObject:[@"button_" stringByAppendingFormat:@"%d",i]];
            //NSLog(@"FILE");
        }
    }
    
    //All details are in contentview but no constrains set
    
    
    NSString *leftPadding = @"5";
    NSString *rightPadding = @"(>=5)";
    
    if(showsProfile) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[profileImageView(40)]-5-[contentEncloser(<=%ld)]",(long)self.maxcontentWidth] options:0 metrics:nil views:views]]; //Correct
        if(showsSenderName) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[profileImageView(40)]-5-[senderLabel(<=%ld)]",(long)self.maxcontentWidth] options:0 metrics:nil views:views]]; //Correct
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[senderLabel]-2-[profileImageView(40)]" options:0 metrics:nil views:views]];
        } else {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[profileImageView(40)]" options:0 metrics:nil views:views]];
        }
    } else {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[contentEncloser(<=%ld)]",(long)self.maxcontentWidth] options:0 metrics:nil views: views]];
        if(showsSenderName) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[senderLabel]-(<=%ld)-|",(long)self.maxcontentWidth] options:0 metrics:nil views: views]];
        }
    }
    
    
    if(showsSenderName) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[senderLabel]-2-[contentEncloser(>=50)]-5-|" options:0 metrics:nil views:views]];
    } else {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[contentEncloser(>=50)]-2-|" options:0 metrics:nil views:views]];
    }
    //Constraints for profileview and contentEncloser are done.
    
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    //Constraints for chatbubble are done.
    
    BOOL welcomeTextMsg = (currentMessage.isWelcomeMessage && fragmensViewArr.count == 1);
    
    NSMutableString *veriticalConstraint = [[NSMutableString alloc]initWithString:@"V:|"];
    for(int i=0;i<fragmensViewArr.count;i++) { //Set Constraints here
        NSString *str = fragmensViewArr[i];
        if([str containsString:@"image_"]) {
            FDImageFragment *imageFragment = views[str];
            NSString *imageHeight = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.height];
            NSString *imageWidth = [NSString stringWithFormat:@"%d",(int)imageFragment.imgFrame.size.width];
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-(>=10)-[%@(%@)]-(>=5)-|",str,imageWidth];
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
            if(welcomeTextMsg) { //If it has only text message in welcome message
                FDHtmlFragment *textFragment = views[str];
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
                [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
                NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:textFragment
                                                                                    attribute:NSLayoutAttributeCenterY
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:contentEncloser
                                                                                    attribute:NSLayoutAttributeCenterY
                                                                                   multiplier:1
                                                                                     constant:0];
                [contentEncloser addConstraint:centerConstraint];
                [veriticalConstraint appendString:[NSString stringWithFormat:@"-(>=5)-[%@(>=0)]",str]];
            } else {
                NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
                [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
                [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(>=0)]",str]];
            }
        } else if([str containsString:@"button_"]) {
            
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(>=75)]-%@-|",@"10",str,@"(>=10)"];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@]",str]];
        }
    }
    if(!currentMessage.isWelcomeMessage) { //Show time for non welcome messages.
        [veriticalConstraint appendString:@"-5-[messageSentTimeLabel]"];
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"H:|-10-[messageSentTimeLabel]-(>=10)-|" options:0 metrics:nil views:views]];
    }
    if(welcomeTextMsg) {
        [veriticalConstraint appendString:@"-(>=5)-|"];
    } else {
        [veriticalConstraint appendString:@"-5-|"];
    }
    //Constraints for details inside contentEncloser is done.
    if(![veriticalConstraint isEqualToString:@"V:|-5-|"]) {
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : veriticalConstraint options:0 metrics:nil views:views]];
    }
    self.tag=[currentMessage.messageId hash];
}

-(void) clearAllSubviews {
    NSArray *contentEnclosersubViewArr = [self.contentEncloser subviews];
    for (int i=0; i<[contentEnclosersubViewArr count]; i++) {
        [contentEnclosersubViewArr[i] removeFromSuperview];
    }
    NSArray *subViewArr = [self.contentView subviews];
    for (int i=0; i<[subViewArr count]; i++) {
        [subViewArr[i] removeFromSuperview];
    }
    
}

@end
