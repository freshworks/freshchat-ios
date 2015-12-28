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

#define WIDTH_BUFFER_IF_NO_PROFILE_AVAILABLE 5*KONOTOR_HORIZONTAL_PADDING;
static KonotorUIParameters* konotorUIParameters=nil;

static UITextView* tempView=nil;
static UITextView* txtView=nil;


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

@synthesize messageActionButton,messagePictureImageView,messageSentTimeLabel,messageTextView,chatCalloutImageView,uploadStatusImageView,profileImageView,audioItem,senderNameLabel;

@synthesize isSenderOther,showsProfile,showsSenderName,customFontName,showsTimeStamp,showsUploadStatus,sentImage,sendingImage;

-(instancetype)initWithReuseIdentifier:(NSString *)identifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
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

    showsProfile=YES;
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
        [messageSentTimeLabel setFont:(customFontName?[UIFont fontWithName:customFontName size:11.0]:[UIFont systemFontOfSize:11.0])];
        [messageSentTimeLabel setBackgroundColor:[UIColor clearColor]];
        [messageSentTimeLabel setTextAlignment:NSTextAlignmentRight];
        [messageSentTimeLabel setTextColor:[UIColor darkGrayColor]];
        [messageSentTimeLabel setEditable:NO];
        [messageSentTimeLabel setSelectable:NO];
        [messageSentTimeLabel setScrollEnabled:NO];
        [self.contentView addSubview:messageSentTimeLabel];
    }
    
    /* setup message text field*/

    messageTextView=[[UITextView alloc] initWithFrame:CGRectZero];
    [messageTextView setFont:KONOTOR_MESSAGETEXT_FONT];
    [messageTextView setBackgroundColor:[UIColor clearColor]];
    [messageTextView setDataDetectorTypes:(UIDataDetectorTypeLink|UIDataDetectorTypePhoneNumber)];
    [messageTextView setTextAlignment:NSTextAlignmentLeft];
    [messageTextView setTextColor:[UIColor blackColor]];
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
    imgViewTapGesture.numberOfTapsRequired=1;
    [messagePictureImageView addGestureRecognizer:imgViewTapGesture];

    [messageTextView addSubview:messagePictureImageView];
    
    /* setup action button view */
    messageActionButton=[FDActionButton buttonWithType:UIButtonTypeCustom];
    [messageActionButton addTarget:self.delegate action:@selector(openActionUrl:) forControlEvents:UIControlEventTouchUpInside];
    [messageActionButton setUpStyle];
    [messageActionButton setActionUrlString:nil];
    [self.contentView addSubview:messageActionButton];
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

    
    NSString* customFontName=[[HLTheme sharedInstance] conversationUIFontName];
    
    float messageContentViewWidth = KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;

    //single line text messages and html messages occupy less width than others
    
    if((([message messageType].integerValue==KonotorMessageTypeText)||([message messageType].integerValue==KonotorMessageTypeHTML))&&(![FDMessageCell hasButtonForURL:message.actionURL articleID:message.articleID])){
        NSString* messageText=message.text;
        
        //convert HTML text to a plain string for width calculation
        if(message.messageType.integerValue==KonotorMessageTypeHTML){
            messageText=[[[NSMutableAttributedString alloc] initWithData:[messageText dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil] string];
        }
        
        //check if message occupies a single line
        CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:KONOTOR_MESSAGETEXT_FONT];
        int numLines = (sizer.height-10) / ([FDMessageCell getTextViewLineHeight:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:KONOTOR_MESSAGETEXT_FONT]);
        
        //if message is single line, calculate larger width of the message text and date string
        if (numLines >= 1){
            [tempView setFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView setText:messageText];
            [tempView setFont:KONOTOR_MESSAGETEXT_FONT];
            CGSize txtSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 1000)];
            
            NSDate* date=[NSDate dateWithTimeIntervalSince1970:message.createdMillis.longLongValue/1000];
            NSString *strDate = [FDUtilities stringRepresentationForDate:date];
            
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
    }
    else if((([message messageType].integerValue==KonotorMessageTypePicture)||([message messageType].integerValue==KonotorMessageTypePictureV2))&&(![FDMessageCell hasButtonForURL:message.actionURL articleID:message.articleID]))
    {
        NSString* messageText=message.text;
        
        //check if message occupies a single line
        CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:KONOTOR_MESSAGETEXT_FONT];
        int numLines = (sizer.height-10) / ([FDMessageCell getTextViewLineHeight:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:KONOTOR_MESSAGETEXT_FONT]);
        
        //if message is single line, calculate larger width of the message text and date string
        if (numLines >= 1){
            [tempView setFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView setText:messageText];
            [tempView setFont:KONOTOR_MESSAGETEXT_FONT];
            CGSize txtSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 1000)];
            
            NSDate* date=[NSDate dateWithTimeIntervalSince1970:message.createdMillis.longLongValue/1000];
            NSString *strDate = [FDUtilities stringRepresentationForDate:date];
            
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
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:message];
        if((picSize.width+16)>messageContentViewWidth)
            messageContentViewWidth=MIN(picSize.width+16,KONOTOR_TEXTMESSAGE_MAXWIDTH);

    }
    
    return messageContentViewWidth;
}


- (void) drawMessageViewForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView withWidth:(float)contentViewWidth{
    
    NSInteger messageType = [currentMessage.messageType integerValue];
    
    isSenderOther=[Konotor isUserMe:[currentMessage messageUserId]]?NO:YES;
    float profileX=0.0, profileY=0.0, messageContentViewX=0.0, messageContentViewY=0.0, messageTextBoxX=0.0, messageTextBoxY=0.0,messageContentViewWidth=0.0,messageTextBoxWidth=0.0;
    
    messageContentViewWidth=contentViewWidth;
    
    showsProfile=isSenderOther?([HLTheme sharedInstance].showsBusinessProfileImage):([HLTheme sharedInstance].showsUserProfileImage);
    
    // get the length of the textview if one line and calculate page sides
    
    float messageDisplayWidth=parentView.frame.size.width;
    
    if(showsProfile){
        profileX=isSenderOther?KONOTOR_HORIZONTAL_PADDING:(messageDisplayWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION);
        profileY=KONOTOR_VERTICAL_PADDING;
        messageContentViewY=KONOTOR_VERTICAL_PADDING;
        messageContentViewWidth=MIN(messageDisplayWidth-KONOTOR_PROFILEIMAGE_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING,messageContentViewWidth);
        messageContentViewX=isSenderOther?(profileX+KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_HORIZONTAL_PADDING):(messageDisplayWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION-KONOTOR_HORIZONTAL_PADDING-messageContentViewWidth);
        
        messageTextBoxWidth=messageContentViewWidth-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
        messageTextBoxX=isSenderOther?(messageContentViewX+KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING):(messageContentViewX+KONOTOR_HORIZONTAL_PADDING);
        
        messageTextBoxY=messageContentViewY;
    }
    else{
        messageContentViewY=KONOTOR_VERTICAL_PADDING;
        messageContentViewWidth= MIN(messageDisplayWidth-8*KONOTOR_HORIZONTAL_PADDING,messageContentViewWidth);
        messageContentViewX=isSenderOther?(KONOTOR_HORIZONTAL_PADDING*2):(messageDisplayWidth-2*KONOTOR_HORIZONTAL_PADDING-messageContentViewWidth);
        messageTextBoxWidth=messageContentViewWidth-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
        messageTextBoxX=isSenderOther?(messageContentViewX+KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING):(messageContentViewX+KONOTOR_HORIZONTAL_PADDING);
        messageTextBoxY=messageContentViewY;
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
    
        
    KonotorUIParameters* interfaceOptions=[KonotorUIParameters sharedInstance];
    
    if(isSenderOther){
        senderNameLabel.text=@"Support";
        [uploadStatusImageView setImage:nil];
        [chatCalloutImageView setImage:[interfaceOptions.otherChatBubble resizableImageWithCapInsets:interfaceOptions.otherChatBubbleInsets]];
        [senderNameLabel setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERNAME_TEXT_COLOR:interfaceOptions.otherTextColor)];
        [messageTextView setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERMESSAGE_TEXT_COLOR:interfaceOptions.otherTextColor)];
        [messageSentTimeLabel setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERTIMESTAMP_COLOR:interfaceOptions.otherTextColor)];
    }
    else{
        senderNameLabel.text=@"You";
        [chatCalloutImageView setImage:[interfaceOptions.userChatBubble resizableImageWithCapInsets:interfaceOptions.userChatBubbleInsets]];
        [senderNameLabel setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERNAME_TEXT_COLOR:interfaceOptions.userTextColor)];
        [messageTextView setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERMESSAGE_TEXT_COLOR:interfaceOptions.userTextColor)];
        [messageSentTimeLabel setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERTIMESTAMP_COLOR:interfaceOptions.userTextColor)];
        
    }
    
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    [messageSentTimeLabel setText:[FDUtilities stringRepresentationForDate:date]];
    
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
        
        CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:messageTextBoxWidth text:simpleString withFont:KONOTOR_MESSAGETEXT_FONT];
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
            currentMessage.text=@"Error loading picture message.Image Not Found";
            
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
        
        float height=picSize.height;
        
        float txtheight=0.0;
        
        [messagePictureImageView setUpPictureMessageInteractionsForMessage:currentMessage withMessageWidth:messageContentViewWidth];
        
        if((currentMessage.text)&&(![currentMessage.text isEqualToString:@""])){
           
            NSString *simpleString=currentMessage.text;
            
            
            [messageTextView setText:[NSString stringWithFormat:@"\u200b%@",currentMessage.text]];
            CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:messageTextBoxWidth text:simpleString withFont:KONOTOR_MESSAGETEXT_FONT];

            
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
       // NSMutableAttributedString* messageText=[FDMessageCell getAttributedStringWithText:currentMessage.text font:KONOTOR_MESSAGETEXT_FONT];
        
        float height=[FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:KONOTOR_MESSAGETEXT_FONT];
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
            currentMessage.text=@"Error loading picture message.Image Not Found";
        
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
        
        float height=picSize.height;
        float txtheight=0.0;
        
        
        //TODO: Read message font from theme
        if((currentMessage.text)&&(![currentMessage.text isEqualToString:@""])){
            NSString *simpleString=currentMessage.text;
            txtheight=[FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:KONOTOR_MESSAGETEXT_FONT];
        }
        cellHeight= 16+txtheight+height+(KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)+(showSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+(showSenderName?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    if([FDMessageCell hasButtonForURL:currentMessage.actionURL articleID:currentMessage.articleID])
        cellHeight+= ACTION_URL_HEIGHT;
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
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+messageTextFrame.size.height-4, messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT+4)];
            timeField.textContainerInset=UIEdgeInsetsMake(4, 0, 0, 0);
            
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
                
                [timeField setTextContainerInset:UIEdgeInsetsMake(4, 0, 0, 0)];
            }
            
        }
            
        case KonotorMessageTypeHTML:
            
        case KonotorMessageTypeText:
            
            
        default:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+messageTextFrame.size.height, messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT+4)];
            timeField.textContainerInset=UIEdgeInsetsMake(4, 0, 0, 0);
            [timeField setContentOffset:CGPointMake(0, 4)];
            
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
    
    msgHeight+=([FDMessageCell hasButtonForURL:actionUrl articleID:articleID])?(KONOTOR_ACTIONBUTTON_HEIGHT+2*KONOTOR_VERTICAL_PADDING):0;
  
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
    [txtView setDataDetectorTypes:(UIDataDetectorTypeLink|UIDataDetectorTypePhoneNumber)];
    [txtView setTextAlignment:NSTextAlignmentLeft];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING, 1000)];
    return size.height-16;
}

@end

@implementation KonotorUIParameters

@synthesize disableTransparentOverlay,headerViewColor,backgroundViewColor,voiceInputEnabled,imageInputEnabled,closeButtonImage,autoShowTextInput,titleText,textInputButtonImage,titleTextColor,showInputOptions,noPhotoOption,titleTextFont,allowSendingEmptyMessage,dontShowLoadingAnimation,sendButtonColor,doneButtonColor,userChatBubble,userTextColor,otherChatBubble,otherTextColor,overlayTransitionStyle,inputHintText,userProfileImage,otherProfileImage,showOtherName,showUserName,otherName,userName,messageTextFont,inputTextFont,notificationCenterMode,customFontName,doneButtonFont,doneButtonText,dismissesInputOnScroll,alwaysPollForMessages,pollingTimeNotOnChatWindow,pollingTimeOnChatWindow,otherChatBubbleInsets,userChatBubbleInsets/*,cancelButtonText,cancelButtonFont,cancelButtonColor*/;

+ (KonotorUIParameters*) sharedInstance
{
    if(konotorUIParameters==nil){
        konotorUIParameters=[[KonotorUIParameters alloc] init];
        konotorUIParameters.voiceInputEnabled=NO;
        konotorUIParameters.imageInputEnabled=YES;
        konotorUIParameters.actionButtonLabelColor=[UIColor whiteColor];
        konotorUIParameters.actionButtonColor=[UIColor colorWithRed:0 green:0.5 blue:0 alpha:1];
        konotorUIParameters.backgroundViewColor=nil;
        konotorUIParameters.headerViewColor=[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
        
        konotorUIParameters.titleTextColor=nil;
        konotorUIParameters.showInputOptions=YES;
        konotorUIParameters.textInputButtonImage=nil;
        konotorUIParameters.messageSharingEnabled=NO;
        konotorUIParameters.noPhotoOption=NO;
        konotorUIParameters.titleTextFont=nil;
        konotorUIParameters.messageTextFont=nil;
        konotorUIParameters.inputTextFont=nil;
        konotorUIParameters.allowSendingEmptyMessage=NO;
        konotorUIParameters.dontShowLoadingAnimation=NO;
        
        konotorUIParameters.sendButtonColor=nil;
        konotorUIParameters.doneButtonColor=nil;
        
        konotorUIParameters.otherTextColor=[UIColor blackColor];
        konotorUIParameters.otherChatBubble=[[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_LEFT];
        konotorUIParameters.userTextColor=[UIColor darkGrayColor];
        
        konotorUIParameters.userChatBubble=[[HLTheme sharedInstance]getImageWithKey:IMAGE_BUBBLE_CELL_RIGHT];
        konotorUIParameters.userProfileImage=nil;
        konotorUIParameters.otherProfileImage=nil;
        
        konotorUIParameters.overlayTransitionStyle=UIModalTransitionStyleCoverVertical;
        konotorUIParameters.inputHintText=nil;
        
        konotorUIParameters.showUserName=NO;
        konotorUIParameters.showOtherName=NO;
        
        konotorUIParameters.otherName=nil;
        konotorUIParameters.userName=nil;
        
        konotorUIParameters.notificationCenterMode=NO;
        
        konotorUIParameters.customFontName=nil;
        konotorUIParameters.doneButtonFont=nil;
        
        konotorUIParameters.doneButtonText=@"Done";
        konotorUIParameters.dismissesInputOnScroll=NO;
        
        konotorUIParameters.pollingTimeOnChatWindow=10;
        konotorUIParameters.pollingTimeNotOnChatWindow=-1;
        konotorUIParameters.alwaysPollForMessages=NO;
        
        konotorUIParameters.otherChatBubbleInsets=UIEdgeInsetsMake(9, 12, 10, 7);
        konotorUIParameters.userChatBubbleInsets=UIEdgeInsetsMake(10, 7, 9, 12);
        
    }
    return konotorUIParameters;
}


- (void) disableMessageSharing{
    self.messageSharingEnabled=NO;
}
- (void) enableMessageSharing{
    self.messageSharingEnabled=YES;
}

@end

@implementation TapOnPictureRecognizer

@synthesize height,width,image,imageURL;

@end
