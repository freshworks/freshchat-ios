//
//  FDMessageCell.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMessageCell.h"
#import "FDUtilities.h"
#import "KonotorUI.h"
@implementation FDMessageCell

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
    sentImage=[UIImage imageNamed:@"konotor_sent"];
    sendingImage=[UIImage imageNamed:@"konotor_uploading"];

    showsProfile=YES;
    showsSenderName=NO;
    customFontName=@"Helvetica";
    showsUploadStatus=YES;
    showsTimeStamp=YES;
    
    /* setup callout*/
    chatCalloutImageView=[[UIImageView alloc] initWithFrame:CGRectMake(1, 1, 1, 1)];
    UIEdgeInsets insets=UIEdgeInsetsMake(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_BOTTOM_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_RIGHT_INSET);
    [chatCalloutImageView setImage:[[UIImage imageNamed:@"konotor_chatbubble_ios7_other.png"] resizableImageWithCapInsets:insets]];
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
    }
    
    /* setup message sent status*/
    if(showsUploadStatus){
        uploadStatusImageView=[[UIImageView alloc] initWithFrame:CGRectZero];
        [uploadStatusImageView setImage:sentImage];
        [self.contentView addSubview:uploadStatusImageView];
    }
    
    /* setup message picture view */
    messagePictureImageView=[[FDPictureMessageView alloc] initWithFrame:CGRectZero];
    [messageTextView addSubview:messagePictureImageView];
    
    /* setup action button view */
    messageActionButton=[FDActionButton buttonWithType:UIButtonTypeCustom];
    [messageActionButton setUpStyle];
    [messageActionButton setActionUrlString:nil];
    [self.contentView addSubview:messageActionButton];
}

- (float) getWidthForMessage:(KonotorMessageData*)message{
    
    float messageContentViewWidth = KONOTOR_TEXTMESSAGE_MAXWIDTH;

    //single line text messages and html messages occupy less width than others
    
    if((([message messageType].integerValue==KonotorMessageTypeText)||([message messageType].integerValue==KonotorMessageTypeHTML))&&((message.actionURL==nil)||(![message.actionURL isEqualToString:@""]))){
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
            UITextView* tempView=[[UITextView alloc] initWithFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView setText:messageText];
            [tempView setFont:KONOTOR_MESSAGETEXT_FONT];
            CGSize txtSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 1000)];
            
            NSDate* date=[NSDate dateWithTimeIntervalSince1970:message.createdMillis.longLongValue/1000];
            NSString *strDate = [FDUtilities stringRepresentationForDate:date];
            
            UITextView* tempView2=[[UITextView alloc] initWithFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView2 setFont:(customFontName?[UIFont fontWithName:customFontName size:11.0]:[UIFont systemFontOfSize:11.0])];
            [tempView2 setText:strDate];
            CGSize txtTimeSize = [tempView2 sizeThatFits:CGSizeMake(messageContentViewWidth, 50)];
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
    else if((([message messageType].integerValue==KonotorMessageTypePicture)||([message messageType].integerValue==KonotorMessageTypePictureV2))&&((message.actionURL==nil)||(![message.actionURL isEqualToString:@""])))
    {
        NSString* messageText=message.text;
        
        //check if message occupies a single line
        CGSize sizer = [FDMessageCell getSizeOfTextViewWidth:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:KONOTOR_MESSAGETEXT_FONT];
        int numLines = (sizer.height-10) / ([FDMessageCell getTextViewLineHeight:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:messageText withFont:KONOTOR_MESSAGETEXT_FONT]);
        
        //if message is single line, calculate larger width of the message text and date string
        if (numLines >= 1){
            UITextView* tempView=[[UITextView alloc] initWithFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView setText:messageText];
            [tempView setFont:KONOTOR_MESSAGETEXT_FONT];
            CGSize txtSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 1000)];
            
            NSDate* date=[NSDate dateWithTimeIntervalSince1970:message.createdMillis.longLongValue/1000];
            NSString *strDate = [FDUtilities stringRepresentationForDate:date];
            
            UITextView* tempView2=[[UITextView alloc] initWithFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView2 setFont:(customFontName?[UIFont fontWithName:customFontName size:11.0]:[UIFont systemFontOfSize:11.0])];
            [tempView2 setText:strDate];
            CGSize txtTimeSize = [tempView2 sizeThatFits:CGSizeMake(messageContentViewWidth, 50)];
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


- (void) drawMessageViewForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView{
    
    NSInteger messageType = [currentMessage.messageType integerValue];
    
    isSenderOther=[Konotor isUserMe:[currentMessage messageUserId]]?NO:YES;
    float profileX=0.0, profileY=0.0, messageContentViewX=0.0, messageContentViewY=0.0, messageTextBoxX=0.0, messageTextBoxY=0.0,messageContentViewWidth=0.0,messageTextBoxWidth=0.0;
    
    messageContentViewWidth=[self getWidthForMessage:currentMessage];
    
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
    
    
    UIEdgeInsets insets=UIEdgeInsetsMake(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_BOTTOM_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_RIGHT_INSET);
    
    KonotorUIParameters* interfaceOptions=[KonotorUIParameters sharedInstance];
    if(isSenderOther){
        senderNameLabel.text=@"Support";
        [uploadStatusImageView setImage:nil];
        [chatCalloutImageView setImage:[((interfaceOptions.otherChatBubble==nil)?[UIImage imageNamed:@"konotor_chatbubble_ios7_other.png"]:interfaceOptions.otherChatBubble) resizableImageWithCapInsets:insets]];
        [senderNameLabel setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERNAME_TEXT_COLOR:interfaceOptions.otherTextColor)];
        [messageTextView setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERMESSAGE_TEXT_COLOR:interfaceOptions.otherTextColor)];
        [messageSentTimeLabel setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERTIMESTAMP_COLOR:interfaceOptions.otherTextColor)];
    }
    else{
        senderNameLabel.text=@"You";
        [chatCalloutImageView setImage:[((interfaceOptions.userChatBubble==nil)?[UIImage imageNamed:@"konotor_chatbubble_ios7_you.png"]:interfaceOptions.userChatBubble) resizableImageWithCapInsets:insets]];
        [senderNameLabel setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERNAME_TEXT_COLOR:interfaceOptions.userTextColor)];
        [messageTextView setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERMESSAGE_TEXT_COLOR:interfaceOptions.userTextColor)];
        [messageSentTimeLabel setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERTIMESTAMP_COLOR:interfaceOptions.userTextColor)];
        
    }
    
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    [messageSentTimeLabel setText:[FDUtilities stringRepresentationForDate:date]];
    
    NSString* actionUrl=currentMessage.actionURL;
    NSString* actionLabel=currentMessage.actionLabel;
    messageActionButton.actionUrlString=actionUrl;
    
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
        
        [self adjustHeightForMessageBubble:chatCalloutImageView textView:messageTextView actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
        [messagePictureImageView setHidden:YES];
        [messageActionButton setupWithLabel:actionLabel frame:messageTextView.frame];
        
    }else if(messageType == KonotorMessageTypeAudio){
        
        [messageTextView setText:@""];
        
        float msgHeight=KONOTOR_AUDIOMESSAGE_HEIGHT;
        float textViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING);
        float contentViewY=(showsSenderName?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING;
        
        [self adjustHeightForMessageBubble:chatCalloutImageView textView:messageTextView actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
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
        
        [self adjustHeightForMessageBubble:chatCalloutImageView textView:messageTextView actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
        
        [audioItem setHidden:YES];
        [messagePictureImageView setHidden:NO];
        
        messagePictureImageView.layer.cornerRadius=10.0;
        messagePictureImageView.layer.masksToBounds=YES;
        [messageActionButton setupWithLabel:actionLabel frame:messageTextView.frame];
        
    }
    
    [self adjustPositionForTimeView:messageSentTimeLabel textBoxRect:messageTextView.frame contentViewRect:messageContentViewFrame showsSenderName:showsSenderName messageType:(enum KonotorMessageType)[currentMessage messageType].integerValue isAgentMessage:(BOOL)isSenderOther];
    
   if(showsProfile){
       profileImageView.hidden = NO;
       if(isSenderOther){
           profileImageView.image = [UIImage imageNamed:@"konotor_supportprofile"];
       }else{
           profileImageView.image = [UIImage imageNamed:@"konotor_profile"];
       }
       
       profileImageView.frame = CGRectMake(profileX,chatCalloutImageView.frame.origin.y+chatCalloutImageView.frame.size.height-KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION);

       profileImageView.layer.cornerRadius = KONOTOR_PROFILEIMAGE_DIMENSION/2;
       
    }else{
        profileImageView.hidden = YES;
    }
     
    [self setBackgroundColor:[UIColor clearColor]];
    [self.contentView setClipsToBounds:YES];
    self.tag=[currentMessage.messageId hash];
}

+ (float) getHeightForMessage:(KonotorMessageData*)currentMessage parentView:(UIView*)parentView{
    
    NSInteger messageType = [currentMessage.messageType integerValue];
    
    BOOL KONOTOR_SHOWPROFILEIMAGE=NO;
    BOOL KONOTOR_SHOW_SENDERNAME=NO;
    
    float maxTextWidth=KONOTOR_TEXTMESSAGE_MAXWIDTH;
    float widthBufferIfNoProfileImage=5*KONOTOR_HORIZONTAL_PADDING;
    float maxAvailableWidth=parentView.frame.size.width-3*KONOTOR_HORIZONTAL_PADDING-(KONOTOR_SHOWPROFILEIMAGE?KONOTOR_PROFILEIMAGE_DIMENSION:widthBufferIfNoProfileImage);
    float width=MIN(maxAvailableWidth,maxTextWidth);
    float extraHeight=KONOTOR_VERTICAL_PADDING+16
    +(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)
    +(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0)
    +KONOTOR_VERTICAL_PADDING*2;
    float minimumHeight=(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2;
    
    float cellHeight=0;
    
    if((messageType == KonotorMessageTypeText)||(messageType == KonotorMessageTypeHTML)){
       // NSMutableAttributedString* messageText=[FDMessageCell getAttributedStringWithText:currentMessage.text font:KONOTOR_MESSAGETEXT_FONT];

        NSString *simpleString=currentMessage.text; //[messageText string];
      
        
        float height=[FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:KONOTOR_MESSAGETEXT_FONT];
        if(KONOTOR_SHOWPROFILEIMAGE){
            cellHeight= MAX(height+extraHeight,
                            minimumHeight);
        }
        else{
            cellHeight= height+extraHeight;
        }
        
    }
    else if(messageType == KonotorMessageTypeAudio){
        cellHeight=KONOTOR_AUDIOMESSAGE_HEIGHT+KONOTOR_VERTICAL_PADDING+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
;
    }
    else if((messageType == KonotorMessageTypePicture)||(messageType == KonotorMessageTypePictureV2)){
        
        if((![currentMessage picData])&&(([[currentMessage picUrl] isEqualToString:@""])|| ([currentMessage picUrl]==nil))&&((currentMessage.text==nil)||([currentMessage.text isEqualToString:@""])))
            currentMessage.text=@"Error loading picture message.Image Not Found";
        
        CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
        
        float height=picSize.height;
        float txtheight=0.0;
        
        if((currentMessage.text)&&(![currentMessage.text isEqualToString:@""])){
            
           // NSMutableAttributedString* attributedString=[FDMessageCell getAttributedStringWithText:currentMessage.text font:KONOTOR_MESSAGETEXT_FONT];
           // txtheight=[attributedString boundingRectWithSize:CGSizeMake(width, 1000) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size.height;
            
            NSString *simpleString=currentMessage.text;
            txtheight=[FDMessageCell getTextViewHeightForMaxWidth:width text:simpleString withFont:KONOTOR_MESSAGETEXT_FONT];
        }
        cellHeight= 16+txtheight+height+(KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    if((currentMessage.actionURL!=nil)&&(![currentMessage.actionURL isEqualToString:@""]))
        cellHeight+=KONOTOR_ACTIONBUTTON_HEIGHT+KONOTOR_VERTICAL_PADDING*2;
    return cellHeight;
}

- (void) adjustPositionForTimeView:(UITextView*) timeField textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)KONOTOR_SHOW_SENDERNAME messageType:(enum KonotorMessageType) messageType isAgentMessage:(BOOL)isAgentMessage{
    
    float messageTextBoxX=messageTextFrame.origin.x-KONOTOR_HORIZONTAL_PADDING-(isAgentMessage?0:15);
    float messageTextBoxY=messageTextFrame.origin.y+(self.messageActionButton.isHidden?0:(KONOTOR_ACTIONBUTTON_HEIGHT+2*KONOTOR_VERTICAL_PADDING));
    float messageTextBoxWidth=messageTextFrame.size.width;
    
    switch (messageType) {

        case KonotorMessageTypePictureV2:
            
        case KonotorMessageTypePicture:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+messageTextFrame.size.height, messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT+4)];
            timeField.textContainerInset=UIEdgeInsetsMake(4, 0, 0, 0);
            
            break;
        }
            
            
        case KonotorMessageTypeAudio:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+(KONOTOR_SHOW_SENDERNAME?(KONOTOR_USERNAMEFIELD_HEIGHT+KONOTOR_AUDIOMESSAGE_HEIGHT):KONOTOR_AUDIOMESSAGE_HEIGHT), messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT)];
            
            if((KONOTOR_SHOW_TIMESTAMP)&&(KONOTOR_SHOW_SENDERNAME))
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
    
    [uploadStatusImageView setFrame:CGRectMake(messageTextBoxX+messageTextBoxWidth, messageTextBoxY+messageTextView.frame.size.height, 15, 15)];
    
}

- (void) adjustHeightForMessageBubble:(UIImageView*)messageBackground textView:(UITextView*)messageText actionUrl:(NSString*)actionUrl height:(float)msgHeight textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)KONOTOR_SHOW_SENDERNAME sender:(BOOL)isSenderOther textFrameAdjustY:(float)textViewY contentFrameAdjustY:(float)contentViewY{
    
    float messageTextBoxX=messageTextFrame.origin.x;
    float messageTextBoxY=messageTextFrame.origin.y;
    float messageTextBoxWidth=messageTextFrame.size.width;
    
    float messageContentViewX=messageContentFrame.origin.x;
    float messageContentViewY=messageContentFrame.origin.y;
    float messageContentViewWidth=messageContentFrame.size.width;
    
    
    messageText.frame=CGRectMake(messageTextBoxX, messageTextBoxY+textViewY, messageTextBoxWidth, msgHeight);
    
    msgHeight=msgHeight+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    
    msgHeight+=(actionUrl!=nil)?(KONOTOR_ACTIONBUTTON_HEIGHT+2*KONOTOR_VERTICAL_PADDING):0;
  
    messageBackground.frame=CGRectMake(messageContentViewX, messageContentViewY, messageContentViewWidth, msgHeight);
}

+(CGSize)getSizeOfTextViewWidth:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font{
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:font];
    [txtView setText:text];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width, 1000)];
    return size;
}

+(CGFloat)getTextViewLineHeight:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font{
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:font];
    [txtView setText:text];
    return txtView.font.lineHeight;
}

+(CGFloat)getTextViewHeightForMaxWidth:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font{
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:font];
    [txtView setText:text];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width, 1000)];
    return size.height-16;
}
/*
+ (NSMutableAttributedString*) getAttributedStringWithText:(NSString*) messageText font:(UIFont*)font{
    NSString *htmlString = messageText;
    NSDictionary* fontDict=[[NSDictionary alloc] initWithObjectsAndKeys:font,NSFontAttributeName,nil];
    NSMutableAttributedString* attributedString=nil;
    attributedString=[[NSMutableAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
    [attributedString addAttributes:fontDict range:NSMakeRange(0, [attributedString length])];
    return attributedString;
}*/

@end