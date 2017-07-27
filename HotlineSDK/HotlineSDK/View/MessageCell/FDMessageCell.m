//
//  FDMessageCell.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMessageCell.h"
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


#define KONOTOR_VERTICAL_PADDING 2
#define KONOTOR_AGENT_NAME_MIN_PADDING 8
#define KONOTOR_TIMEFIELD_HEIGHT 16
#define KONOTOR_SHOW_TIMESTAMP YES
#define KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME NO
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING 20
#define WIDTH_BUFFER_IF_NO_PROFILE_AVAILABLE 5*KONOTOR_HORIZONTAL_PADDING;

#define MAX_MESSAGE_WIDTH 400

static UITextView* tempView=nil;
static UITextView* txtView=nil;

//TODO: Remove all magic numbers use defined values of required padding, time height constant etc.,

@interface FDMessageCell()
   @property (nonatomic, assign) float userNameFieldHeight;
@end

@implementation FDMessageCell

static float MIN_HEIGHT=(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2;
static float ACTION_URL_HEIGHT = KONOTOR_ACTIONBUTTON_HEIGHT+KONOTOR_VERTICAL_PADDING*2;

#if KONOTOR_SHOW_TIMESTAMP == YES 
    #define EXTRA_TIMESTAMP_HEIGHT KONOTOR_TIMEFIELD_HEIGHT;
#else
    #define EXTRA_TIMESTAMP_HEIGHT = 0;
#endif

static float EXTRA_HEIGHT_WITHOUT_SENDER_NAME =KONOTOR_VERTICAL_PADDING+ 16 + KONOTOR_VERTICAL_PADDING*2 + EXTRA_TIMESTAMP_HEIGHT ;


@synthesize messageActionButton,messagePictureImageView,messageSentTimeLabel,messageTextView,chatBubbleImageView,uploadStatusImageView,profileImageView,audioItem,senderNameLabel,messageTextFont;

@synthesize isAgentMessage,showsProfile,showsSenderName,customFontName,showsTimeStamp,showsUploadStatus,sentImage,sendingImage;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<FDMessageCellDelegate>)delegate{
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
    
    /* customization options to be moved out*/
    
    if(tempView==nil){
        tempView=[[UITextView alloc] init];
        txtView=[[UITextView alloc] init];
    }
    
    self.maxcontentWidth =(NSInteger) self.contentView.frame.size.width - ((self.contentView.frame.size.width/100)*30) ;
    
    sentImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    sendingImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];
    showsProfile = YES;
    showsSenderName= NO;
    customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    showsUploadStatus=YES;
    showsTimeStamp=YES;
    /* setup callout*/
    chatBubbleImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    
    /* setup UserName field*/
    senderNameLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    [senderNameLabel setFont:[[HLTheme sharedInstance] agentNameFont]];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
    senderNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    senderNameLabel.textColor = [[HLTheme sharedInstance] agentNameTextColor];
    [senderNameLabel setEditable:NO];
    [senderNameLabel setScrollEnabled:NO];
    [senderNameLabel setSelectable:NO];
    //[self.contentView addSubview:senderNameLabel];
    
    self.userNameFieldHeight = [[HLTheme sharedInstance] agentNameFont].lineHeight+([FDMessageCell getAgentnamePadding]);
    
    /* setup SentTime field*/
    if(showsTimeStamp){
        messageSentTimeLabel=[[UITextView alloc] initWithFrame:CGRectZero];
        [messageSentTimeLabel setFont:[[HLTheme sharedInstance] getChatbubbleTimeFont]];
        [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
        [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
        [messageSentTimeLabel setEditable:NO];
        [messageSentTimeLabel setSelectable:NO];
        [messageSentTimeLabel setScrollEnabled:NO];
        messageSentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    /* setup message text field*/
    
    messageTextFont = [[HLTheme sharedInstance] getChatBubbleMessageFont];
    messageTextView=[[UITextView alloc] initWithFrame:CGRectZero];
    [messageTextView setFont:messageTextFont];
    
    
    [messageTextView setBackgroundColor:[UIColor clearColor]];
    [messageTextView setDataDetectorTypes:UIDataDetectorTypeAll];
    [messageTextView setTextAlignment:NSTextAlignmentLeft];
    [messageTextView setEditable:NO];
    [messageTextView setScrollEnabled:NO];
    messageTextView.scrollsToTop=NO;
    //[self.contentView addSubview:messageTextView];
    
    /* setup audio message elements*/
    
    audioItem=[[FDAudioMessageUnit alloc] init];
    [audioItem setUpView];
    [messageTextView addSubview:audioItem.audioPlayButton];
    [messageTextView addSubview:audioItem.mediaProgressBar];
    
    /* setup profile image view*/
    if(showsProfile){
        profileImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
        //[self.contentView addSubview:profileImageView];
        //profileImageView.layer.masksToBounds=YES;
        //profileImageView.layer.cornerRadius=KONOTOR_PROFILEIMAGE_DIMENSION/2;
    }
    
    /* setup message sent status*/
    if(showsUploadStatus){
        uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
        [uploadStatusImageView setImage:sentImage];
        uploadStatusImageView.translatesAutoresizingMaskIntoConstraints = NO;
        //[self.contentView addSubview:uploadStatusImageView];
    }
    
    /* setup message picture view */
    messagePictureImageView=[[FDPictureMessageView alloc] initWithFrame:CGRectZero];
    TapOnPictureRecognizer *imgViewTapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
    [messagePictureImageView setContentMode:UIViewContentModeCenter];
    imgViewTapGesture.numberOfTapsRequired=1;
    imgViewTapGesture.numberOfTouchesRequired = 1;
    [messagePictureImageView addGestureRecognizer:imgViewTapGesture];
    
    UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imageLongPress:)];
    [longPressGesture setMinimumPressDuration:0.50];
    longPressGesture.delegate =self;
    messagePictureImageView.userInteractionEnabled = YES;
    [messagePictureImageView addGestureRecognizer:longPressGesture];
    
    [imgViewTapGesture requireGestureRecognizerToFail:longPressGesture];

    [messageTextView addSubview:messagePictureImageView];
    
    /* setup action button view */
    messageActionButton=[FDActionButton buttonWithType:UIButtonTypeCustom];
    [messageActionButton addTarget:self action:@selector(openActionUrl:) forControlEvents:UIControlEventTouchUpInside];
    [messageActionButton setUpStyle];
    [messageActionButton setActionUrlString:nil];
    //[self addSubview:messageActionButton];
}

+ (float) getAgentnamePadding{
    return ( MAX([[HLTheme sharedInstance] agentNameFont].lineHeight/2, KONOTOR_AGENT_NAME_MIN_PADDING));
}

-(void)imageLongPress:(UILongPressGestureRecognizer*)recognizer
{
    // disable long press
}

-(void)openActionUrl:(id)sender{
    [self.delegate messageCell:self openActionUrl:sender];
}

-(void)tappedOnPicture:(id)gesture{
    /*
    UIImage *image=[UIImage imageWithData:[self.messageData picData]];
    if(!image) {
        image = [[HLTheme sharedInstance ] getImageWithKey:IMAGE_PLACEHOLDER];
    }
    [self.delegate messageCell:self pictureTapped:image]; 
     */
}

+(BOOL) hasButtonForURL:(NSString*)actionURL articleID:(NSNumber*)articleID{
    if(((actionURL!=nil)&&(![actionURL isEqualToString:@""]))||((articleID!=nil)&&(articleID.intValue!=0)))
        return YES;
    return NO;
}


+ (float) getWidthForMessage:(MessageData*)message{
    /*
    if(tempView==nil){
        tempView=[[UITextView alloc] init];
        txtView=[[UITextView alloc] init];
    }

    float messageContentViewWidth = KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;

    //single line text messages and html messages occupy less width than others
    
    if ([FDMessageCell hasButtonForURL:message.actionURL articleID:message.articleID] ||
        message.messageType.integerValue==KonotorMessageTypeAudio ){
        return messageContentViewWidth;
    }
    
    NSString* messageText=message.text;
    //convert HTML text to a plain string for width calculation
    if(message.messageType.integerValue==KonotorMessageTypeHTML){
        messageText=[[[NSMutableAttributedString alloc] initWithData:[messageText dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil] string];
    }
    
    //check if message occupies a single line
    NSString* customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    int numLines = [FDMessageCell getNoOfLines:messageText];
    
    //if message is single line, calculate larger width of the message text and date string
    if (numLines >= 1){
        [tempView setFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
        [tempView setText:messageText];
        [tempView setFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]];
        CGSize txtSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 1000)];
        
        NSDate* date=[NSDate dateWithTimeIntervalSince1970:message.createdMillis.longLongValue/1000];
        NSString *strDate = [FDStringUtil stringRepresentationForDate:date];
        
        [tempView setFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
        [tempView setFont:(customFontName?[UIFont fontWithName:customFontName size:11.0]:[UIFont systemFontOfSize:11.0])];
        [tempView setText:strDate];
        CGSize txtTimeSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 50)];
        CGFloat msgWidth = txtSize.width + 3 * KONOTOR_HORIZONTAL_PADDING;
        CGFloat timeWidth = (txtTimeSize.width +  3 * KONOTOR_HORIZONTAL_PADDING)+16;
        
        if (msgWidth < timeWidth){
            messageContentViewWidth = timeWidth;
        }
        else{
            messageContentViewWidth = msgWidth;
        }
    }
    /*if(([message messageType].integerValue==KonotorMessageTypePicture)||([message messageType].integerValue==KonotorMessageTypePictureV2)){
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:message];
        if((picSize.width+16)>messageContentViewWidth)
            messageContentViewWidth=MIN(picSize.width+16,KONOTOR_TEXTMESSAGE_MAXWIDTH);

    }*/
    
    //return messageContentViewWidth;
    return 0;
}

+ (int) getNoOfLines :(NSString *)messageText {
    
    CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]];
    
    return ((sizer.height-10) / ([FDMessageCell getTextViewLineHeight:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]]));
}


- (void) drawMessageViewForMessage:(MessageData*)currentMessage parentView:(UIView*)parentView withWidth:(float)contentViewWidth{
    NSArray *subViewArr = [self.contentView subviews];
    NSMutableArray *fragmensViewArr = [[NSMutableArray alloc]init];
    for (int i=0; i<[subViewArr count]; i++) {
        [subViewArr[i] removeFromSuperview];
    }
    
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

    showsSenderName = isAgentMessage && [FDMessageCell showAgentAvatarLabel]; //Buid considering always false
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

+ (float) getHeightForMessage:(MessageData*)currentMessage parentView:(UIView*)parentView{
    
/*    BOOL KONOTOR_SHOWPROFILEIMAGE=YES;
    
    NSInteger messageType = [currentMessage.messageType integerValue];
    BOOL isAgent=[Konotor isUserMe:[currentMessage messageUserId]]?NO:YES;
    BOOL isAgentNameEnabled = [FDMessageCell showAgentAvatarLabel];
    float heightWithSenderName = KONOTOR_VERTICAL_PADDING+16 + [[HLTheme sharedInstance] agentNameFont].lineHeight+([FDMessageCell getAgentnamePadding]) +KONOTOR_VERTICAL_PADDING*2 + EXTRA_TIMESTAMP_HEIGHT;
    float extraHeight = (isAgent && isAgentNameEnabled) ? heightWithSenderName: EXTRA_HEIGHT_WITHOUT_SENDER_NAME;
    float width = [FDMessageCell getWidthForMessage:currentMessage];

    float cellHeight=0;
    NSString *simpleString=currentMessage.text; //[messageText string];
    UIFont *messageFont = [[HLTheme sharedInstance] getChatBubbleMessageFont];
    
    if((messageType == KonotorMessageTypeText)||(messageType == KonotorMessageTypeHTML)){
        
        float height=[FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:messageFont];
        if(KONOTOR_SHOWPROFILEIMAGE){
            cellHeight= MAX(height+extraHeight, MIN_HEIGHT);
        }
        else{
            cellHeight= height+extraHeight;
        }
        
    }
    else if(messageType == KonotorMessageTypeAudio){
        cellHeight=KONOTOR_AUDIOMESSAGE_HEIGHT+
        ((isAgent && isAgentNameEnabled)?[[HLTheme sharedInstance] agentNameFont].lineHeight+([FDMessageCell getAgentnamePadding]):KONOTOR_VERTICAL_PADDING)
        +(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)
        +((isAgent && isAgentNameEnabled) ?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+
        ((isAgent && isAgentNameEnabled)?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    else if((messageType == KonotorMessageTypePicture)||(messageType == KonotorMessageTypePictureV2)){
        
        if((![currentMessage picData])&&(([[currentMessage picUrl] isEqualToString:@""])|| ([currentMessage picUrl]==nil))&&((simpleString == nil)||([simpleString isEqualToString:@""])))
            currentMessage.text=HLLocalizedString(LOC_PICTURE_MSG_UPLOAD_ERROR);
        
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
        
        float height=picSize.height;
        float txtheight=0.0;
        
        if((currentMessage.text)&&(![currentMessage.text isEqualToString:@""])){
            NSString *simpleString=currentMessage.text;
            txtheight = [FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:messageFont] + messageFont.pointSize;
            if(isAgentNameEnabled){
                txtheight = txtheight + 2*KONOTOR_VERTICAL_PADDING ;
            }
        }
        cellHeight= 16+txtheight+height+(KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)+((isAgent && isAgentNameEnabled)?[[HLTheme sharedInstance] agentNameFont].lineHeight+([FDMessageCell getAgentnamePadding]):KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+((isAgent && isAgentNameEnabled)?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+((isAgent && isAgentNameEnabled)?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    if([FDMessageCell hasButtonForURL:currentMessage.actionURL articleID:currentMessage.articleID])
        cellHeight+= ACTION_URL_HEIGHT;
    
    if(currentMessage.isWelcomeMessage){
        cellHeight= cellHeight-(KONOTOR_VERTICAL_PADDING+KONOTOR_TIMEFIELD_HEIGHT);
        if(KONOTOR_PROFILEIMAGE_DIMENSION > cellHeight)//For setting minimum height
            cellHeight = KONOTOR_PROFILEIMAGE_DIMENSION;
    }
    cellHeight = (isAgent && isAgentNameEnabled)?(cellHeight -(2*KONOTOR_VERTICAL_PADDING)) : cellHeight;
    return cellHeight;
     */
}

/*- (void) adjustPositionForTimeView:(UITextView*) timeField textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)showSenderName messageType:(enum KonotorMessageType) messageType isAgentMessage:(BOOL)isAgentMessage{
    
    float messageTextBoxX=messageTextFrame.origin.x-KONOTOR_HORIZONTAL_PADDING-(isAgentMessage?0:15);
    float messageTextBoxY=messageTextFrame.origin.y+(self.messageActionButton.isHidden?0:(KONOTOR_ACTIONBUTTON_HEIGHT+2*KONOTOR_VERTICAL_PADDING));
    float messageTextBoxWidth=messageTextFrame.size.width;
    
    switch (messageType) {

        case KonotorMessageTypePictureV2:
            
        case KonotorMessageTypePicture:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+messageTextFrame.size.height, messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT+4)];
            timeField.textContainerInset=UIEdgeInsetsMake(0, 0, 0, 0);
            
            break;
        }
            
            
        case KonotorMessageTypeAudio:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+(showSenderName?(self.userNameFieldHeight+KONOTOR_AUDIOMESSAGE_HEIGHT):KONOTOR_AUDIOMESSAGE_HEIGHT), messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT)];
            
            if((KONOTOR_SHOW_TIMESTAMP)&&(showSenderName))
            {
                
                [timeField setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
            }
            else{
                
                [timeField setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
            }
            
        }
            
        case KonotorMessageTypeHTML:
            
        case KonotorMessageTypeText:
            
            
        default:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+messageTextFrame.size.height, messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT)];
            timeField.textContainerInset=UIEdgeInsetsMake(0, 0, 0, 0);
            [timeField setContentOffset:CGPointMake(0, 0)];
            
            break;
        }
    }
    
    [uploadStatusImageView setFrame:CGRectMake(messageTextBoxX+messageTextBoxWidth, messageTextBoxY+messageTextView.frame.size.height+2, 10, 10)];
    
}*/

- (void) adjustHeightForMessageBubble:(UIImageView*)messageBackground textView:(UITextView*)messageText actionUrl:(NSString*)actionUrl height:(float)msgHeight articleID:(NSNumber*) articleID textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)showSenderName sender:(BOOL)isAgentMessage textFrameAdjustY:(float)textViewY contentFrameAdjustY:(float)contentViewY{
    
    float messageTextBoxX=messageTextFrame.origin.x;
    float messageTextBoxY=messageTextFrame.origin.y;
    float messageTextBoxWidth=messageTextFrame.size.width;
    
    float messageContentViewX=messageContentFrame.origin.x;
    float messageContentViewY=messageContentFrame.origin.y;
    float messageContentViewWidth=messageContentFrame.size.width;
    
    
    messageText.frame=CGRectMake(messageTextBoxX, messageTextBoxY+textViewY, messageTextBoxWidth, msgHeight);
    
    msgHeight=msgHeight+(showSenderName?self.userNameFieldHeight:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    
    msgHeight+=([FDMessageCell hasButtonForURL:actionUrl articleID:articleID])?(KONOTOR_ACTIONBUTTON_HEIGHT+KONOTOR_VERTICAL_PADDING):0;
    
    if(!messageSentTimeLabel.text.length){
        msgHeight-= (KONOTOR_TIMEFIELD_HEIGHT+KONOTOR_VERTICAL_PADDING);
        if(KONOTOR_PROFILEIMAGE_DIMENSION > msgHeight)// for minimum dimension
            msgHeight = KONOTOR_PROFILEIMAGE_DIMENSION;
    }
    
    messageBackground.frame=CGRectMake(messageContentViewX, messageContentViewY, messageContentViewWidth, msgHeight);
}

+(CGSize)getSizeOfTextViewWidth:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font{
    if(tempView==nil){
        tempView=[[UITextView alloc] init];
        txtView=[[UITextView alloc] init];
    }

    [txtView setFont:font];
    [txtView setText:text];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width, 1000)];
    return size;
}

+(CGFloat)getTextViewLineHeight:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font{
    if(tempView==nil){
        tempView=[[UITextView alloc] init];
        txtView=[[UITextView alloc] init];
    }

    [txtView setFont:font];
    [txtView setText:text];
    return txtView.font.lineHeight;
}

+(CGFloat)getTextViewHeightForMaxWidth:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font{
    if(tempView==nil){
        tempView=[[UITextView alloc] init];
        txtView=[[UITextView alloc] init];
    }

    [txtView setFont:font];
    if([txtView respondsToSelector:@selector(setTextContainerInset:)])
        [txtView setTextContainerInset:UIEdgeInsetsMake(6, 0, 8, 0)];

    [txtView setText:text];
    [txtView setDataDetectorTypes:UIDataDetectorTypeAll];
    [txtView setTextAlignment:NSTextAlignmentLeft];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING, 1000)];
    return size.height-16;
}

@end

@implementation TapOnPictureRecognizer

@synthesize height,width,image,imageURL;

@end
