//
//  HLMessageCell.m
//  HotlineSDK
//
//  Created by user on 28/07/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import "HLAgentMessageCell.h"
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
#import "FDAutolayoutHelper.h"
#import "FDParticipant.h"
#import "FDImageView.h"

@interface HLAgentMessageCell ()

@property (strong, nonatomic) NSLayoutConstraint *senderLabelHeight;

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

+(BOOL) showAgentAvatarLabel{
    static BOOL SHOW_AGENT_AVATAR_LABEL;
    FDParticipant *participant; //= [FDParticipant fetchParticipantForAlias:<#(NSString *)#> :<#(NSManagedObjectContext *)#>
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (participant.firstName || participant.lastName || [HLLocalization isNotEmpty:LOC_MESSAGES_AGENT_LABEL_TEXT]){
            SHOW_AGENT_AVATAR_LABEL = TRUE;
        }
    });
    return SHOW_AGENT_AVATAR_LABEL;
}

- (void) initCell{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect screenRect = screen.bounds;
    self.maxcontentWidth = (NSInteger) screenRect.size.width - ((screenRect.size.width/100)*20) ;
    self.sentImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    self.sendingImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    self.showsProfile = YES;
    self.showsSenderName= NO;
    self.customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    self.showsUploadStatus=YES;
    self.showsTimeStamp=YES;
    self.chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    self.senderNameLabel=[[UILabel alloc] initWithFrame:CGRectZero];
    contentEncloser = [[UIView alloc] init];
    contentEncloser.translatesAutoresizingMaskIntoConstraints = NO;
    [contentEncloser setLayoutMargins:UIEdgeInsetsMake(0,0,0,0)];
    
    
    [senderNameLabel setFont:[[HLTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[HLTheme sharedInstance] agentNameTextColor];
    
    messageSentTimeLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    [messageSentTimeLabel setFont:[[HLTheme sharedInstance] getChatbubbleTimeFont]];
    [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
    [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
    [messageSentTimeLabel setEditable:NO];
    [messageSentTimeLabel setSelectable:NO];
    [messageSentTimeLabel setScrollEnabled:NO];
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
    
    showsProfile = [[FDSecureStore sharedInstance] boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    showsSenderName = [HLAgentMessageCell showAgentAvatarLabel]; //Buid considering always false
    
    agentChatBubble = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_LEFT];
    agentChatBubbleInsets= [[HLTheme sharedInstance] getAgentBubbleInsets];

    [chatBubbleImageView setImage:[agentChatBubble resizableImageWithCapInsets:agentChatBubbleInsets]];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
}


- (void) drawMessageViewForMessage:(MessageData*)currentMessage parentView:(UIView*)parentView {
    
    [self clearAllSubviews];
    
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    NSMutableDictionary *views = [[NSMutableDictionary alloc]init];
    [views setObject:self.contentEncloser forKey:@"contentEncloser"];
    [views setObject:self.chatBubbleImageView forKey:@"chatBubbleImageView"];
    int senderNameHeight = self.senderNameLabel.intrinsicContentSize.height;
    self.senderLabelHeight = [FDAutolayoutHelper setHeight:senderNameHeight forView:self.senderNameLabel inView:self.contentEncloser];
    FDParticipant *participant = [FDParticipant fetchParticipantForAlias:currentMessage.messageUserAlias inContext:[KonotorDataManager sharedInstance].mainObjectContext];
    if(showsSenderName){
        if(participant.firstName || participant.lastName){
            senderNameLabel.text = [FDUtilities appendFirstName:participant.firstName withLastName:participant.lastName];
        }
        else{
            senderNameLabel.text = HLLocalizedString(LOC_MESSAGES_AGENT_LABEL_TEXT);
        }
    }
    self.senderLabelHeight.constant =senderNameHeight;
    [contentEncloser addSubview:chatBubbleImageView];
    [contentEncloser addSubview:senderNameLabel];
    [views setObject:self.senderNameLabel forKey:@"senderLabel"];
    
    if(showsProfile){
        profileImageView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
        
        profileImageView.frame = CGRectMake(0, 0, 40, 40);
        [self.contentView addSubview:profileImageView];
        [views setObject:profileImageView forKey:@"profileImageView"];
        
        
        FDWebImageManager *manager = [FDWebImageManager sharedManager];
        
        [manager loadImageWithURL:[NSURL URLWithString:@"https://www.atomix.com.au/media/2015/06/atomix_user31.png"] options:FDWebImageDelayPlaceholder progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, FDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            if(image && finished){
                profileImageView.image = image;
            }
            else{
                profileImageView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
            }
        }];
    }
    
    if(!currentMessage.isWelcomeMessage){
        NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
        messageSentTimeLabel.text = [FDStringUtil stringRepresentationForDate:date];
        messageSentTimeLabel.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [contentEncloser addSubview:messageSentTimeLabel];
        [views setObject:messageSentTimeLabel forKey:@"messageSentTimeLabel"]; //Constraints not yet set.
    }
    
    [self.contentView addSubview:contentEncloser];
    
    
    for(int i=0; i<currentMessage.fragments.count; i++) {
        FragmentData *fragment = currentMessage.fragments[i];
        if ([fragment.type isEqualToString:@"1"]) {
            //HTML
            FDHtmlFragment *htmlFragment = [[FDHtmlFragment alloc]initWithFragment:fragment];
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
    
    
    NSString *leftPadding = @"10";
    NSString *rightPadding = @"(>=5)";
    
    if(showsProfile) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[profileImageView(40)]-5-[contentEncloser(<=%ld)]",(long)self.maxcontentWidth] options:0 metrics:nil views:views]]; //Correct
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[profileImageView(40)]-5-|" options:0 metrics:nil views:views]];
    } else {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-5-[contentEncloser(<=%ld)]",(long)self.maxcontentWidth] options:0 metrics:nil views: views]];
   
    }
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[contentEncloser(>=50)]-5-|" options:0 metrics:nil views:views]];
    //Constraints for profileview and contentEncloser are done.
    
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[chatBubbleImageView]-|" options:0 metrics:nil views:views]];
    //Constraints for chatbubble are done.
    
    
    
    NSMutableString *veriticalConstraint = [[NSMutableString alloc]initWithString:@"V:|-4-[senderLabel]"];
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
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(<=%ld)]-%@-|",leftPadding,str,(long)self.maxcontentWidth,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@(>=0)]",str]];
        } else if([str containsString:@"button_"]) {
            NSString *horizontalConstraint = [NSString stringWithFormat:@"H:|-%@-[%@(>=50)]-%@-|",leftPadding,str,rightPadding];
            [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : horizontalConstraint options:0 metrics:nil views:views]];
            [veriticalConstraint appendString:[NSString stringWithFormat:@"-5-[%@]",str]];
        }
    }
    if(!currentMessage.isWelcomeMessage) { //Show time for non welcome messages.
        [veriticalConstraint appendString:@"-5-[messageSentTimeLabel(<=20)]"];
        [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"H:|-5-[messageSentTimeLabel]-(>=5)-|" options:0 metrics:nil views:views]];
    }
    [contentEncloser addConstraints:[NSLayoutConstraint constraintsWithVisualFormat : @"H:|-10-[senderLabel]-7-|" options:0 metrics:nil views:views]];
    [veriticalConstraint appendString:@"-5-|"];
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
