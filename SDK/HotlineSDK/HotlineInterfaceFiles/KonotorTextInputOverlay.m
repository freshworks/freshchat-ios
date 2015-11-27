//
//  KonotorTextInputOverlay.m
//  KonotorSampleApp
//
//  Created by Srikrishnan Ganesan on 11/07/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorTextInputOverlay.h"
#import "KonotorFeedbackScreen.h"

static KonotorTextInputOverlay* konotorTextInputBox=nil;
static BOOL promptForPush=YES;
static BOOL firstWordOnLine=YES;

@implementation KonotorTextInputOverlay

@synthesize window,textInputBox,transparentView,originalTextInputRect,sourceViewController;

+(KonotorTextInputOverlay*) sharedInstance
{
    if(konotorTextInputBox==nil)
        konotorTextInputBox=[[KonotorTextInputOverlay alloc] init];
    return konotorTextInputBox;
}

+(BOOL) showInputForViewController:(UIViewController *)viewController
{
    BOOL showingInput=[KonotorTextInputOverlay showInputForView:viewController.view];
    if(konotorTextInputBox!=nil)
        konotorTextInputBox.sourceViewController=viewController;
    return showingInput;
}

+(BOOL) showInputForView:(UIView *)view
{
    if(konotorTextInputBox!=nil)
        return NO;
    konotorTextInputBox=[KonotorTextInputOverlay sharedInstance];
    konotorTextInputBox.window=view;
    [konotorTextInputBox showInputView];
    return YES;
}

- (void) showInputView
{
    
    textInputBox=[[UIView alloc] initWithFrame:CGRectMake(0, window.frame.size.height-44,  window.frame.size.width, 44)];
    [textInputBox setBackgroundColor:[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0]];
    textInputBox.layer.shadowColor=[[UIColor lightGrayColor] CGColor];
    textInputBox.layer.shadowOffset=CGSizeMake(1.0, 1.0);
    textInputBox.layer.shadowRadius=1.0;
    
    KonotorUITextView* input;

    if([KonotorUtility KonotorIsInterfaceLandscape:(((KonotorFeedbackScreen*)[KonotorFeedbackScreen sharedInstance]).conversationViewController)])
        input=[[KonotorUITextView alloc] initWithFrame:CGRectMake(5+35+10, 6, window.frame.size.height-30-10-50-35+10+15-10, 44-6-6)];
    else
        input=[[KonotorUITextView alloc] initWithFrame:CGRectMake(5+35+10, 6, window.frame.size.width-30-10-50-35+10+15-10, 44-6-6)];

    input.layer.borderWidth=1.0;
    input.layer.borderColor=[[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0] CGColor];
    input.layer.cornerRadius=5.0;
    
    UIFont* inputTextFont =[[KonotorUIParameters sharedInstance] inputTextFont];
    if(inputTextFont==nil)
        inputTextFont=[UIFont systemFontOfSize:14.0];
    [input setFont:inputTextFont];
    [input setBackgroundColor:[UIColor whiteColor]];
    input.tag=KONOTOR_TEXTINPUT_TEXTVIEW_TAG;
    [input setReturnKeyType:UIReturnKeyDefault];
    input.scrollEnabled=NO;
    
    input.delegate=self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shiftInput:) name:UIKeyboardWillShowNotification object:nil];
    
    [textInputBox addSubview:input];
    [window addSubview:textInputBox];
    
    
    UIButton *cancelButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:CGRectMake(5, 7, 30, 30)];
    [cancelButton setTag:KONOTOR_TEXTINPUT_CANCELBUTTON_TAG];

    [cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    if([[KonotorUIParameters sharedInstance] imageInputEnabled]){
        [cancelButton setImage:[UIImage imageNamed:@"konotor_cam"] forState:UIControlStateNormal];
        [cancelButton setAlpha:0.4];
    }
    else{
        [cancelButton setImage:[UIImage imageNamed:@"konotor_cancel"] forState:UIControlStateNormal];
        [cancelButton setAlpha:1.0];
    }
    
    [cancelButton setFrame:CGRectMake(4, 2, 40, 40)];
    if([[KonotorUIParameters sharedInstance] imageInputEnabled]){
        [cancelButton addTarget:self.sourceViewController action:@selector(showImageInput) forControlEvents:UIControlEventTouchUpInside];
    }
    else{
        [input setFrame:CGRectMake(input.frame.origin.x-10-35, input.frame.origin.y, input.frame.size.width+10+35, input.frame.size.height)];
        [cancelButton setHidden:YES];
        [cancelButton addTarget:[KonotorTextInputOverlay class] action:@selector(dismissInput) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [textInputBox addSubview:cancelButton];

    
    UIButton *sendButton=[UIButton buttonWithType:UIButtonTypeCustom];
    
    if([KonotorUtility KonotorIsInterfaceLandscape:(((KonotorFeedbackScreen*)[KonotorFeedbackScreen sharedInstance]).conversationViewController)])
        [sendButton setFrame:CGRectMake(5+35+window.frame.size.height-30-10-50-35+5+10+15, 5, 50, 34)];
    else
        [sendButton setFrame:CGRectMake(5+35+window.frame.size.width-30-10-50-35+5+10+15, 5, 50, 34)];

    
    [sendButton setTitleColor:(([[KonotorUIParameters sharedInstance] sendButtonColor]==nil)?KONOTOR_UIBUTTON_COLOR:[[KonotorUIParameters sharedInstance] sendButtonColor]) forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    sendButton.enabled=NO;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    
    NSString* customFontName=[[KonotorUIParameters sharedInstance] customFontName];
    if(customFontName){
        [sendButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Send" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:([KonotorUIParameters sharedInstance].customFontName) size:15.0],NSFontAttributeName,nil]] forState:UIControlStateNormal];
    }
    [sendButton setTag:KONOTOR_TEXTINPUT_SENDBUTTON_TAG];

    [sendButton addTarget:self action:@selector(sendText) forControlEvents:UIControlEventTouchUpInside];
    [textInputBox addSubview:sendButton];
      
    [input performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0];

    
}


- (void) shiftInput:(NSNotification*)note{
    CGRect newFrame;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&newFrame];
    
    KonotorFeedbackScreenViewController* conversationView=[KonotorFeedbackScreen sharedInstance].conversationViewController;
    BOOL tabBarDisplay=conversationView.showingInTab;
    
    float adjustHeight=tabBarDisplay?([KonotorFeedbackScreen sharedInstance].conversationViewController.tabBarHeight):0;
    
    
    newFrame.size.height=(newFrame.size.height-adjustHeight);
    float y=([KonotorUtility KonotorIsInterfaceLandscape:(((KonotorFeedbackScreen*)[KonotorFeedbackScreen sharedInstance]).conversationViewController)])?(window.frame.size.width-newFrame.size.width):(window.frame.size.height-newFrame.size.height);
    float width=([KonotorUtility KonotorIsInterfaceLandscape:(((KonotorFeedbackScreen*)[KonotorFeedbackScreen sharedInstance]).conversationViewController)])?newFrame.size.height:newFrame.size.width;
    
    KonotorUITextView* input=(KonotorUITextView*)[self.textInputBox viewWithTag:KONOTOR_TEXTINPUT_TEXTVIEW_TAG];
    
    UIButton* sendButton = (UIButton*)[self.textInputBox viewWithTag:KONOTOR_TEXTINPUT_SENDBUTTON_TAG];
    
    if([KonotorUtility KonotorIsInterfaceLandscape:(((KonotorFeedbackScreen*)[KonotorFeedbackScreen sharedInstance]).conversationViewController)])
        [sendButton setFrame:CGRectMake(5+35+self.window.frame.size.height-30-10-50-35+5+10+15, 5, 50, 34)];
    else
        [sendButton setFrame:CGRectMake(5+35+self.window.frame.size.width-30-10-50-35+5+10+15, 5, 50, 34)];
    
    float txtWidth;
    if([KonotorUtility KonotorIsInterfaceLandscape:(((KonotorFeedbackScreen*)[KonotorFeedbackScreen sharedInstance]).conversationViewController.messagesView)])
        txtWidth=self.window.frame.size.height-30-10-50-35+10+15;
    else
        txtWidth=self.window.frame.size.width-30-10-50-35+10+15;
    
    if(![[KonotorUIParameters sharedInstance] imageInputEnabled]){
        txtWidth+=35+10;
    }
    CGSize txtSize;
    
    float cameraAdjustment=10.0;
    
    txtSize = [input sizeThatFits:CGSizeMake(txtWidth-cameraAdjustment, 140)];
    
    if(txtSize.height>100)
        txtSize.height=100;
    
    float totalTime=0.25;
    float delay=(adjustHeight/(newFrame.size.height+adjustHeight))*totalTime/2;
    
    [UIView animateWithDuration:(totalTime-delay) delay:delay options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{
        [textInputBox setFrame:CGRectMake(0, y-txtSize.height-10, width, txtSize.height+10)];
    } completion:^(BOOL finished) {
        
    }];
    float inputX=5+(([[KonotorUIParameters sharedInstance] imageInputEnabled])?(35+cameraAdjustment):0);
    
    input.frame=CGRectMake(inputX,5,txtWidth-cameraAdjustment,txtSize.height);

    
}

- (BOOL) shouldAutorotate{
    return YES;
}

- (void) sendText
{
    KonotorUITextView* textInputView=(KonotorUITextView*)[textInputBox viewWithTag:KONOTOR_TEXTINPUT_TEXTVIEW_TAG];
    NSString* toSend=[((KonotorUITextView*)[textInputBox viewWithTag:KONOTOR_TEXTINPUT_TEXTVIEW_TAG]).text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if((![KonotorUIParameters sharedInstance].allowSendingEmptyMessage)&&[toSend isEqualToString:@""]){
        UIAlertView* alertNilString=[[UIAlertView alloc] initWithTitle:@"Empty Message" message:@"You cannot send an empty message. Please type a message to send." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertNilString show];
    }
    else{
        [Konotor uploadTextFeedback:toSend onConversation:nil];
        
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

        
        if (!notificationEnabled) {
            if(promptForPush){
                UIAlertView* pushDisabledAlert=[[UIAlertView alloc] initWithTitle:@"Modify Push Setting" message:@"To be notified of responses even when out of this chat, enable push notifications for this app via the Settings->Notification Center" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [pushDisabledAlert show];
                promptForPush=NO;
            }
        }
        [textInputView setText:@""];
        [self textViewDidChange:textInputView];

    }
    
    [KonotorFeedbackScreen performSelector:@selector(refreshMessages) withObject:nil afterDelay:0.0];
}

+ (void) dismissInput
{
    [konotorTextInputBox.textInputBox resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:konotorTextInputBox];
    [konotorTextInputBox.transparentView removeFromSuperview];
    [konotorTextInputBox.textInputBox removeFromSuperview];
    konotorTextInputBox.textInputBox=nil;
    konotorTextInputBox.transparentView=nil;
    ((KonotorFeedbackScreenViewController*)konotorTextInputBox.sourceViewController).footerView.hidden=NO;
    if(konotorTextInputBox) {
        konotorTextInputBox=nil;
        [KonotorFeedbackScreen refreshMessages];
    }
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    [KonotorTextInputOverlay performSelector:@selector(dismissInput) withObject:nil afterDelay:0.0];
}

- (void) textViewDidChange:(UITextView *)textView
{
    KonotorUITextView* textBox=(KonotorUITextView*)textView;
    NSString *txt=textBox.text;
    UIButton* sendButton = (UIButton*)[self.textInputBox viewWithTag:KONOTOR_TEXTINPUT_SENDBUTTON_TAG];
    UIButton* cancelButton = (UIButton*)[self.textInputBox viewWithTag:KONOTOR_TEXTINPUT_CANCELBUTTON_TAG];

    if((txt==nil)||([txt isEqualToString:@""])){
        sendButton.enabled=NO;
        txt=@"1";
    }
    else
        sendButton.enabled=YES;
    
    CGSize txtSize = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, 140)];
    
    if((txtSize.height)>=67){
        txtSize.height=67;
        if(firstWordOnLine==YES)
            firstWordOnLine=NO;
        else
            textView.scrollEnabled=YES;
    }
    else{
        textView.scrollEnabled=NO;
    }

    float adjustment=txtSize.height-textBox.frame.size.height;
    
    if(adjustment!=0){
        textInputBox.frame=CGRectMake(textInputBox.frame.origin.x, textInputBox.frame.origin.y-(txtSize.height-textBox.frame.size.height), textInputBox.frame.size.width, textInputBox.frame.size.height+(txtSize.height-textBox.frame.size.height));
        sendButton.frame=CGRectMake(sendButton.frame.origin.x, sendButton.frame.origin.y+txtSize.height-textBox.frame.size.height, sendButton.frame.size.width, sendButton.frame.size.height);
        cancelButton.frame=CGRectMake(cancelButton.frame.origin.x, cancelButton.frame.origin.y+txtSize.height-textBox.frame.size.height, cancelButton.frame.size.width, cancelButton.frame.size.height);
        [[KonotorFeedbackScreen sharedInstance].conversationViewController.messagesView adjustTableViewWithInset:([KonotorFeedbackScreen sharedInstance].conversationViewController.messagesView.tableView.contentInset.bottom+adjustment)];
    }
    
    textBox.frame=CGRectMake(textView.frame.origin.x,textView.frame.origin.y,textView.frame.size.width,txtSize.height);
    
    
    txt=nil;
    
}



@end
