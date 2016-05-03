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

#define KONOTOR_VERTICAL_PADDING 2
#define KONOTOR_USERNAMEFIELD_HEIGHT 18
#define KONOTOR_TIMEFIELD_HEIGHT 16
#define KONOTOR_SHOW_TIMESTAMP YES
#define KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME NO
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING 20
#define WIDTH_BUFFER_IF_NO_PROFILE_AVAILABLE 5*KONOTOR_HORIZONTAL_PADDING;

static UITextView* tempView=nil;
static UITextView* txtView=nil;

//TODO: Remove all magic numbers use defined values of required padding, time height constant etc.,

@implementation FDMessageCell

static BOOL KONOTOR_SHOWPROFILEIMAGE=YES;
static float MAX_TEXT_WIDTH =KONOTOR_TEXTMESSAGE_MAXWIDTH - KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
static float MAX_WIDTH_WITH_PROFILE_IMAGE = 3*KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION;
//static float MAX_WIDTH_WITHOUT_PROFILE_IMAGE = 3*KONOTOR_HORIZONTAL_PADDING-WIDTH_BUFFER_IF_NO_PROFILE_AVAILABLE;
static float MIN_HEIGHT=(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2;
static float ACTION_URL_HEIGHT = KONOTOR_ACTIONBUTTON_HEIGHT+KONOTOR_VERTICAL_PADDING*2;

#if KONOTOR_SHOW_TIMESTAMP == YES 
    #define EXTRA_TIMESTAMP_HEIGHT KONOTOR_TIMEFIELD_HEIGHT;
#else
    #define EXTRA_TIMESTAMP_HEIGHT = 0;
#endif

static float EXTRA_HEIGHT_WITHOUT_SENDER_NAME =KONOTOR_VERTICAL_PADDING+ 16 + KONOTOR_VERTICAL_PADDING*2 + EXTRA_TIMESTAMP_HEIGHT ;
static float EXTRA_HEIGHT_WITH_SENDER_NAME =KONOTOR_VERTICAL_PADDING+16 + KONOTOR_USERNAMEFIELD_HEIGHT +KONOTOR_VERTICAL_PADDING*2 + EXTRA_TIMESTAMP_HEIGHT;

@synthesize messageActionButton,messagePictureImageView,messageSentTimeLabel,messageTextView,chatCalloutImageView,uploadStatusImageView,profileImageView,audioItem,senderNameLabel,messageTextFont;

@synthesize isSenderOther,showsProfile,showsSenderName,customFontName,showsTimeStamp,showsUploadStatus,sentImage,sendingImage;

- (instancetype) initWithReuseIdentifier:(NSString *)identifier andDelegate:(id<FDMessageCellDelegate>)delegate{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        self.delegate = delegate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self initCell];
    }
    return self;
}


- (void) initCell{
    
    /* customization options to be moved out*/
    
    if(tempView==nil){
        tempView=[[UITextView alloc] init];
        txtView=[[UITextView alloc] init];
    }
    
    sentImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENT_ICON];
    sendingImage=[[HLTheme sharedInstance] getImageWithKey:IMAGE_MESSAGE_SENDING_ICON];

    showsProfile = YES;
    showsSenderName=NO;
    customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    showsUploadStatus=YES;
    showsTimeStamp=YES;
    
    /* setup callout*/
    chatCalloutImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    [self.contentView addSubview:chatCalloutImageView];
    
    /* setup UserName field*/
    senderNameLabel=[[UITextView alloc] initWithFrame:CGRectZero];
    [senderNameLabel setFont:(customFontName?[UIFont fontWithName:customFontName size:12.0]:[UIFont systemFontOfSize:12.0])];
    [senderNameLabel setBackgroundColor:[UIColor clearColor]];
    [senderNameLabel setTextAlignment:NSTextAlignmentLeft];
  
    [senderNameLabel setEditable:NO];
    [senderNameLabel setScrollEnabled:NO];
    [senderNameLabel setSelectable:NO];
    [self.contentView addSubview:senderNameLabel];
    
    /* setup SentTime field*/
    if(showsTimeStamp){
        messageSentTimeLabel=[[UITextView alloc] initWithFrame:CGRectZero];
        [messageSentTimeLabel setFont:[[HLTheme sharedInstance] getChatbubbleTimeFont]];
        [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
        [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
        [messageSentTimeLabel setEditable:NO];
        [messageSentTimeLabel setSelectable:NO];
        [messageSentTimeLabel setScrollEnabled:NO];
        [self.contentView addSubview:messageSentTimeLabel];
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
    [self.contentView addSubview:messageTextView];
    
    /* setup audio message elements*/
    
    audioItem=[[FDAudioMessageUnit alloc] init];
    [audioItem setUpView];
    [messageTextView addSubview:audioItem.audioPlayButton];
    [messageTextView addSubview:audioItem.mediaProgressBar];
    
    /* setup profile image view*/
    if(showsProfile){
        profileImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:profileImageView];
        profileImageView.layer.masksToBounds=YES;
        profileImageView.layer.cornerRadius=KONOTOR_PROFILEIMAGE_DIMENSION/2;
    }
    
    /* setup message sent status*/
    if(showsUploadStatus){
        uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
        [uploadStatusImageView setImage:sentImage];
        [self.contentView addSubview:uploadStatusImageView];
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
    [self addSubview:messageActionButton];
}

-(void)imageLongPress:(UILongPressGestureRecognizer*)recognizer
{
    // disable long press
}

-(void)openActionUrl:(id)sender{
    [self.delegate messageCell:self openActionUrl:sender];
}

-(void)tappedOnPicture:(id)gesture{
    [self.delegate messageCell:self pictureTapped:self.messagePictureImageView.image];
}

+(BOOL) hasButtonForURL:(NSString*)actionURL articleID:(NSNumber*)articleID{
    if(((actionURL!=nil)&&(![actionURL isEqualToString:@""]))||((articleID!=nil)&&(articleID.intValue!=0)))
        return YES;
    return NO;
}


+ (float) getWidthForMessage:(KonotorMessageData*)message{
    
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
    if(([message messageType].integerValue==KonotorMessageTypePicture)||([message messageType].integerValue==KonotorMessageTypePictureV2)){
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:message];
        if((picSize.width+16)>messageContentViewWidth)
            messageContentViewWidth=MIN(picSize.width+16,KONOTOR_TEXTMESSAGE_MAXWIDTH);

    }
    
    return messageContentViewWidth;
}

+ (int) getNoOfLines :(NSString *)messageText {
    
    CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]];
    
    return ((sizer.height-10) / ([FDMessageCell getTextViewLineHeight:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]]));
}


- (void) drawMessageViewForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView withWidth:(float)contentViewWidth{
    
    NSInteger messageType = [currentMessage.messageType integerValue];
    
    isSenderOther=[Konotor isUserMe:[currentMessage messageUserId]]?NO:YES;
    float profileX=0.0, profileY=0.0, messageContentViewX=0.0, messageContentViewY=0.0, messageTextBoxX=0.0, messageTextBoxY=0.0,messageContentViewWidth=0.0,messageTextBoxWidth=0.0;
    
    messageContentViewWidth=contentViewWidth;
    
    //add for config into user file
    
    FDSecureStore *store = [FDSecureStore sharedInstance];
    BOOL isAgentAvatarEnabled = [store boolValueForKey:HOTLINE_DEFAULTS_AGENT_AVATAR_ENABLED];
    BOOL isUserAvatarEnabled = FALSE;//Set Default as false will use it in later versions
    showsProfile = isSenderOther?isAgentAvatarEnabled:isUserAvatarEnabled;
    
    // get the length of the textview if one line and calculate page sides
    
    float messageDisplayWidth=parentView.frame.size.width;
    
    if(showsProfile){
        profileX=isSenderOther?KONOTOR_HORIZONTAL_PADDING:(messageDisplayWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION);
        profileY=KONOTOR_VERTICAL_PADDING;
        messageContentViewY=KONOTOR_VERTICAL_PADDING;
        messageContentViewWidth=MIN(messageDisplayWidth-KONOTOR_PROFILEIMAGE_DIMENSION-4*KONOTOR_HORIZONTAL_PADDING,messageContentViewWidth)+8;
        messageContentViewX=isSenderOther?(profileX+KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_HORIZONTAL_PADDING)-4:(messageDisplayWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION-KONOTOR_HORIZONTAL_PADDING-messageContentViewWidth);
        
        messageTextBoxWidth=messageContentViewWidth-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
        messageTextBoxX=isSenderOther?(messageContentViewX+KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING):(messageContentViewX+KONOTOR_HORIZONTAL_PADDING);
        
        messageTextBoxY=messageContentViewY;
    }
    else{
        messageContentViewY=KONOTOR_VERTICAL_PADDING;
        messageContentViewWidth= MIN(messageDisplayWidth-4*KONOTOR_HORIZONTAL_PADDING,messageContentViewWidth)+8;
        messageContentViewX=isSenderOther?(KONOTOR_HORIZONTAL_PADDING*2):(messageDisplayWidth-2*KONOTOR_HORIZONTAL_PADDING-messageContentViewWidth);
        messageTextBoxWidth=messageContentViewWidth-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
        messageTextBoxX=isSenderOther?(messageContentViewX+KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING):(messageContentViewX+KONOTOR_HORIZONTAL_PADDING);
        messageTextBoxY=messageContentViewY;
    }
    
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    
    if(currentMessage.isWelcomeMessage){
        messageSentTimeLabel.text = nil;
        if([FDMessageCell getNoOfLines : currentMessage.text]==1){
            messageTextBoxY= KONOTOR_HORIZONTAL_PADDING *1.5;
        }
    }
    else{
        messageSentTimeLabel.text = [FDStringUtil stringRepresentationForDate:date];
    }
    
    CGRect messageTextBoxFrame=CGRectMake(messageTextBoxX,messageTextBoxY,messageTextBoxWidth,0);
    CGRect messageContentViewFrame=CGRectMake(messageContentViewX, messageContentViewY, messageContentViewWidth, 0);
    
    [senderNameLabel setFrame:CGRectMake(messageTextBoxX, messageTextBoxY, messageTextBoxWidth, KONOTOR_USERNAMEFIELD_HEIGHT)];
    if(showsSenderName)
        [senderNameLabel setHidden:NO];
    else
        [senderNameLabel setHidden:YES];
    
    if([currentMessage uploadStatus].integerValue==MessageUploaded)
        [uploadStatusImageView setImage:sentImage];
    else
        [uploadStatusImageView setImage:sendingImage];
        
    UIImage *otherChatBubble = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_LEFT];
    UIImage *userChatBubble = [[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_RIGHT];
    
    UIEdgeInsets otherChatBubbleInsets= [[HLTheme sharedInstance] getAgentBubbleInsets];
    UIEdgeInsets userChatBubbleInsets= [[HLTheme sharedInstance] getUserBubbleInsets];
    UIColor *messageTextColor;
    if(isSenderOther){
        messageTextColor = [[HLTheme sharedInstance] agentMessageFontColor];
        senderNameLabel.text=HLLocalizedString(LOC_MESSAGES_SUPPORT_LABEL_TEXT);
        [uploadStatusImageView setImage:nil];
        [chatCalloutImageView setImage:[otherChatBubble resizableImageWithCapInsets:otherChatBubbleInsets]];
        [messageTextView setTextColor:messageTextColor];
        [messageSentTimeLabel setTextColor:messageTextColor];
    }
    else{
        messageTextColor = [[HLTheme sharedInstance] userMessageFontColor];
        senderNameLabel.text=HLLocalizedString(LOC_MESSAGES_USER_LABEL_TEXT);
        [chatCalloutImageView setImage:[userChatBubble resizableImageWithCapInsets:userChatBubbleInsets]];
        [messageTextView setTextColor:messageTextColor];
        [messageSentTimeLabel setTextColor:messageTextColor];
    }
    
    NSString* actionUrl=currentMessage.actionURL;
    NSString* actionLabel=currentMessage.actionLabel;
    messageActionButton.actionUrlString=actionUrl;
    messageActionButton.articleID=currentMessage.articleID;
    
    if([messageTextView respondsToSelector:@selector(setTextContainerInset:)])
        [messageTextView setTextContainerInset:UIEdgeInsetsMake(6, 0, 8, 0)];
    
    
    if((messageType == KonotorMessageTypeText)||(messageType == KonotorMessageTypeHTML)) {
        [audioItem.mediaProgressBar setHidden:YES];
        [audioItem.audioPlayButton setHidden:YES];
        
        
        NSString *simpleString=currentMessage.text;
        [messageTextView setText:[NSString stringWithFormat:@"\u200b%@",currentMessage.text]];
        
        CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:messageTextBoxWidth text:simpleString withFont:messageTextFont];
        float msgHeight=sizer.height;
        float textViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:0);
        float contentViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:0);
        
        [self adjustHeightForMessageBubble:chatCalloutImageView textView:messageTextView actionUrl:actionUrl height:msgHeight articleID:currentMessage.articleID textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
        [messagePictureImageView setHidden:YES];
        [messageActionButton setupWithLabel:actionLabel frame:messageTextView.frame];
        
    }else if(messageType == KonotorMessageTypeAudio){
        
        [messageTextView setText:@""];
        
        float msgHeight=KONOTOR_AUDIOMESSAGE_HEIGHT;
        float textViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING);
        float contentViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING;
        
        [self adjustHeightForMessageBubble:chatCalloutImageView textView:messageTextView actionUrl:actionUrl height:msgHeight articleID:currentMessage.articleID textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
        [audioItem displayMessage:(FDMessage*)currentMessage];
        
        [messagePictureImageView setHidden:YES];
        [messageActionButton setupWithLabel:actionLabel frame:messageTextView.frame];

    }else if((messageType ==KonotorMessageTypePicture)||(messageType == KonotorMessageTypePictureV2)){
        if((![currentMessage picData])&&(([[currentMessage picUrl] isEqualToString:@""])|| ([currentMessage picUrl]==nil))&&((currentMessage.text==nil)||([currentMessage.text isEqualToString:@""])))
            currentMessage.text=HLLocalizedString(LOC_PICTURE_MSG_UPLOAD_ERROR);
            
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
        
        float height=picSize.height;
        
        float txtheight=0.0;
        
        [messagePictureImageView setUpPictureMessageInteractionsForMessage:currentMessage withMessageWidth:messageContentViewWidth];
        
        if((currentMessage.text)&&(![currentMessage.text isEqualToString:@""])){
           
            NSString *simpleString=currentMessage.text;
            
            
            [messageTextView setText:[NSString stringWithFormat:@"\u200b%@",currentMessage.text]];
            CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:messageTextBoxWidth text:simpleString withFont:messageTextFont];

            
            txtheight=sizer.height-16;
            
            [messageTextView setTextContainerInset:UIEdgeInsetsMake(height+10, 0, 0, 0)];
            
        }
        else
            [messageTextView setText:@""];
        
        float msgHeight=16+height+txtheight;
        float textViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:0);
        float contentViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING;
        
        [self adjustHeightForMessageBubble:chatCalloutImageView textView:messageTextView actionUrl:actionUrl height:msgHeight articleID:currentMessage.articleID textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        

        [audioItem setHidden:YES];
        [messagePictureImageView setHidden:NO];
        
        messagePictureImageView.layer.cornerRadius=10.0;
        messagePictureImageView.layer.masksToBounds=YES;
        [messageActionButton setupWithLabel:actionLabel frame:messageTextView.frame];
        
    }
    
    [self adjustPositionForTimeView:messageSentTimeLabel textBoxRect:messageTextView.frame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName messageType:(enum KonotorMessageType)[currentMessage messageType].integerValue isAgentMessage:(BOOL)isSenderOther];
    
   if(showsProfile){
       if(isSenderOther){
           profileImageView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_AGENT];
       }else{
           profileImageView.image = [[HLTheme sharedInstance] getImageWithKey:IMAGE_AVATAR_USER];
       }
       
       profileImageView.frame = CGRectMake(profileX,chatCalloutImageView.frame.origin.y+chatCalloutImageView.frame.size.height-KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION);
       profileImageView.hidden = NO;
       
    }else{
        profileImageView.hidden = YES;
    }
     
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
    self.tag=[currentMessage.messageId hash];
}

+ (float) getHeightForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView{
    
    NSInteger messageType = [currentMessage.messageType integerValue];
    
    BOOL showSenderName=NO;
    float maxAvailableWidth=parentView.frame.size.width-MAX_WIDTH_WITH_PROFILE_IMAGE;

    float width=MIN(maxAvailableWidth,MAX_TEXT_WIDTH);

    float extraHeight = showSenderName ? EXTRA_HEIGHT_WITH_SENDER_NAME: EXTRA_HEIGHT_WITHOUT_SENDER_NAME;
    width = [FDMessageCell getWidthForMessage:currentMessage];

    float cellHeight=0;
    NSString *simpleString=currentMessage.text; //[messageText string];
    
    if((messageType == KonotorMessageTypeText)||(messageType == KonotorMessageTypeHTML)){
        
        float height=[FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]];
        if(KONOTOR_SHOWPROFILEIMAGE){
            cellHeight= MAX(height+extraHeight,
                            MIN_HEIGHT);
        }
        else{
            cellHeight= height+extraHeight;
        }
        
    }
    else if(messageType == KonotorMessageTypeAudio){
        cellHeight=KONOTOR_AUDIOMESSAGE_HEIGHT+
        (showSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)
        +(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)
        +(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+
        (showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    else if((messageType == KonotorMessageTypePicture)||(messageType == KonotorMessageTypePictureV2)){
        
        if((![currentMessage picData])&&(([[currentMessage picUrl] isEqualToString:@""])|| ([currentMessage picUrl]==nil))&&((simpleString == nil)||([simpleString isEqualToString:@""])))
            currentMessage.text=HLLocalizedString(LOC_PICTURE_MSG_UPLOAD_ERROR);
        
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
        
        float height=picSize.height;
        float txtheight=0.0;
        
        if((currentMessage.text)&&(![currentMessage.text isEqualToString:@""])){
            NSString *simpleString=currentMessage.text;
            txtheight = [FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:[[HLTheme sharedInstance] getChatBubbleMessageFont]];
        }
        cellHeight= 16+txtheight+height+(KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)+(showSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    if([FDMessageCell hasButtonForURL:currentMessage.actionURL articleID:currentMessage.articleID])
        cellHeight+= ACTION_URL_HEIGHT;
    
    if(currentMessage.isWelcomeMessage){
        cellHeight= cellHeight-(KONOTOR_VERTICAL_PADDING+KONOTOR_TIMEFIELD_HEIGHT);
        if(KONOTOR_PROFILEIMAGE_DIMENSION > cellHeight)//For setting minimum height
            cellHeight = KONOTOR_PROFILEIMAGE_DIMENSION;
    }
    return cellHeight;
}

- (void) adjustPositionForTimeView:(UITextView*) timeField textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)showSenderName messageType:(enum KonotorMessageType) messageType isAgentMessage:(BOOL)isAgentMessage{
    
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
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+(showSenderName?(KONOTOR_USERNAMEFIELD_HEIGHT+KONOTOR_AUDIOMESSAGE_HEIGHT):KONOTOR_AUDIOMESSAGE_HEIGHT), messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT)];
            
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
    
}

- (void) adjustHeightForMessageBubble:(UIImageView*)messageBackground textView:(UITextView*)messageText actionUrl:(NSString*)actionUrl height:(float)msgHeight articleID:(NSNumber*) articleID textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)showSenderName sender:(BOOL)isSenderOther textFrameAdjustY:(float)textViewY contentFrameAdjustY:(float)contentViewY{
    
    float messageTextBoxX=messageTextFrame.origin.x;
    float messageTextBoxY=messageTextFrame.origin.y;
    float messageTextBoxWidth=messageTextFrame.size.width;
    
    float messageContentViewX=messageContentFrame.origin.x;
    float messageContentViewY=messageContentFrame.origin.y;
    float messageContentViewWidth=messageContentFrame.size.width;
    
    
    messageText.frame=CGRectMake(messageTextBoxX, messageTextBoxY+textViewY, messageTextBoxWidth, msgHeight);
    
    msgHeight=msgHeight+(showSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    
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