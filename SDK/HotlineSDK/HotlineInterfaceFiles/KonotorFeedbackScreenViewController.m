//
//  KonotorFeedbackScreenViewController.m
//  KonotorSampleApp
//
//  Created by Srikrishnan Ganesan on 10/07/13.
//  Copyright (c) 2013 Demach. All rights reserved.
//

#import "KonotorFeedbackScreenViewController.h"

static NSString *microphoneAccessDenied=@"KonotorMicrophoneAccessDenied";

static KonotorUIParameters* konotorUIParameters=nil;

@interface KonotorFeedbackScreenViewController ()

@end

@implementation KonotorFeedbackScreenViewController

@synthesize textInputBox,transparentView,messagesView;
@synthesize headerContainerView,headerView,closeButton,footerView,messageTableView,voiceInput,input,picInput,poweredByLabel;
@synthesize showingInTab,tabBarHeight;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self.view setBackgroundColor:KONOTOR_MESSAGELAYOUT_BACKGROUND_COLOR];
    }
    return self;
}

- (BOOL) shouldAutorotate{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    //Modified for removing table view separators
    self.messageTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    float topPaddingIOS7=20;
    
    if(KONOTOR_PUSH_ON_NAVIGATIONCONTROLLER){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if([konotorUIParameters headerViewColor])
        [headerView setBackgroundColor:[konotorUIParameters headerViewColor]];

    if([konotorUIParameters titleText]){
        [headerView setText:[konotorUIParameters titleText]];
        if([konotorUIParameters titleTextFont])
            [headerView setFont:[konotorUIParameters titleTextFont]];
        [headerView setTextColor:[UIColor blackColor]];
        [headerView setTextAlignment:NSTextAlignmentCenter];
    }
    if([konotorUIParameters titleTextColor]){
        [headerView setTextColor:[konotorUIParameters titleTextColor]];
    }
    
    [self setUpDoneButton];
    
    if(!KONOTOR_PUSH_ON_NAVIGATIONCONTROLLER){
        CGRect headerRect=headerContainerView.frame;
        headerRect.origin.y=headerRect.origin.y+topPaddingIOS7;
        [headerContainerView setFrame:headerRect];
    }
    
    
    if([konotorUIParameters closeButtonImage])
        [closeButton setImage:[konotorUIParameters closeButtonImage] forState:UIControlStateNormal];
    [closeButton addTarget:[KonotorFeedbackScreen class] action:@selector(dismissScreen) forControlEvents:UIControlEventTouchUpInside];
    
    footerView.layer.shadowOffset=CGSizeMake(1,1);
    footerView.layer.shadowColor=[[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] CGColor];
    footerView.layer.shadowRadius=1.0;
    footerView.layer.shadowOpacity=1.0;
    
    UITapGestureRecognizer* tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTextInput)];
    UILongPressGestureRecognizer* longPress=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showTextInput)];
    [input addGestureRecognizer:tap];
    [input addGestureRecognizer:longPress];
    if([input respondsToSelector:@selector(setSelectable:)])
        [input setSelectable:NO];
    input.layer.borderColor=[[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0] CGColor];
    input.layer.borderWidth=1.0;
    input.layer.cornerRadius=5.0;
    
    if(konotorUIParameters.inputHintText){
        [input setText:konotorUIParameters.inputHintText];
    }
    
    [voiceInput setFrame:CGRectMake(footerView.frame.size.width-5-40, 2, 40, 40)];

    if([[KonotorUIParameters sharedInstance] voiceInputEnabled]){
    
        [voiceInput setFrame:CGRectMake(footerView.frame.size.width-5-40, 2, 40, 40)];
        voiceInput.layer.cornerRadius=20.0;
        [voiceInput setImage:[UIImage imageNamed:@"konotor_mic.png"] forState:UIControlStateNormal];
        
        [voiceInput addTarget:self action:@selector(showVoiceInput) forControlEvents:UIControlEventTouchDown];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToTextOnlyInput) name:microphoneAccessDenied object:nil];
    }
    else{
        [voiceInput setTitle:@"Send" forState:UIControlStateNormal];
        if([[KonotorUIParameters sharedInstance] customFontName]){
            [voiceInput setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Send" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:[[KonotorUIParameters sharedInstance] customFontName] size:14.0],NSFontAttributeName, nil]] forState:UIControlStateNormal];
        }
        [voiceInput setImage:nil forState:UIControlStateNormal];
        [voiceInput setAlpha:1.0];
        [voiceInput setBackgroundColor:[UIColor clearColor]];
        [voiceInput setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [voiceInput setFrame:CGRectMake(voiceInput.frame.origin.x-10, voiceInput.frame.origin.y, voiceInput.frame.size.width+10, voiceInput.frame.size.height)];
        [input setFrame:CGRectMake(input.frame.origin.x, input.frame.origin.y, input.frame.size.width-12, input.frame.size.height)];
        [voiceInput setUserInteractionEnabled:NO];
    }
    
    if([[KonotorUIParameters sharedInstance] imageInputEnabled])
        [picInput addTarget:self action:@selector(showImageInput) forControlEvents:UIControlEventTouchDown];
    else{
        [picInput setHidden:YES];
        [input setFrame:CGRectMake(input.frame.origin.x-40, input.frame.origin.y, input.frame.size.width+40, input.frame.size.height)];
    }
    if([Konotor isPoweredByHidden])
    {
        [messageTableView setFrame:CGRectMake(messageTableView.frame.origin.x, messageTableView.frame.origin.y, messageTableView.frame.size.width, messageTableView.frame.size.height+14)];
        [footerView setFrame:CGRectMake(footerView.frame.origin.x, footerView.frame.origin.y+14, footerView.frame.size.width, footerView.frame.size.height)];
        [poweredByLabel setHidden:YES];
    }
    
    if((!konotorUIParameters.showInputOptions)&&(!footerView.hidden)){
        [messageTableView setFrame:CGRectMake(messageTableView.frame.origin.x, messageTableView.frame.origin.y, messageTableView.frame.size.width, messageTableView.frame.size.height+footerView.frame.size.height)];
        [footerView setHidden:YES];
    }
    
    messagesView=[[KonotorConversationViewController alloc] init];
    messagesView.view=messageTableView;
    [messageTableView setDelegate:messagesView];
    [messageTableView setDataSource:messagesView];
    
    UITapGestureRecognizer* tapGesture=[[UITapGestureRecognizer alloc] initWithTarget:[KonotorTextInputOverlay class] action:@selector(dismissInput)];
    [messageTableView addGestureRecognizer:tapGesture];
    
    
    if(!KONOTOR_PUSH_ON_NAVIGATIONCONTROLLER){
        CGRect messageRect=messagesView.view.frame;
        messageRect.origin.y=messageRect.origin.y+topPaddingIOS7;
        messageRect.size.height=messageRect.size.height-topPaddingIOS7;
        [messagesView.view setFrame:messageRect];
    }

    [Konotor setDelegate:messagesView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showVoiceInputOverlay) name:@"KonotorRecordingStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showRecordingFailed) name:@"KonotorRecordingFailed" object:nil];

    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];;

}

- (void) setUpDoneButton
{
    if([konotorUIParameters closeButtonImage]==nil){
        if(konotorUIParameters.doneButtonText){
            [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:konotorUIParameters.doneButtonText style:UIBarButtonItemStyleDone target:[KonotorFeedbackScreen class] action:@selector(dismissScreen)]];
        }
        else{
            [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleDone target:[KonotorFeedbackScreen class] action:@selector(dismissScreen)]];
        }
        if(konotorUIParameters.doneButtonFont||konotorUIParameters.doneButtonColor){
            NSMutableDictionary* fontAttributes=[[NSMutableDictionary alloc] init];
            if(konotorUIParameters.doneButtonColor){
                [fontAttributes setObject:konotorUIParameters.doneButtonColor forKey:NSForegroundColorAttributeName];
            }
            if(konotorUIParameters.doneButtonFont){
                [fontAttributes setObject:konotorUIParameters.doneButtonFont forKey:NSFontAttributeName];
            }
            [self.navigationItem.leftBarButtonItem setTitleTextAttributes:fontAttributes forState:UIControlStateNormal];
        }
        
    }
    
    else{
        UIButton *leftButton=[UIButton buttonWithType:UIButtonTypeCustom];
        [leftButton setFrame:CGRectMake(0, 0, 32, 32)];
        [leftButton setImage:[konotorUIParameters closeButtonImage] forState:UIControlStateNormal];
        [leftButton addTarget:[KonotorFeedbackScreen class] action:@selector(dismissScreen) forControlEvents:UIControlEventTouchUpInside];
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:leftButton]];
    }
    
    
}



- (void) hideDoneButton
{
    [self.navigationItem setLeftBarButtonItem:nil];
}


- (void) viewWillAppear:(BOOL)animated{
    [KonotorFeedbackScreen sharedInstance].konotorFeedbackScreenNavigationController=self.navigationController;
    [KonotorFeedbackScreen sharedInstance].conversationViewController=self;
    UIViewController* currentTab=self.tabBarController.selectedViewController;
    if(currentTab&&(!showingInTab)){
        showingInTab=YES;
        tabBarHeight=self.tabBarController.tabBar.frame.size.height;
    }
    else if(!currentTab){
        showingInTab=NO;
    }
    
    if(showingInTab){
        [self hideDoneButton];
    }
    else{
        [self setUpDoneButton];
    }
    [messagesView refreshView];
}

- (UIRectEdge)edgesForExtendedLayout
{
    return UIRectEdgeNone;
}

- (void) viewDidAppear:(BOOL)animated
{
    if(KONOTOR_PUSH_ON_NAVIGATIONCONTROLLER){
        if([konotorUIParameters titleText])
            [self.navigationItem setTitle:[konotorUIParameters titleText]];
        else
            [self.navigationItem setTitle:@"Feedback"];

        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        if([konotorUIParameters closeButtonImage])
            [button setImage:[konotorUIParameters closeButtonImage] forState:UIControlStateNormal];
        else
            [button setBackgroundImage:[UIImage imageNamed:@"konotor_cross.png"] forState:UIControlStateNormal];
        button.frame=CGRectMake(0,0, 36, 36);
        [button addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        self.navigationItem.leftBarButtonItem=backButton;

    }

}



-(IBAction)cancel:(id)sender{
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 0);
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        [Konotor StopPlayback];
        [self.navigationController popViewControllerAnimated:YES];
    });
  
}

- (void) viewWillLayoutSubviews{
    CGFloat topBarOffset = self.topLayoutGuide.length;
    [headerContainerView setFrame:CGRectMake(headerContainerView.frame.origin.x, headerContainerView.frame.origin.y, headerContainerView.frame.size.width, topBarOffset)];
    [messageTableView setFrame:CGRectMake(messageTableView.frame.origin.x, topBarOffset, messageTableView.frame.size.width, messageTableView.frame.size.height-topBarOffset+messageTableView.frame.origin.y)];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIInterfaceOrientation toInterfaceOrientation=(UIInterfaceOrientationIsLandscape(fromInterfaceOrientation))?(UIInterfaceOrientationPortrait):(UIInterfaceOrientationLandscapeLeft);
    [KonotorVoiceInputOverlay rotateToOrientation:toInterfaceOrientation duration:0];
//    [KonotorImageInput rotateToOrientation:toInterfaceOrientation duration:0];
    if(self.messagesView.fullImageView)
        [self.messagesView.fullImageView rotateToOrientation:toInterfaceOrientation duration:0];

}

- (void) showTextInput
{
    [self.footerView setHidden:YES];
    [KonotorTextInputOverlay showInputForViewController:self];
}

- (void) showVoiceInput
{
    [Konotor startRecording];
}


- (void) showImageInput
{
//    [KonotorImageInput showInputOptions:self];

}

- (void) showRecordingFailed
{
    [KonotorUtility showToastWithString:@"Voice recording failed. Try again." forMessageID:nil];
}

- (void) showVoiceInputOverlay
{
    [KonotorVoiceInputOverlay showInputLinearForView:self.view];
}

- (void) switchToTextOnlyInput
{
    [KonotorUtility showToastWithString:@"Change Mic Permissions in Settings" forMessageID:nil];
    [voiceInput setImage:nil forState:UIControlStateNormal];
    [voiceInput setTitle:@"Send" forState:UIControlStateNormal];
    [voiceInput setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [voiceInput setFrame:CGRectMake(voiceInput.frame.origin.x-15, voiceInput.frame.origin.y, voiceInput.frame.size.width+20, voiceInput.frame.size.height)];
    [voiceInput setBackgroundColor:[UIColor whiteColor]];
    [voiceInput removeTarget:self action:@selector(showVoiceInput) forControlEvents:UIControlEventTouchDown];
    [voiceInput setUserInteractionEnabled:NO];
}

-(void) dismissVoiceInputOverlay
{
    [KonotorVoiceInputOverlay dismissVoiceInputOverlay];
}

- (void) refreshView
{
    [messagesView refreshView];
}


- (void) setupNavigationController{
    if([konotorUIParameters headerViewColor]){
        UINavigationController* navController=[KonotorFeedbackScreen sharedInstance].konotorFeedbackScreenNavigationController;
        [navController.navigationBar setBackgroundColor:[konotorUIParameters headerViewColor]];
        [navController.navigationBar setBarTintColor:[konotorUIParameters headerViewColor]];
    }
    
    if([konotorUIParameters titleTextColor]){
        [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[konotorUIParameters titleTextColor], NSForegroundColorAttributeName, nil]];
        [self.navigationController.navigationBar setTintColor:[konotorUIParameters titleTextColor]];
    }
    
    if([konotorUIParameters titleText])
        [self setTitle:[konotorUIParameters titleText]];
    
    if([konotorUIParameters titleTextFont])
        self.navigationController.navigationBar.titleTextAttributes=[NSDictionary dictionaryWithObjectsAndKeys:[konotorUIParameters titleTextFont],NSFontAttributeName, nil];
    
    if([konotorUIParameters doneButtonColor])
        [self.navigationItem.leftBarButtonItem setTintColor:[konotorUIParameters doneButtonColor]];
   
}

@end

@implementation KonotorUIParameters

@synthesize disableTransparentOverlay,headerViewColor,backgroundViewColor,voiceInputEnabled,imageInputEnabled,closeButtonImage,toastStyle,autoShowTextInput,titleText,toastBGColor,toastTextColor,textInputButtonImage,titleTextColor,showInputOptions,noPhotoOption,titleTextFont,allowSendingEmptyMessage,dontShowLoadingAnimation,sendButtonColor,doneButtonColor,userChatBubble,userTextColor,otherChatBubble,otherTextColor,overlayTransitionStyle,inputHintText,userProfileImage,otherProfileImage,showOtherName,showUserName,otherName,userName,messageTextFont,inputTextFont,notificationCenterMode,customFontName,doneButtonFont,doneButtonText,dismissesInputOnScroll,alwaysPollForMessages,pollingTimeNotOnChatWindow,pollingTimeOnChatWindow,otherChatBubbleInsets,userChatBubbleInsets/*,cancelButtonText,cancelButtonFont,cancelButtonColor*/;

+ (KonotorUIParameters*) sharedInstance
{
    if(konotorUIParameters==nil){
        konotorUIParameters=[[KonotorUIParameters alloc] init];
        konotorUIParameters.voiceInputEnabled=NO;
        konotorUIParameters.imageInputEnabled=YES;
        konotorUIParameters.toastStyle=KonotorToastStyleDefault;
        konotorUIParameters.toastBGColor=[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        konotorUIParameters.toastTextColor=[UIColor whiteColor];
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
        konotorUIParameters.otherChatBubble=[UIImage imageNamed:@"messagebubble_left"];
        konotorUIParameters.userTextColor=[UIColor darkGrayColor];
        konotorUIParameters.userChatBubble=[UIImage imageNamed:@"messagebubble_right"];
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
        
        konotorUIParameters.otherChatBubbleInsets=UIEdgeInsetsMake(19, 24, 20, 15);
        konotorUIParameters.userChatBubbleInsets=UIEdgeInsetsMake(20, 15, 19, 24);
        
    }
    return konotorUIParameters;
}

- (void) setToastStyle:(enum KonotorToastStyle) style backgroundColor:(UIColor*) bgColor textColor: (UIColor*) textColor
{
    self.toastStyle=style;
    self.toastTextColor=textColor;
    self.toastBGColor=bgColor;
}

- (void) disableMessageSharing{
    self.messageSharingEnabled=NO;
}
- (void) enableMessageSharing{
    self.messageSharingEnabled=YES;
}

@end
