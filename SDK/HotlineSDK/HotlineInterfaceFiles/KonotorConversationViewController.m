//
//  KonotorConversationViewController.m
//  KonotorSampleApp
//
//  Created by Srikrishnan Ganesan on 08/07/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorConversationViewController.h"
#import "FDUtilities.h"

@interface KonotorConversationViewController ()

@end

static int messageCount=0;
static NSArray* messages=nil;
static BOOL loading=NO;
static BOOL showingAlert=NO;
static NSString* copiedText=@"";
static NSData* copiedContent=nil;
static NSString* copiedMessageId=@"";
static int messageCount_prev=0;
static UIFont* KONOTOR_MESSAGETEXT_FONT=nil;
static NSString* copiedMimeType=@"";
static NSTimer* refreshMessagesTimer=nil;

static int numberOfMessagesShown=KONOTOR_MESSAGESPERPAGE;
static int loadMore=KONOTOR_MESSAGESPERPAGE;

static BOOL notificationCenterMode=NO;

NSMutableDictionary *messageHeights=nil;

UIImage* meImage=nil,*otherImage=nil,*sendingImage=nil,*sentImage=nil;

NSString* otherName=nil,*userName=nil;

@implementation TapOnPictureRecognizer

@synthesize height,width,image,imageURL;

@end

@implementation KonotorShareButton

@synthesize messageId;

@end

@implementation KonotorActionButton

@synthesize actionUrl;

@end

@implementation KonotorConversationViewController
@synthesize fullImageView;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [self.tableView setBackgroundColor:KONOTOR_MESSAGELAYOUT_BACKGROUND_COLOR];
    }
    return self;
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    KonotorUIParameters *konotorUIOptions=[KonotorUIParameters sharedInstance];
    if(konotorUIOptions.dismissesInputOnScroll)
        [KonotorTextInputOverlay dismissInput];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setDelegate:self];
    
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [Konotor sendAllUnsentMessages];
    
    KonotorUIParameters *konotorUIOptions=[KonotorUIParameters sharedInstance];
    
    notificationCenterMode=[KonotorUIParameters sharedInstance].notificationCenterMode;

    if(messageHeights==nil)
        messageHeights=[[NSMutableDictionary alloc] init];
    numberOfMessagesShown=KONOTOR_MESSAGESPERPAGE;
    
    messages=[Konotor getAllMessagesForDefaultConversation];
    
    if(!(konotorUIOptions.dontShowLoadingAnimation))
        loading=YES;
    else
        loading=NO;
    if(![Konotor areConversationsDownloading])
        [Konotor DownloadAllMessages];
    
    if(YES){
        meImage=[konotorUIOptions userProfileImage];
        if(meImage==nil) meImage=[UIImage imageNamed:@"konotor_profile.png"];
        otherImage=[konotorUIOptions otherProfileImage];
        if(otherImage==nil) otherImage=[UIImage imageNamed:@"konotor_supportprofile.png"];
    }
    sendingImage=[UIImage imageNamed:@"konotor_uploading.png"];
    sentImage=[UIImage imageNamed:@"konotor_sent.png"];
    
    KONOTOR_MESSAGETEXT_FONT=[konotorUIOptions messageTextFont];
    if(KONOTOR_MESSAGETEXT_FONT==nil)
        KONOTOR_MESSAGETEXT_FONT=KONOTOR_MESSAGETEXT_FONT_DEFAULT;
    
    otherName=[konotorUIOptions otherName];
    if(!otherName) otherName=@"Support";
    userName=[konotorUIOptions userName];
    if(!userName) userName=@"You";
    
    [Konotor markAllMessagesAsRead];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Konotor_FinishedMessagePull" object:nil];
    [self registerForKeyboardNotifications];
    
    if(refreshMessagesTimer){
        [refreshMessagesTimer invalidate];
        refreshMessagesTimer=nil;
    }
    
    
    if(konotorUIOptions.pollingTimeNotOnChatWindow>0){
        refreshMessagesTimer=[NSTimer scheduledTimerWithTimeInterval:((konotorUIOptions.pollingTimeNotOnChatWindow)>=5?konotorUIOptions.pollingTimeNotOnChatWindow:5)  target:[Konotor class] selector:@selector(DownloadAllMessages) userInfo:nil repeats:YES];
        [refreshMessagesTimer fire];
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    KonotorUIParameters *konotorUIOptions=[KonotorUIParameters sharedInstance];

    NSSortDescriptor* desc=[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:!(konotorUIOptions.notificationCenterMode)];
    messages=[[Konotor getAllMessagesForDefaultConversation] sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
    messageCount=(int)[messages count];
    if((numberOfMessagesShown>messageCount)||(messageCount<=KONOTOR_MESSAGESPERPAGE)||((messageCount-numberOfMessagesShown)<3))
        numberOfMessagesShown=messageCount;
    if(!loading)
        return numberOfMessagesShown;
    else
        return numberOfMessagesShown+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(((!notificationCenterMode)&&(loading)&&(indexPath.row==numberOfMessagesShown))||((notificationCenterMode)&&(loading)&&(indexPath.row==0)))
    {
        static NSString *CellIdentifier = @"KonotorRefreshCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell==nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setBackgroundColor:[UIColor clearColor]];
        
        UIActivityIndicatorView* refreshIndicator=(UIActivityIndicatorView*)[cell viewWithTag:KONOTOR_REFRESHINDICATOR_TAG];
        if(refreshIndicator==nil){
            refreshIndicator=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [refreshIndicator setFrame:CGRectMake(self.view.frame.size.width/2-10, cell.contentView.frame.size.height/2-10, 20, 20)];
            refreshIndicator.tag=KONOTOR_REFRESHINDICATOR_TAG;
            [cell.contentView addSubview:refreshIndicator];
        }
        if(![refreshIndicator isAnimating])
            [refreshIndicator startAnimating];
        
        return cell;
        
    }
    else if(indexPath.row==numberOfMessagesShown){
        static NSString *CellIdentifier = @"KonotorBlankCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell==nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
    else if((indexPath.row==(notificationCenterMode?(numberOfMessagesShown-1):0))&&(numberOfMessagesShown<messageCount)){
        static NSString *CellIdentifier = @"KonotorRefreshCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell==nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setBackgroundColor:[UIColor clearColor]];
        UIActivityIndicatorView* refreshIndicator=(UIActivityIndicatorView*)[cell viewWithTag:KONOTOR_REFRESHINDICATOR_TAG];
        if(refreshIndicator==nil){
            refreshIndicator=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [refreshIndicator setFrame:CGRectMake(self.view.frame.size.width/2-10, cell.contentView.frame.size.height/2-10, 20, 20)];
            refreshIndicator.tag=KONOTOR_REFRESHINDICATOR_TAG;
            [cell.contentView addSubview:refreshIndicator];
        }
        if(![refreshIndicator isAnimating])
            [refreshIndicator startAnimating];
        int oldnumber=numberOfMessagesShown;
        numberOfMessagesShown+=loadMore;
        if(numberOfMessagesShown>messageCount) numberOfMessagesShown=messageCount;
        [self performSelector:@selector(refreshView:) withObject:[NSNumber numberWithInt:oldnumber] afterDelay:0];
        return cell;
    }
    KonotorMessageData* currentMessage=(KonotorMessageData*)[messages objectAtIndex:((notificationCenterMode?(loading?-1:0):(messageCount-numberOfMessagesShown))+indexPath.row)];
    
    BOOL isSenderOther=([Konotor isUserMe:currentMessage.messageUserId])?NO:YES;
    BOOL KONOTOR_SHOWPROFILEIMAGE=((!isSenderOther)?([[KonotorUIParameters sharedInstance] userProfileImage]!=nil):([[KonotorUIParameters sharedInstance] otherProfileImage]!=nil));
    BOOL showsProfile=KONOTOR_SHOWPROFILEIMAGE;
    BOOL KONOTOR_SHOW_SENDERNAME=((!isSenderOther)?([[KonotorUIParameters sharedInstance] showUserName]):([[KonotorUIParameters sharedInstance] showOtherName]));
    float profileX=0.0, profileY=0.0, messageContentViewX=0.0, messageContentViewY=0.0, messageTextBoxX=0.0, messageTextBoxY=0.0,messageContentViewWidth=0.0,messageTextBoxWidth=0.0;
    NSString* customFontName=[[KonotorUIParameters sharedInstance] customFontName];
    
    if([KonotorUIParameters sharedInstance].notificationCenterMode&&!(isSenderOther)){
        static NSString *CellIdentifier = @"KonotorBlankCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell==nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        [cell setBackgroundColor:[UIColor clearColor]];
        return cell;
    }
    
    messageContentViewWidth = KONOTOR_TEXTMESSAGE_MAXWIDTH;
    if([currentMessage messageType].integerValue==KonotorMessageTypeText){
        CGSize sizer = [self getSizeOfTextViewWidth:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:currentMessage.text withFont:KONOTOR_MESSAGETEXT_FONT];
        int numLines = (sizer.height-10) / ([self getTextViewLineHeight:(KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING) text:currentMessage.text withFont:KONOTOR_MESSAGETEXT_FONT]);
        if (numLines == 1)
        {
            UITextView* tempView=[[UITextView alloc] initWithFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView setText:currentMessage.text];
            [tempView setFont:KONOTOR_MESSAGETEXT_FONT];
            CGSize txtSize = [tempView sizeThatFits:CGSizeMake(messageContentViewWidth, 1000)];
            
            NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
            NSString *strDate = [FDUtilities stringRepresentationForDate:date];

            UITextView* tempView2=[[UITextView alloc] initWithFrame:CGRectMake(0,0,messageContentViewWidth,1000)];
            [tempView2 setFont:(customFontName?[UIFont fontWithName:customFontName size:11.0]:[UIFont systemFontOfSize:11.0])];
            [tempView2 setText:strDate];
            CGSize txtTimeSize = [tempView2 sizeThatFits:CGSizeMake(messageContentViewWidth, 50)];
            CGFloat msgWidth = txtSize.width + 16 + 3 * KONOTOR_HORIZONTAL_PADDING;
            CGFloat timeWidth = (txtTimeSize.width + 16 +  5 * KONOTOR_HORIZONTAL_PADDING);
            
            if ( msgWidth < timeWidth)
            {
                messageContentViewWidth = timeWidth;
            }
            else
            {
                messageContentViewWidth = msgWidth;
                
            }
        }
    }
    
    
    // get the length of the textview if one line and calculate page sides
    
    float messageDisplayWidth=self.view.frame.size.width;
    
    
    if(showsProfile){
        profileX=isSenderOther?KONOTOR_HORIZONTAL_PADDING:(messageDisplayWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION);
        profileY=KONOTOR_VERTICAL_PADDING;
        messageContentViewY=KONOTOR_VERTICAL_PADDING;
        messageContentViewWidth=MIN(messageDisplayWidth-KONOTOR_PROFILEIMAGE_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING,messageContentViewWidth);
        messageContentViewX=isSenderOther?(profileX+KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_HORIZONTAL_PADDING):(messageDisplayWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PROFILEIMAGE_DIMENSION-KONOTOR_HORIZONTAL_PADDING-messageContentViewWidth);
        
        messageTextBoxWidth=messageContentViewWidth-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
        messageTextBoxX=isSenderOther?(messageContentViewX+KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING):(messageContentViewX+KONOTOR_HORIZONTAL_PADDING);
        
        messageTextBoxY=isSenderOther?(messageContentViewY+(KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING):0)):(messageContentViewY+(KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING):0));
    }
    else{
        
        messageContentViewY=KONOTOR_VERTICAL_PADDING;
        messageContentViewWidth= MIN(messageDisplayWidth-8*KONOTOR_HORIZONTAL_PADDING,messageContentViewWidth);
        messageContentViewX=isSenderOther?(KONOTOR_HORIZONTAL_PADDING*2):(messageDisplayWidth-2*KONOTOR_HORIZONTAL_PADDING-messageContentViewWidth);
        messageTextBoxWidth=messageContentViewWidth-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
        messageTextBoxX=isSenderOther?(messageContentViewX+KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING):(messageContentViewX+KONOTOR_HORIZONTAL_PADDING);
        messageTextBoxY=isSenderOther?(messageContentViewY+(KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING):0)):(messageContentViewY+(KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING):0));
    }
    
    CGRect messageTextBoxFrame=CGRectMake(messageTextBoxX,messageTextBoxY,messageTextBoxWidth,0);
    CGRect messageContentViewFrame=CGRectMake(messageContentViewX, messageContentViewY, messageContentViewWidth, 0);
    
    static NSString *CellIdentifier = @"KonotorMessagesTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIImageView *messageBackground=[[UIImageView alloc] initWithFrame:CGRectMake((KONOTOR_SHOWPROFILEIMAGE?1:0)*(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_HORIZONTAL_PADDING)+KONOTOR_HORIZONTAL_PADDING, KONOTOR_VERTICAL_PADDING, 1, 1)];
        UIEdgeInsets insets=UIEdgeInsetsMake(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_BOTTOM_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_RIGHT_INSET);
        [messageBackground setImage:[[UIImage imageNamed:@"konotor_chatbubble_ios7_other.png"] resizableImageWithCapInsets:insets]];
        messageBackground.tag=KONOTOR_CALLOUT_TAG;
        [cell.contentView addSubview:messageBackground];
        
        UITextView *userNameField=[[UITextView alloc] initWithFrame:CGRectMake(messageTextBoxX, messageTextBoxY, messageTextBoxWidth, KONOTOR_USERNAMEFIELD_HEIGHT)];
        
        if([userNameField respondsToSelector:@selector(textContainerInset)])
            [userNameField setTextContainerInset:UIEdgeInsetsMake(4, 0, 0, 0)];
        else
            userNameField.contentInset=UIEdgeInsetsMake(-4, 0,-4,0);
        [userNameField setFont:(customFontName?[UIFont fontWithName:customFontName size:12.0]:[UIFont systemFontOfSize:12.0])];
        [userNameField setBackgroundColor:KONOTOR_MESSAGE_BACKGROUND_COLOR];
        
        [userNameField setTextAlignment:NSTextAlignmentLeft];
        if(isSenderOther)
            [userNameField setTextColor:[UIColor darkGrayColor]];
        else
            [userNameField setTextColor:KONOTOR_UIBUTTON_COLOR];
        [userNameField setEditable:NO];
        [userNameField setScrollEnabled:NO];
        if([userNameField respondsToSelector:@selector(setSelectable:)])
            [userNameField setSelectable:NO];
        //   [userNameField setContentOffset:CGPointMake(0,-4)];
        // [userNameField setContentSize:CGSizeMake(messageTextBoxWidth, KONOTOR_USERNAMEFIELD_HEIGHT)];
        userNameField.tag=KONOTOR_USERNAMEFIELD_TAG;
        //if(KONOTOR_SHOW_SENDERNAME)
        [cell.contentView addSubview:userNameField];
        
        UITextView *timeField=[[UITextView alloc] initWithFrame:CGRectMake(messageTextBoxX, messageTextBoxY+((KONOTOR_SHOW_SENDERNAME)?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING), messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT)];
        [timeField setFont:(customFontName?[UIFont fontWithName:customFontName size:11.0]:[UIFont systemFontOfSize:11.0])];
        [timeField setBackgroundColor:KONOTOR_MESSAGE_BACKGROUND_COLOR];
        [timeField setTextAlignment:NSTextAlignmentLeft];
        [timeField setTextColor:[UIColor darkGrayColor]];
        [timeField setEditable:NO];
        if([timeField respondsToSelector:@selector(setSelectable:)])
            [timeField setSelectable:NO];
        [timeField setScrollEnabled:NO];
        timeField.tag=KONOTOR_TIMEFIELD_TAG;
        if(KONOTOR_SHOW_TIMESTAMP)
            [cell.contentView addSubview:timeField];
        
        UITextView* messageText=[[UITextView alloc] initWithFrame:CGRectMake((KONOTOR_SHOWPROFILEIMAGE?1:0)*(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_HORIZONTAL_PADDING)+KONOTOR_HORIZONTAL_PADDING, KONOTOR_VERTICAL_PADDING+KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING, self.view.frame.size.width-(KONOTOR_SHOWPROFILEIMAGE?1:0)*(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_HORIZONTAL_PADDING)-30, 10)];
        [messageText setFont:KONOTOR_MESSAGETEXT_FONT];
        [messageText setBackgroundColor:KONOTOR_MESSAGE_BACKGROUND_COLOR];
        [messageText setDataDetectorTypes:UIDataDetectorTypeLink];
        [messageText setTextAlignment:NSTextAlignmentLeft];
        [messageText setTextColor:[UIColor blackColor]];
        [messageText setEditable:NO];
        [messageText setScrollEnabled:NO];
        messageText.scrollsToTop=NO;
        messageText.tag=KONOTOR_MESSAGETEXTVIEW_TAG;
        
        
        
        KonotorMediaUIButton *playButton=[[KonotorMediaUIButton alloc] initWithFrame:CGRectMake(messageTextBoxWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_AUDIOMESSAGE_HEIGHT/2-KONOTOR_PLAYBUTTON_DIMENSION/2,KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_PLAYBUTTON_DIMENSION)];
        [playButton setImage:[UIImage imageNamed:@"konotor_play.png"] forState:UIControlStateNormal];
        [playButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [playButton setBackgroundColor:KONOTOR_UIBUTTON_COLOR];
        playButton.layer.cornerRadius=KONOTOR_PLAYBUTTON_DIMENSION/2;
        [playButton addTarget:self action:@selector(playMedia:) forControlEvents:UIControlEventTouchUpInside];
        playButton.tag=KONOTOR_PLAYBUTTON_TAG;
        
        [messageText addSubview:playButton];
        
        playButton.mediaProgressBar=[[UISlider alloc] initWithFrame:CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-2, messageDisplayWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, 4)];
        playButton.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-playButton.mediaProgressBar.currentThumbImage.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, playButton.mediaProgressBar.currentThumbImage.size.height);
        playButton.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-playButton.mediaProgressBar.bounds.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, playButton.mediaProgressBar.bounds.size.height);
        [playButton.mediaProgressBar setMinimumTrackImage:[UIImage imageNamed:@"konotor_progress_blue.png"] forState:UIControlStateNormal];
        [playButton.mediaProgressBar setMaximumTrackImage:[UIImage imageNamed:@"konotor_progress_black.png"] forState:UIControlStateNormal];
        
        [messageText addSubview:playButton.mediaProgressBar];
        
        
        [cell.contentView addSubview:messageText];
        
        UIImageView* profileImage=[[UIImageView alloc] initWithFrame:CGRectMake(profileX, profileY, KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION)];
        profileImage.tag=KONOTOR_PROFILEIMAGE_TAG;
        [cell.contentView addSubview:profileImage];
        
        UIImageView* uploadStatus=[[UIImageView alloc] initWithFrame:CGRectMake(messageTextBoxX+messageTextBoxWidth-15-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING, KONOTOR_VERTICAL_PADDING+6+(isSenderOther?((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)):((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0))), 15, 15)];
        [uploadStatus setImage:sentImage];
        uploadStatus.tag=KONOTOR_UPLOADSTATUS_TAG;
        if(KONOTOR_SHOW_UPLOADSTATUS)
            [cell.contentView addSubview:uploadStatus];
        UIImageView* picView=[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, KONOTOR_TEXTMESSAGE_MAXWIDTH, 0)];
        picView.tag=KONOTOR_PICTURE_TAG;
        [messageText addSubview:picView];
        
        KonotorActionButton* actionButton=[KonotorActionButton buttonWithType:UIButtonTypeCustom];
        [self setStyleForActionButton:actionButton];
        [actionButton setHidden:YES];
        actionButton.actionUrl=nil;
        actionButton.tag=KONOTOR_ACTIONBUTTON_TAG;
        [actionButton addTarget:self action:@selector(openActionUrl:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:actionButton];
    }
    else{
        KonotorMediaUIButton* playButton=(KonotorMediaUIButton*)[cell.contentView viewWithTag:KONOTOR_PLAYBUTTON_TAG];
        playButton.frame=CGRectMake(messageTextBoxWidth-KONOTOR_HORIZONTAL_PADDING-KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_AUDIOMESSAGE_HEIGHT/2-KONOTOR_PLAYBUTTON_DIMENSION/2,KONOTOR_PLAYBUTTON_DIMENSION,KONOTOR_PLAYBUTTON_DIMENSION);
        playButton.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-playButton.mediaProgressBar.currentThumbImage.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, playButton.mediaProgressBar.currentThumbImage.size.height);
        playButton.mediaProgressBar.frame=CGRectMake(KONOTOR_HORIZONTAL_PADDING, KONOTOR_AUDIOMESSAGE_HEIGHT/2-playButton.mediaProgressBar.bounds.size.height/2, messageTextBoxWidth-KONOTOR_PLAYBUTTON_DIMENSION-3*KONOTOR_HORIZONTAL_PADDING, playButton.mediaProgressBar.bounds.size.height);
        
    }
    
    // Configure the cell...
    
    UITextView* messageText=(UITextView*)[cell.contentView viewWithTag:KONOTOR_MESSAGETEXTVIEW_TAG];
    UIImageView* messageBackground=(UIImageView*)[cell.contentView viewWithTag:KONOTOR_CALLOUT_TAG];
    KonotorMediaUIButton* playButton=(KonotorMediaUIButton*)[cell.contentView viewWithTag:KONOTOR_PLAYBUTTON_TAG];
    [playButton stopAnimating];
    
    UITextView* userNameField=(UITextView*)[cell.contentView viewWithTag:KONOTOR_USERNAMEFIELD_TAG];
    UITextView* timeField=(UITextView*)[cell.contentView viewWithTag:KONOTOR_TIMEFIELD_TAG];
    
    KonotorActionButton* actionButton = (KonotorActionButton*)[cell.contentView viewWithTag:KONOTOR_ACTIONBUTTON_TAG];
    
    [userNameField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY, messageTextBoxWidth, KONOTOR_USERNAMEFIELD_HEIGHT)];
    if(KONOTOR_SHOW_SENDERNAME)
        [userNameField setHidden:NO];
    else
        [userNameField setHidden:YES];
    
    UIImageView* uploadStatus=(UIImageView*)[cell.contentView viewWithTag:KONOTOR_UPLOADSTATUS_TAG];
    [uploadStatus setFrame:CGRectMake(messageTextBoxX+messageTextBoxWidth-15-6, KONOTOR_VERTICAL_PADDING+6+(isSenderOther?((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)):((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0))), 15, 15)];
    if([currentMessage uploadStatus].integerValue==MessageUploaded)
        [uploadStatus setImage:sentImage];
    else
        [uploadStatus setImage:sendingImage];
    UIImageView* picView=(UIImageView*)[messageText viewWithTag:KONOTOR_PICTURE_TAG];
    
    UIEdgeInsets insets=UIEdgeInsetsMake(KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_BOTTOM_INSET, KONOTOR_MESSAGE_BACKGROUND_IMAGE_RIGHT_INSET);
    
    KonotorUIParameters* interfaceOptions=[KonotorUIParameters sharedInstance];
    if(isSenderOther){
        userNameField.text=otherName;
        [uploadStatus setImage:nil];
        [userNameField setBackgroundColor:KONOTOR_SUPPORTMESSAGE_BACKGROUND_COLOR];
        [timeField setBackgroundColor:KONOTOR_SUPPORTMESSAGE_BACKGROUND_COLOR];
        [messageText setBackgroundColor:KONOTOR_SUPPORTMESSAGE_BACKGROUND_COLOR];
        [messageBackground setImage:[((interfaceOptions.otherChatBubble==nil)?[UIImage imageNamed:@"konotor_chatbubble_ios7_other.png"]:interfaceOptions.otherChatBubble) resizableImageWithCapInsets:insets]];
        [userNameField setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERNAME_TEXT_COLOR:interfaceOptions.otherTextColor)];
        [messageText setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERMESSAGE_TEXT_COLOR:interfaceOptions.otherTextColor)];
        [timeField setTextColor:((interfaceOptions.otherTextColor==nil)?KONOTOR_OTHERTIMESTAMP_COLOR:interfaceOptions.otherTextColor)];
    }
    else{
        userNameField.text=userName;
        [userNameField setBackgroundColor:KONOTOR_MESSAGE_BACKGROUND_COLOR];
        [timeField setBackgroundColor:KONOTOR_MESSAGE_BACKGROUND_COLOR];
        [messageText setBackgroundColor:KONOTOR_MESSAGE_BACKGROUND_COLOR];
        [messageBackground setImage:[((interfaceOptions.userChatBubble==nil)?[UIImage imageNamed:@"konotor_chatbubble_ios7_you.png"]:interfaceOptions.userChatBubble) resizableImageWithCapInsets:insets]];
        [userNameField setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERNAME_TEXT_COLOR:interfaceOptions.userTextColor)];
        [messageText setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERMESSAGE_TEXT_COLOR:interfaceOptions.userTextColor)];
        [timeField setTextColor:((interfaceOptions.userTextColor==nil)?KONOTOR_USERTIMESTAMP_COLOR:interfaceOptions.userTextColor)];

    }
    
    NSDate* date=[NSDate dateWithTimeIntervalSince1970:currentMessage.createdMillis.longLongValue/1000];
    [timeField setText:[FDUtilities stringRepresentationForDate:date]];
    
    NSString* actionUrl=currentMessage.actionURL;
    NSString* actionLabel=currentMessage.actionLabel;
    
    if([messageText respondsToSelector:@selector(setTextContainerInset:)])
        [messageText setTextContainerInset:UIEdgeInsetsMake(6, 0, 8, 0)];
    
    [self adjustPositionForTimeView:timeField textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:KONOTOR_SHOW_SENDERNAME messageType:(enum KonotorMessageType)[currentMessage messageType].integerValue];


    if([currentMessage messageType].integerValue==KonotorMessageTypeText)
    {
        [playButton.mediaProgressBar setHidden:YES];
        [playButton setHidden:YES];
        
        [messageText setText:nil];
        [messageText setDataDetectorTypes:UIDataDetectorTypeNone];
        [messageText setText:[NSString stringWithFormat:@"\u200b%@",currentMessage.text]];
        [messageText setDataDetectorTypes:(UIDataDetectorTypeLink|UIDataDetectorTypePhoneNumber)];
        
        CGSize sizer = [self getSizeOfTextViewWidth:messageTextBoxWidth text:currentMessage.text withFont:KONOTOR_MESSAGETEXT_FONT];
        float msgHeight=sizer.height;
        float textViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0);
        float contentViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0)+(isSenderOther?((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)):((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)));
     
        [self adjustHeightForMessageBubble:messageBackground textView:messageText actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:KONOTOR_SHOW_SENDERNAME sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
        [picView setHidden:YES];
        [self setupActionButtonWithUrlString:actionUrl label:actionLabel actionButton:actionButton frame:messageText.frame];

    }
    else if([currentMessage messageType].integerValue==KonotorMessageTypeAudio){
        [messageText setText:@""];
        
        float msgHeight=KONOTOR_AUDIOMESSAGE_HEIGHT;
        float textViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:(KONOTOR_SHOW_TIMESTAMP?(KONOTOR_TIMEFIELD_HEIGHT+KONOTOR_VERTICAL_PADDING):KONOTOR_VERTICAL_PADDING));
        float contentViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
        
        [self adjustHeightForMessageBubble:messageBackground textView:messageText actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:KONOTOR_SHOW_SENDERNAME sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];

        
        [playButton.mediaProgressBar setHidden:NO];
        [playButton setHidden:NO];
        
        playButton.messageID=[currentMessage messageId];
        playButton.message=currentMessage;
        
        [playButton.mediaProgressBar setValue:0.0 animated:NO];
        [playButton.mediaProgressBar setMaximumValue:currentMessage.durationInSecs.floatValue];
        if([[Konotor getCurrentPlayingMessageID] isEqualToString:[currentMessage messageId]])
            [playButton startAnimating];
        [picView setHidden:YES];
        [self setupActionButtonWithUrlString:actionUrl label:actionLabel actionButton:actionButton frame:messageText.frame];
        
    }
    else if(([currentMessage messageType].integerValue==KonotorMessageTypePicture)||([currentMessage messageType].integerValue==KonotorMessageTypePictureV2)){
        if((![currentMessage picData])&&(([[currentMessage picUrl] isEqualToString:@""])|| ([currentMessage picUrl]==nil)))
            [messageText setText:@"Image Not Found"];
        else
            [messageText setText:@""];
        
        float height=MIN([[currentMessage picThumbHeight] floatValue],KONOTOR_IMAGE_MAXHEIGHT);
        float imgwidth=[[currentMessage picThumbWidth] floatValue];
        if(height!=[[currentMessage picThumbHeight] floatValue]){
            imgwidth=[[currentMessage picThumbWidth] floatValue]*(height/[[currentMessage picThumbHeight] floatValue]);
        }
        if(imgwidth>KONOTOR_IMAGE_MAXWIDTH)
        {
            imgwidth=KONOTOR_IMAGE_MAXWIDTH;
            height=[[currentMessage picThumbHeight] floatValue]*(imgwidth/[[currentMessage picThumbWidth] floatValue]);
        }

        float txtheight=0.0;
        
        currentMessage.picCaption=(currentMessage.isMarketingMessage?currentMessage.text:@"");

        if((currentMessage.picCaption)&&(![currentMessage.picCaption isEqualToString:@""])){
            NSString *htmlString = currentMessage.picCaption;
            NSDictionary* fontDict=[[NSDictionary alloc] initWithObjectsAndKeys:messageText.font,NSFontAttributeName,nil];
            NSMutableAttributedString* attributedString=nil;
            attributedString=[[NSMutableAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
            [attributedString addAttributes:fontDict range:NSMakeRange(0, [attributedString length])];
            if(isSenderOther){
                [attributedString addAttribute:NSForegroundColorAttributeName value:KONOTOR_OTHERMESSAGE_TEXT_COLOR range:NSMakeRange(0, [attributedString length])];
            }
            else{
                [attributedString addAttribute:NSForegroundColorAttributeName value:KONOTOR_USERMESSAGE_TEXT_COLOR range:NSMakeRange(0, [attributedString length])];
            }

            if([messageText respondsToSelector:@selector(setAttributedText:)])
                messageText.attributedText = attributedString;
            else
                [messageText setText:[attributedString string]];
            
            txtheight=[messageText sizeThatFits:CGSizeMake(messageTextBoxWidth, 1000)].height-16;
            
            if([messageText respondsToSelector:@selector(setTextContainerInset:)]){
                [messageText setTextContainerInset:UIEdgeInsetsMake(height+10, 0, 0, 0)];
            }
            
        }
        
        
        float msgHeight=16+height+txtheight;
        float textViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0);
        float contentViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
        
        [self adjustHeightForMessageBubble:messageBackground textView:messageText actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:KONOTOR_SHOW_SENDERNAME sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];

        
        [playButton.mediaProgressBar setHidden:YES];
        [playButton setHidden:YES];
        [picView setHidden:NO];
        
        picView.layer.cornerRadius=10.0;
        picView.layer.masksToBounds=YES;
        picView.tag=KONOTOR_PICTURE_TAG;
        TapOnPictureRecognizer* tapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
        tapGesture.numberOfTapsRequired=1;
        if([currentMessage picData]){
            tapGesture.image=[UIImage imageWithData:[currentMessage picData]];
        }
        else{
            tapGesture.imageURL=[NSURL URLWithString:[currentMessage picUrl]];
            tapGesture.image=nil;
        }
        tapGesture.height=[[currentMessage picHeight] floatValue];
        tapGesture.width=[[currentMessage picWidth] floatValue];
        picView.userInteractionEnabled=YES;
        NSArray* gestureRecognizers=[picView gestureRecognizers];
        for(UIGestureRecognizer* gr in gestureRecognizers){
            if([gr isKindOfClass:[TapOnPictureRecognizer class]])
                [picView removeGestureRecognizer:gr];
        }
        [picView addGestureRecognizer:tapGesture];

        
        if([currentMessage picThumbData]){
            UIImage *picture=[UIImage imageWithData:[currentMessage picThumbData]];
            [picView setFrame:CGRectMake((KONOTOR_TEXTMESSAGE_MAXWIDTH-imgwidth)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, 8, imgwidth, height)];
            [picView setImage:picture];
            
            if(![currentMessage picData]){
                dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                dispatch_async(q, ^{
                    /* Fetch the image from the server... */
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[currentMessage picUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(data){
                            [Konotor setBinaryImage:data forMessageId:[currentMessage messageId]];
                            currentMessage.picData=data;
                            picView.layer.cornerRadius=10.0;
                            picView.layer.masksToBounds=YES;
                            picView.tag=KONOTOR_PICTURE_TAG;
                            TapOnPictureRecognizer* tapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
                            tapGesture.numberOfTapsRequired=1;
                            if(data)
                                tapGesture.image=[UIImage imageWithData:data];
                            else{
                                tapGesture.imageURL=[NSURL URLWithString:[currentMessage picUrl]];
                                tapGesture.image=nil;
                            }
                            tapGesture.height=[[currentMessage picHeight] floatValue];
                            tapGesture.width=[[currentMessage picWidth] floatValue];
                            picView.userInteractionEnabled=YES;
                            NSArray* gestureRecognizers=[picView gestureRecognizers];
                            for(UIGestureRecognizer* gr in gestureRecognizers){
                                if([gr isKindOfClass:[TapOnPictureRecognizer class]])
                                    [picView removeGestureRecognizer:gr];
                            }
                            [picView addGestureRecognizer:tapGesture];

                        }
                    });
                });

            }
        }
        else{
            if(height>100)
                [picView setFrame:CGRectMake((KONOTOR_TEXTMESSAGE_MAXWIDTH-110)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, (height-100)/2, 110, 100)];
            else{
                [picView setFrame:CGRectMake((KONOTOR_TEXTMESSAGE_MAXWIDTH-height*110/100)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, 8, height*110/100, height)];
            }
            [picView setImage:[UIImage imageNamed:@"konotor_placeholder"]];
            
            dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(q, ^{
                /* Fetch the image from the server... */
                NSData *thumbData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[currentMessage picThumbUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(thumbData){
                        [Konotor setBinaryImageThumbnail:thumbData forMessageId:[currentMessage messageId]];
                        currentMessage.picThumbData=thumbData;
                        UIImage *img = [[UIImage alloc] initWithData:thumbData];
                        
                        /* This is the main thread again, where we set the image to
                         be what we just fetched. */
                        [picView setFrame:CGRectMake((KONOTOR_TEXTMESSAGE_MAXWIDTH-imgwidth)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, 8, imgwidth, height)];
                        [picView setImage:img];
                    }
                });
                
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[currentMessage picUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(data){
                        [Konotor setBinaryImage:data forMessageId:[currentMessage messageId]];
                        currentMessage.picData=data;
                        picView.layer.cornerRadius=10.0;
                        picView.layer.masksToBounds=YES;
                        picView.tag=KONOTOR_PICTURE_TAG;
                        TapOnPictureRecognizer* tapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
                        tapGesture.numberOfTapsRequired=1;
                        if(data)
                            tapGesture.image=[UIImage imageWithData:data];
                        else{
                            tapGesture.imageURL=[NSURL URLWithString:[currentMessage picUrl]];
                            tapGesture.image=nil;
                        }
                        tapGesture.height=[[currentMessage picHeight] floatValue];
                        tapGesture.width=[[currentMessage picWidth] floatValue];
                        picView.userInteractionEnabled=YES;
                        NSArray* gestureRecognizers=[picView gestureRecognizers];
                        for(UIGestureRecognizer* gr in gestureRecognizers){
                            if([gr isKindOfClass:[TapOnPictureRecognizer class]])
                                [picView removeGestureRecognizer:gr];
                        }
                        [picView addGestureRecognizer:tapGesture];

                    }
                });
            });
        }
        [self setupActionButtonWithUrlString:actionUrl label:actionLabel actionButton:actionButton frame:messageText.frame];
        
    }
    else if([currentMessage messageType].integerValue==KonotorMessageTypeHTML)
    {
        [playButton.mediaProgressBar setHidden:YES];
        [playButton setHidden:YES];
        
        NSString *htmlString = currentMessage.text;
        NSDictionary* fontDict=[[NSDictionary alloc] initWithObjectsAndKeys:messageText.font,NSFontAttributeName,nil];
        NSMutableAttributedString* attributedString=nil;
        attributedString=[[NSMutableAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];
        [attributedString addAttributes:fontDict range:NSMakeRange(0, [attributedString length])];
        
        if([messageText respondsToSelector:@selector(setAttributedText:)])
            messageText.attributedText = attributedString;
        else
            [messageText setText:[attributedString string]];
        
        CGSize sizer=[messageText sizeThatFits:CGSizeMake(messageTextBoxWidth, 1000)];
        
        float msgHeight=sizer.height;
        float textViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0);
        float contentViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0)+(isSenderOther?((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)):((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)));
        
        [self adjustHeightForMessageBubble:messageBackground textView:messageText actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:KONOTOR_SHOW_SENDERNAME sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
  
        [picView setHidden:YES];
        [self setupActionButtonWithUrlString:actionUrl label:actionLabel actionButton:actionButton frame:messageText.frame];

        
    }

    else
    {
        [playButton.mediaProgressBar setHidden:YES];
        [playButton setHidden:YES];
        [picView setHidden:YES];
        
        if(([currentMessage text]!=nil)&&(![[currentMessage text] isEqualToString:@""]))
            [messageText setText:currentMessage.text];
        else
            [messageText setText:@"Message cannot be displayed. Please upgrade your app to view new messages."];
                
        CGSize sizer=[messageText sizeThatFits:CGSizeMake(messageTextBoxWidth, 1000)];
        
        float msgHeight=sizer.height;
        float textViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0);
        float contentViewY=(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0)+(isSenderOther?((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)):((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)));
        
        [self adjustHeightForMessageBubble:messageBackground textView:messageText actionUrl:actionUrl height:msgHeight textBoxRect:messageTextBoxFrame contentViewRect:messageContentViewFrame showsSenderName:KONOTOR_SHOW_SENDERNAME sender:isSenderOther textFrameAdjustY:textViewY contentFrameAdjustY:contentViewY];
        
    }
    
    if(showsProfile){
        UIImageView* profileImage=(UIImageView*)[cell.contentView viewWithTag:KONOTOR_PROFILEIMAGE_TAG];
        if(profileImage)
            [profileImage setHidden:NO];
        if(isSenderOther)
            [profileImage setImage:otherImage];
        else
            [profileImage setImage:meImage];
        [profileImage setFrame:CGRectMake(profileX,messageBackground.frame.origin.y+messageBackground.frame.size.height-KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION, KONOTOR_PROFILEIMAGE_DIMENSION)];
    }
    else{
        UIImageView* profileImage=(UIImageView*)[cell.contentView viewWithTag:KONOTOR_PROFILEIMAGE_TAG];
        if(profileImage)
            [profileImage setHidden:YES];
    }

    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.contentView setClipsToBounds:YES];
    cell.tag=[currentMessage.messageId hash];
    
    return cell;
    
}

- (void) tappedOnPicture:(id) sender
{
    TapOnPictureRecognizer* picView=(TapOnPictureRecognizer*)sender;
    fullImageView=[[KonotorImageView alloc] init];
    fullImageView.img=picView.image;
    fullImageView.imgHeight=picView.height;
    fullImageView.imgWidth=picView.width;
    fullImageView.imgURL=picView.imageURL;
    fullImageView.sourceViewController=self;
    [fullImageView showImageView];

    [[KonotorFeedbackScreen sharedInstance].conversationViewController.navigationController
     setNavigationBarHidden:YES animated:NO];
    
}

- (void) dismissImageView{
    [fullImageView removeFromSuperview];
    fullImageView=nil;
    [[KonotorFeedbackScreen sharedInstance].conversationViewController.navigationController
     setNavigationBarHidden:NO animated:NO];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    [super viewWillAppear:animated];
    
}

- (void) viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    if(![Konotor areConversationsDownloading])
        [Konotor DownloadAllMessages];
    
    KonotorUIParameters *konotorUIOptions=[KonotorUIParameters sharedInstance];
    
    
    if(refreshMessagesTimer){
        if(([refreshMessagesTimer isValid])&&([refreshMessagesTimer timeInterval]!=konotorUIOptions.pollingTimeOnChatWindow))
        {
            [refreshMessagesTimer invalidate];
            refreshMessagesTimer=nil;
        }
    }
    
    if((refreshMessagesTimer==nil)||(![refreshMessagesTimer isValid])){
        BOOL notificationEnabled=NO;
        
#if(__IPHONE_OS_VERSION_MAX_ALLOWED >=80000)
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
            notificationEnabled=[[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
        }
        else
#endif
        {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
            UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
            if(types != UIRemoteNotificationTypeNone) notificationEnabled=YES;
#endif
        }
        
        
        
        if ((!notificationEnabled)||konotorUIOptions.alwaysPollForMessages) {
            if(refreshMessagesTimer)
                [refreshMessagesTimer invalidate];
            refreshMessagesTimer=[NSTimer scheduledTimerWithTimeInterval:((konotorUIOptions.pollingTimeOnChatWindow)>=5?konotorUIOptions.pollingTimeOnChatWindow:5)  target:[Konotor class] selector:@selector(DownloadAllMessages) userInfo:nil repeats:YES];
            [refreshMessagesTimer fire];
        }
        
    }
    [Konotor setDelegate:self];
    
}


- (void) viewWillDisappear:(BOOL)animated
{
    [refreshMessagesTimer invalidate];
    refreshMessagesTimer=nil;
    [Konotor setDelegate:[KonotorEventHandler sharedInstance]];
    
    KonotorUIParameters *konotorUIOptions=[KonotorUIParameters sharedInstance];
    
    if(konotorUIOptions.pollingTimeNotOnChatWindow>0){
        refreshMessagesTimer=[NSTimer scheduledTimerWithTimeInterval:((konotorUIOptions.pollingTimeNotOnChatWindow)>=5?konotorUIOptions.pollingTimeNotOnChatWindow:5)  target:[Konotor class] selector:@selector(DownloadAllMessages) userInfo:nil repeats:YES];
        [refreshMessagesTimer fire];
    }
    [super viewWillDisappear:animated];
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void) adjustTableViewWithInset:(float)verticalInset
{
    UIEdgeInsets contentInsets=self.tableView.contentInset;
    
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(contentInsets.top, contentInsets.left,verticalInset , contentInsets.right);
    } else {
        contentInsets = UIEdgeInsetsMake(contentInsets.top, contentInsets.left,verticalInset , contentInsets.right);
    }
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    int lastSpot=loading?numberOfMessagesShown:(numberOfMessagesShown-1);
    
    if([KonotorUIParameters sharedInstance].notificationCenterMode) lastSpot=0;
    
    if(lastSpot<0) return;
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:lastSpot inSection:0];
    
    @try {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    @catch (NSException *exception ) {
        indexPath=[NSIndexPath indexPathForRow:(indexPath.row-1) inSection:0];
        @try{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        @catch(NSException *exception){
            
        }
    }
    
}



- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    notificationCenterMode=[KonotorUIParameters sharedInstance].notificationCenterMode;

    if(((!notificationCenterMode)&&(indexPath.row==numberOfMessagesShown))||((notificationCenterMode)&&(indexPath.row==0)&&loading))
        return 40;
    else if((indexPath.row==(notificationCenterMode?numberOfMessagesShown:0))&&(numberOfMessagesShown<messageCount))
        return 40;
    
    
    KonotorMessageData* currentMessage=(KonotorMessageData*)[messages objectAtIndex:((notificationCenterMode?(loading?-1:0):(messageCount-numberOfMessagesShown))+indexPath.row)];

    if([messageHeights valueForKey:currentMessage.messageId]!=nil)
    {
        return [(NSNumber*)[messageHeights valueForKey:currentMessage.messageId] floatValue];
    }

    BOOL isSenderOther;
    isSenderOther=([Konotor isUserMe:[currentMessage messageUserId]])?NO:YES;
    BOOL KONOTOR_SHOWPROFILEIMAGE=((!isSenderOther)?([[KonotorUIParameters sharedInstance] userProfileImage]!=nil):([[KonotorUIParameters sharedInstance] otherProfileImage]!=nil));
    BOOL KONOTOR_SHOW_SENDERNAME=((!isSenderOther)?([[KonotorUIParameters sharedInstance] showUserName]):([[KonotorUIParameters sharedInstance] showOtherName]));
    
    if([KonotorUIParameters sharedInstance].notificationCenterMode&&(!isSenderOther)) return 0;
    
    float maxTextWidth=KONOTOR_TEXTMESSAGE_MAXWIDTH-KONOTOR_MESSAGE_BACKGROUND_IMAGE_SIDE_PADDING;
    float widthBufferIfNoProfileImage=5*KONOTOR_HORIZONTAL_PADDING;
    float maxAvailableWidth=self.view.frame.size.width-3*KONOTOR_HORIZONTAL_PADDING-(KONOTOR_SHOWPROFILEIMAGE?KONOTOR_PROFILEIMAGE_DIMENSION:widthBufferIfNoProfileImage);
    float width=MIN(maxAvailableWidth,maxTextWidth);
    float extraHeight=(isSenderOther?
                       ((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_OTHER?
                          KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)):
                       ((KONOTOR_MESSAGE_BACKGROUND_TOP_PADDING_ME?
                          KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)))
                        +KONOTOR_VERTICAL_PADDING+16
                        +(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:0)
                        +(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:0)
                        +KONOTOR_VERTICAL_PADDING*2;
    float minimumHeight=(KONOTOR_PROFILEIMAGE_DIMENSION+KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2;
    
    float cellHeight=0;
    
    if([currentMessage messageType].integerValue==KonotorMessageTypeText){
        float height=[self getTextViewHeightForMaxWidth:width text:[currentMessage text] withFont:KONOTOR_MESSAGETEXT_FONT];
        if(KONOTOR_SHOWPROFILEIMAGE){
            cellHeight= MAX(height+extraHeight,
                            minimumHeight);
        }
        else{
            cellHeight= height+extraHeight;
        }
        
    }
    else if([currentMessage messageType].integerValue==KonotorMessageTypeAudio){
        cellHeight= KONOTOR_AUDIOMESSAGE_HEIGHT+(KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)+KONOTOR_VERTICAL_PADDING+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
    }
    else if(([currentMessage messageType].integerValue==KonotorMessageTypePicture)||([currentMessage messageType].integerValue==KonotorMessageTypePictureV2)){
        float height=MIN([[currentMessage picThumbHeight] floatValue], KONOTOR_IMAGE_MAXHEIGHT);
        float imgwidth=[[currentMessage picThumbWidth] floatValue];
        if(height!=[[currentMessage picThumbHeight] floatValue]){
            imgwidth=[[currentMessage picThumbWidth] floatValue]*(height/[[currentMessage picThumbHeight] floatValue]);
        }
        if(imgwidth>KONOTOR_IMAGE_MAXWIDTH)
        {
            imgwidth=KONOTOR_IMAGE_MAXWIDTH;
            height=[[currentMessage picThumbHeight] floatValue]*(imgwidth/[[currentMessage picThumbWidth] floatValue]);
        }
        
        float txtheight=0.0;
        
        
        currentMessage.picCaption=(currentMessage.isMarketingMessage?currentMessage.text:@"");
        
        if((currentMessage.picCaption)&&(![currentMessage.picCaption isEqualToString:@""])){
            NSString *htmlString = currentMessage.picCaption;
            NSDictionary* fontDict=[[NSDictionary alloc] initWithObjectsAndKeys:KONOTOR_MESSAGETEXT_FONT,NSFontAttributeName,nil];
            NSMutableAttributedString* attributedString=nil;
            attributedString=[[NSMutableAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];

            [attributedString addAttributes:fontDict range:NSMakeRange(0, [attributedString length])];
            
            txtheight=[attributedString boundingRectWithSize:CGSizeMake(width, 1000) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size.height;
            
        }
        cellHeight= 16+txtheight+height+(KONOTOR_MESSAGE_BACKGROUND_BOTTOM_PADDING_ME?KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING:0)+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+KONOTOR_VERTICAL_PADDING*2+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?0:KONOTOR_VERTICAL_PADDING))+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));
        
        
    }
    else if([currentMessage messageType].integerValue==KonotorMessageTypeHTML){
        UITextView* txtView=[[UITextView alloc] init];
        [txtView setFont:KONOTOR_MESSAGETEXT_FONT];
        NSString *htmlString = currentMessage.text;
        NSDictionary* fontDict=[[NSDictionary alloc] initWithObjectsAndKeys:txtView.font,NSFontAttributeName,nil];
        NSMutableAttributedString* attributedString=nil;
        attributedString=[[NSMutableAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType } documentAttributes:nil error:nil];

        [attributedString addAttributes:fontDict range:NSMakeRange(0, [attributedString length])];
        
        if([txtView respondsToSelector:@selector(setAttributedText:)])
            txtView.attributedText = attributedString;
        else
            [txtView setText:[attributedString string]];
        
        float height=0.0;
        height=[txtView sizeThatFits:CGSizeMake(width, 1000)].height-16;
        if(KONOTOR_SHOWPROFILEIMAGE){
            cellHeight= MAX(height+extraHeight,minimumHeight);
        }
        else{
            cellHeight= height+extraHeight;
        }
    }
    else
    {
        NSString* msgTxt=nil;
        if(([currentMessage text]!=nil)&&(![[currentMessage text] isEqualToString:@""]))
            msgTxt=[currentMessage text];
        else
            msgTxt=@"Message cannot be displayed. Please upgrade your app to view this message.";
        float height=[self getTextViewHeightForMaxWidth:width text:msgTxt withFont:KONOTOR_MESSAGETEXT_FONT];
        
        if(KONOTOR_SHOWPROFILEIMAGE)
            return MAX(height+extraHeight,minimumHeight);
        else
            return height+extraHeight;
    }
    cellHeight+=(currentMessage.actionURL!=nil)?(KONOTOR_ACTIONBUTTON_HEIGHT+5*KONOTOR_VERTICAL_PADDING):0;
    [messageHeights setValue:[NSNumber numberWithFloat:cellHeight]  forKey:currentMessage.messageId];
    return cellHeight;
}

/* get size of TextView with Text*/

-(CGSize)getSizeOfTextViewWidth:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font
{
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:font];
    [txtView setText:text];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width, 1000)];
    return size;
}

-(CGFloat)getTextViewLineHeight:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font
{
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:font];
    [txtView setText:text];
    return txtView.font.lineHeight;
}

-(CGFloat)getTextViewHeightForMaxWidth:(CGFloat)width text:(NSString *)text withFont:(UIFont *)font
{
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:font];
    [txtView setText:text];
    CGSize size=[txtView sizeThatFits:CGSizeMake(width, 1000)];
    return size.height-16;
}

#pragma mark - Table view delegate


- (void) refreshView
{
    [self.tableView reloadData];
    [Konotor markAllMessagesAsRead];
    
    int lastSpot=loading?numberOfMessagesShown:(numberOfMessagesShown-1);
    
    if([KonotorUIParameters sharedInstance].notificationCenterMode) lastSpot=0;
    
    if(lastSpot<0) return;
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:lastSpot inSection:0];
    @try {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    @catch (NSException *exception ) {
        indexPath=[NSIndexPath indexPathForRow:(indexPath.row-1) inSection:0];
        @try{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        @catch(NSException *exception){
            
        }
        
    }
    messageCount_prev=(int)[[Konotor getAllMessagesForDefaultConversation] count];
}

- (void) refreshView:(id) spot
{
    [self.tableView reloadData];
    [Konotor markAllMessagesAsRead];
    
    notificationCenterMode=[KonotorUIParameters sharedInstance].notificationCenterMode;
    
    int lastSpot=loading?(numberOfMessagesShown-((NSNumber*)spot).intValue):((numberOfMessagesShown-((NSNumber*)spot).intValue));
    if(notificationCenterMode) lastSpot=numberOfMessagesShown-lastSpot-1;
    if(lastSpot<0) return;
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:lastSpot inSection:0];
    @try {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:(notificationCenterMode?UITableViewScrollPositionBottom:UITableViewScrollPositionTop) animated:NO];
    }
    @catch (NSException *exception ) {
        indexPath=[NSIndexPath indexPathForRow:(indexPath.row-1) inSection:0];
        @try{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:(notificationCenterMode?UITableViewScrollPositionBottom:UITableViewScrollPositionTop) animated:NO];
        }
        @catch(NSException *exception){
            
        }
        
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    showingAlert=NO;
}

#pragma mark Konotor delegates

- (void) didFinishPlaying:(NSString *)messageID
{
    for(UITableViewCell* cell in [self.tableView visibleCells]){
        KonotorMediaUIButton* button=(KonotorMediaUIButton*)[cell viewWithTag:KONOTOR_PLAYBUTTON_TAG];
        if([button.messageID isEqualToString:messageID])
        {
            [button stopAnimating];
        }
    }
    
}

- (void) didStartPlaying:(NSString *)messageID
{
    for(UITableViewCell* cell in [self.tableView visibleCells]){
        KonotorMediaUIButton* button=(KonotorMediaUIButton*)[cell viewWithTag:KONOTOR_PLAYBUTTON_TAG];
        if([button.messageID isEqualToString:messageID])
        {
            [button startAnimating];
        }
    }
}

- (void) didFinishDownloadingMessages{
    if((loading)||([[Konotor getAllMessagesForDefaultConversation] count]>messageCount_prev)){
        loading=NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Konotor_FinishedMessagePull" object:nil];
        [self refreshView];
    }
    
}

- (void) didFinishUploading:(NSString *)messageID
{
    for(UITableViewCell* cell in [self.tableView visibleCells]){
        if([messageID hash]==cell.tag)
        {
            UIImageView* uploadStatus=(UIImageView*)[cell.contentView viewWithTag:KONOTOR_UPLOADSTATUS_TAG];
            [uploadStatus setImage:sentImage];
            for(int i=messageCount-1;i>=0;i--){
                if([(NSString*)[(KonotorMessageData*)[messages objectAtIndex:i] messageId] isEqualToString:messageID])
                {
                    [(KonotorMessageData*)[messages objectAtIndex:i] setUploadStatus:([NSNumber numberWithInt:MessageUploaded])];
                    break;
                }
            }
        }
    }
}

- (void) didEncounterErrorWhileUploading:(NSString *)messageID{
    if(!showingAlert){
        UIAlertView* konotorAlert=[[UIAlertView alloc] initWithTitle:@"Message not sent" message:@"We could not send your message(s) at this time. Check your internet or try later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [konotorAlert show];
        showingAlert=YES;
    }
}

- (void) didEncounterErrorWhileDownloading:(NSString *)messageID{
    //Show Toast
}


-(void) didEncounterErrorWhileDownloadingConversations{
    if((loading)||([[Konotor getAllMessagesForDefaultConversation] count]>messageCount_prev)){
        loading=NO;
        [self refreshView];
    }
}


-(BOOL) handleRemoteNotification:(NSDictionary*)userInfo withShowScreen:(BOOL) showScreen{
    NSString* marketingId=((NSString*)[userInfo objectForKey:@"kon_message_marketingid"]);
    NSString* url=[userInfo valueForKey:@"kon_m_url"];
    if(showScreen&&marketingId&&([marketingId longLongValue]!=0))
        [Konotor MarkMarketingMessageAsClicked:[NSNumber numberWithLongLong:[marketingId longLongValue]]];
    
    if(showScreen&&(url!=nil)){
        @try{
            NSURL *clickUrl=[NSURL URLWithString:url];
            if([[UIApplication sharedApplication] canOpenURL:clickUrl]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:clickUrl];
                });
            }
        }
        @catch(NSException *e){
            NSLog(@"%@",e);
        }
        
        [Konotor DownloadAllMessages];
        
        return YES;
    }
    else{
        
        if(!([(NSString*)[userInfo valueForKey:@"source"] isEqualToString:@"konotor"])){
            return NO;
        }
        
        if(![[KonotorUIParameters sharedInstance] dontShowLoadingAnimation])
            loading=YES;
        else
            loading=NO;
        [Konotor DownloadAllMessages];
        
        [self.tableView reloadData];
        
        return YES;

    }
    return YES;
    
}


- (void) playMedia:(id) sender
{
    KonotorMediaUIButton* playButton=(KonotorMediaUIButton*) sender;
    if(playButton.buttonState==KonotorMediaUIButtonStatePlaying){
        [Konotor StopPlayback];
        [self didFinishPlaying:playButton.messageID];
    }
    else{
        [Konotor playMessageWithMessageID:playButton.messageID];
    }
}


-(void) openActionUrl:(id) sender
{
    KonotorActionButton* button=(KonotorActionButton*)sender;
    if(button.actionUrl!=nil){
        @try{
            NSURL * actionUrl=[NSURL URLWithString:button.actionUrl];
            if([[UIApplication sharedApplication] canOpenURL:actionUrl]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:actionUrl];
                });
            }
        }
        @catch(NSException* e){
            NSLog(@"%@",e);
        }
    }
}

////

- (void) setStyleForActionButton:(KonotorActionButton*)actionButton
{
    float padding = KONOTOR_BUTTON_HORIZONTAL_PADDING*2;
    
    [actionButton setFrame:(CGRectMake(0, 0, 40, KONOTOR_ACTIONBUTTON_HEIGHT))];
    [actionButton setContentEdgeInsets:UIEdgeInsetsMake(padding/8, padding/2, padding/8, padding/2)];
    actionButton.layer.cornerRadius=10.0;
    [actionButton setBackgroundColor:[[KonotorUIParameters sharedInstance] actionButtonColor]];
       
    [actionButton setTitleColor:[[KonotorUIParameters sharedInstance] actionButtonLabelColor] forState:UIControlStateNormal];
    [actionButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    

}

- (void) adjustPositionForTimeView:(UITextView*) timeField textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)KONOTOR_SHOW_SENDERNAME messageType:(enum KonotorMessageType) messageType
{
    
    float messageContentViewWidth=messageContentFrame.size.width;

    float messageTextBoxX=messageTextFrame.origin.x;
    float messageTextBoxY=messageTextFrame.origin.y;
    float messageTextBoxWidth=messageTextFrame.size.width;

    CGSize txtSize=[timeField sizeThatFits:CGSizeMake(messageContentViewWidth, 20)];

    switch (messageType) {
            
     
        case KonotorMessageTypePictureV2:
            
        case KonotorMessageTypePicture:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING), messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT+4)];
            if([timeField respondsToSelector:@selector(textContainerInset)])
                timeField.textContainerInset=UIEdgeInsetsMake(4, 0, 0, 0);
            else
                [timeField setContentOffset:CGPointMake(0, 4)];

            break;
        }
            
        
        case KonotorMessageTypeAudio:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+(KONOTOR_SHOW_SENDERNAME?(KONOTOR_USERNAMEFIELD_HEIGHT+KONOTOR_AUDIOMESSAGE_HEIGHT):KONOTOR_VERTICAL_PADDING), messageTextBoxWidth, KONOTOR_TIMEFIELD_HEIGHT)];
            
            if((KONOTOR_SHOW_TIMESTAMP)&&(KONOTOR_SHOW_SENDERNAME))
            {
                
                if([timeField respondsToSelector:@selector(textContainerInset)])
                    [timeField setTextContainerInset:UIEdgeInsetsMake(0, 0, 0, 0)];
                else
                    [timeField setContentOffset:CGPointMake(0, 10)];
            }
            else{
                
                if([timeField respondsToSelector:@selector(textContainerInset)])
                    [timeField setTextContainerInset:UIEdgeInsetsMake(4, 0, 0, 0)];
                else
                    [timeField setContentOffset:CGPointMake(0, 4)];
            }

        }
        
        case KonotorMessageTypeHTML:

        case KonotorMessageTypeText:
      
            
        default:
        {
            [timeField setFrame:CGRectMake(messageTextBoxX, messageTextBoxY+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING), txtSize.width + 16, KONOTOR_TIMEFIELD_HEIGHT+4)];
            if([timeField respondsToSelector:@selector(textContainerInset)])
                timeField.textContainerInset=UIEdgeInsetsMake(4, 0, 0, 0);
            else
                [timeField setContentOffset:CGPointMake(0, 4)];

            break;
        }
    }

}



- (void) adjustHeightForMessageBubble:(UIImageView*)messageBackground textView:(UITextView*)messageText actionUrl:(NSString*)actionUrl height:(float)msgHeight textBoxRect:(CGRect)messageTextFrame contentViewRect:(CGRect)messageContentFrame showsSenderName:(BOOL)KONOTOR_SHOW_SENDERNAME sender:(BOOL)isSenderOther textFrameAdjustY:(float)textViewY contentFrameAdjustY:(float)contentViewY
{
    
    CGRect txtMsgFrame=messageText.frame;
    
    float messageTextBoxX=messageTextFrame.origin.x;
    float messageTextBoxY=messageTextFrame.origin.y;
    float messageTextBoxWidth=messageTextFrame.size.width;
    
    float messageContentViewX=messageContentFrame.origin.x;
    float messageContentViewY=messageContentFrame.origin.y;
    float messageContentViewWidth=messageContentFrame.size.width;
    
    txtMsgFrame.origin.x=messageTextBoxX;
    txtMsgFrame.origin.y=messageTextBoxY+textViewY;

    txtMsgFrame.size.width=messageTextBoxWidth;
    
    txtMsgFrame.size.height=msgHeight;
    
    messageText.frame=txtMsgFrame;
    
    txtMsgFrame.size.height=msgHeight+contentViewY;
    txtMsgFrame.size.height=msgHeight+(KONOTOR_SHOW_SENDERNAME?KONOTOR_USERNAMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_TIMESTAMP?KONOTOR_TIMEFIELD_HEIGHT:KONOTOR_VERTICAL_PADDING)+(KONOTOR_SHOW_SENDERNAME?0:(KONOTOR_SHOW_TIMESTAMP?KONOTOR_VERTICAL_PADDING:0));

    txtMsgFrame.size.height+=(actionUrl!=nil)?(KONOTOR_ACTIONBUTTON_HEIGHT+5*KONOTOR_VERTICAL_PADDING):0;
    txtMsgFrame.origin.y=messageText.frame.origin.y-KONOTOR_MESSAGE_BACKGROUND_IMAGE_TOP_PADDING;
    txtMsgFrame.origin.y=messageContentViewY;
    txtMsgFrame.origin.x=messageContentViewX;
    txtMsgFrame.size.width=messageContentViewWidth;
    messageBackground.frame=txtMsgFrame;
    
}

- (void) setupActionButtonWithUrlString:(NSString*)actionUrl label:(NSString*)actionLabel actionButton:(KonotorActionButton*)actionButton frame:(CGRect)messageFrame
{
    float messageFrameWidth=messageFrame.size.width;
    float messageFrameHeight=messageFrame.size.height;
    float messageOriginX=messageFrame.origin.x;
    float messageOriginY=messageFrame.origin.y;
    float horizontalPadding=KONOTOR_HORIZONTAL_PADDING*3;
    float verticalPadding=KONOTOR_VERTICAL_PADDING;
    float percentWidth=0.5;
    float padding = KONOTOR_BUTTON_HORIZONTAL_PADDING*2;
    float maxButtonWidth =messageFrameWidth-horizontalPadding*2;
    
    UIFont *actionLabelFont=([KonotorUIParameters sharedInstance].customFontName?[UIFont fontWithName:[KonotorUIParameters sharedInstance].customFontName size:16.0]:KONOTOR_BUTTON_FONT);
    
    
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:actionLabelFont];
    [txtView setText:actionLabel];
    CGSize labelSize=[txtView sizeThatFits:CGSizeMake(messageFrameWidth, KONOTOR_ACTIONBUTTON_HEIGHT)];
    
    float labelWidth=padding + 20+labelSize.width;
    float buttonWidth=MAX(MIN(labelWidth, maxButtonWidth), maxButtonWidth*percentWidth);
    
    float buttonXCenterAlign=messageOriginX-horizontalPadding/3.0+(messageFrameWidth-buttonWidth)/2;
    
    if(actionUrl!=nil){
        actionButton.actionUrl=actionUrl;
        [actionButton setFrame:CGRectMake(buttonXCenterAlign,
                                          messageOriginY+messageFrameHeight-verticalPadding,
                                          buttonWidth,
                                          KONOTOR_ACTIONBUTTON_HEIGHT)];
        [actionButton setHidden:NO];
        if([actionLabel isEqualToString:@""]||(actionLabel==nil))
            actionLabel=KONOTOR_BUTTON_DEFAULTACTIONLABEL;
        [actionButton setAttributedTitle:
         [[NSAttributedString alloc] initWithString:actionLabel attributes:[NSDictionary dictionaryWithObjectsAndKeys:actionLabelFont,NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName,nil]] forState:UIControlStateNormal];
    }
    else{
        [actionButton setHidden:YES];
    }

}


#pragma mark Keyboard Notifications

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    float adjustHeight=[KonotorFeedbackScreen sharedInstance].conversationViewController.showingInTab?([KonotorFeedbackScreen sharedInstance].conversationViewController.tabBarHeight):0;
    keyboardSize.height-=adjustHeight;
    
    float verticalInsetAdjustment=10-([Konotor isPoweredByHidden]?14:0);
    
    [self adjustTableViewWithInset:(keyboardSize.height-verticalInsetAdjustment)];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets=UIEdgeInsetsMake(contentInsets.top, contentInsets.left,6 , contentInsets.right);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    int lastSpot=loading?numberOfMessagesShown:(numberOfMessagesShown-1);
    
    if([KonotorUIParameters sharedInstance].notificationCenterMode) lastSpot=0;
    
    if(lastSpot<0) return;
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:lastSpot inSection:0];
    @try {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    @catch (NSException *exception ) {
        indexPath=[NSIndexPath indexPathForRow:(indexPath.row-1) inSection:0];
        @try{
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        @catch(NSException *exception){
            
        }
        
    }
}

@end
