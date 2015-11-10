//
//  FDMessageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDMessageController.h"
#import "FDMessageCell.h"
#import "Konotor.h"
#import "KonotorImageInput.h"

@interface FDMessageController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) HLChannel *channel;
@property (nonatomic, strong) FDInputToolbarView *inputToolbar;
@property (strong, nonatomic) NSLayoutConstraint *bottomViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *bottomViewBottomConstraint;
@property (strong, nonatomic) UIView *bottomView;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) BOOL isKeyboardOpen;
@property (nonatomic) BOOL isModalPresentationPreferred;

@end

@implementation FDMessageController

static BOOL promptForPush=YES;
static CGFloat TOOLBAR_HEIGHT = 40;
BOOL firstWordOnLine=YES;

-(instancetype)initWithChannel:(HLChannel *)channel andPresentModally:(BOOL)isModal{
    self = [super init];
    if (self) {
        self.channel = channel;
        self.isModalPresentationPreferred = isModal;
    }
    return self;
}

-(void)willMoveToParentViewController:(UIViewController *)parent{
    parent.title = @"Messages";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setSubviews];
    [self updateMessages];
    [self setNavigationItem];
    [self localNotificationSubscription];
}

-(void)setNavigationItem{
    if(self.isModalPresentationPreferred){
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
        [self.parentViewController.navigationItem setLeftBarButtonItem:closeButton];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)updateMessages{
    self.messages = @[@"Welcome to the conversations related to billing",
                      @"how do i book using card. I should <a href=\"http://yahoo.com\">Yahoo</a> this already!",
                      @"you can use this link http://goo.le/d35Gfac"];
}

-(void)setSubviews{
    self.tableView = [[UITableView alloc]init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.separatorStyle=UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    //Bottomview
    self.bottomView = [[UIView alloc]init];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bottomView];
    
    self.bottomViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeHeight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:nil
                                                              attribute:NSLayoutAttributeNotAnAttribute
                                                             multiplier:1.0
                                                               constant:TOOLBAR_HEIGHT];
    
    self.bottomViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.bottomView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0 constant:0];
    
    self.inputToolbar = [[FDInputToolbarView alloc]initWithDelegate:self];
    self.inputToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inputToolbar showAttachButton:YES];

    //Initial Constraints
    NSDictionary *views = @{@"tableView" : self.tableView, @"bottomView" : self.bottomView};
    [self.view addConstraint:self.bottomViewBottomConstraint];
    [self.view addConstraint:self.bottomViewHeightConstraint];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomView]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView][bottomView]" options:0 metrics:nil views:views]];
    
    [self updateBottomViewWith:self.inputToolbar andHeight:TOOLBAR_HEIGHT];
}

-(void)updateBottomViewWith:(UIView *)view andHeight:(CGFloat) height{
    [[self.bottomView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.bottomView addSubview:view];
    self.bottomViewHeightConstraint.constant = height;
    
    NSDictionary *views = @{ @"bottomInputView" : view };
    [self.bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bottomInputView]|" options:0 metrics:nil views:views]];
    [self.bottomView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bottomInputView]|" options:0 metrics:nil views:views]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = @"FDMessageCell";
    FDMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FDMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell initCell];
    }
    
    if (indexPath.row < self.messages.count) {
        //cell.textLabel.text  = self.messages[indexPath.row];
        KonotorMessageData* message=[[KonotorMessageData alloc] init];
        message.messageType=[NSNumber numberWithInt:KonotorMessageTypeText];
        message.picThumbUrl=@"http://www.britishairways.com/assets/images/destinations/components/mainCarousel/orlando/US-ORL-DISNEY-CASTLE-WALK-760x350.jpg";
        message.picThumbWidth=[NSNumber numberWithFloat:300.0];
        message.picThumbHeight=[NSNumber numberWithFloat:150.0];
        message.text=self.messages[indexPath.row];
        [cell drawMessageViewForMessage:message parentView:self.view];
        
    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messages.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    KonotorMessageData* message=[[KonotorMessageData alloc] init];
    message.messageType=[NSNumber numberWithInt:KonotorMessageTypeText];
    message.picThumbUrl=@"http://www.britishairways.com/assets/images/destinations/components/mainCarousel/orlando/US-ORL-DISNEY-CASTLE-WALK-760x350.jpg";
    message.picThumbWidth=[NSNumber numberWithFloat:300.0];
    message.picThumbHeight=[NSNumber numberWithFloat:150.0];
    message.text=self.messages[indexPath.row];
    float height=[FDMessageCell getHeightForMessage:message parentView:self.view];
    return height;
}

-(void)inputToolbarAttachmentButtonPressed:(id)sender{
    [KonotorImageInput showInputOptions:self];
}

-(void)inputToolbarSendButtonPressed:(id)sender{
    NSCharacterSet *trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *toSend = [self.inputToolbar.inputTextView.text stringByTrimmingCharactersInSet:trimChars];
    if((![KonotorUIParameters sharedInstance].allowSendingEmptyMessage)&&[toSend isEqualToString:@""]){
        UIAlertView* alertNilString=[[UIAlertView alloc] initWithTitle:@"Empty Message" message:@"You cannot send an empty message. Please type a message to send." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertNilString show];
    }else{
        [Konotor uploadTextFeedback:toSend];
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
        self.inputToolbar.inputTextView.text = @"";
        [self textViewDidChange:self.inputToolbar.inputTextView];
        
    }
    [KonotorFeedbackScreen performSelector:@selector(refreshMessages) withObject:nil afterDelay:0.0];
}

-(void) keyboardWillShow:(NSNotification *)note{
    self.isKeyboardOpen = YES;
    CGRect keyboardFrame = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRect = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat keyboardCoveredHeight = self.view.bounds.size.height - keyboardRect.origin.y;
    self.bottomViewBottomConstraint.constant = - keyboardCoveredHeight;
    self.keyboardHeight = keyboardCoveredHeight;
    [self scrollTableViewToLastCell];
    [self.view layoutIfNeeded];
}

-(void) keyboardWillHide:(NSNotification *)note{
    self.isKeyboardOpen = NO;
    NSTimeInterval animationDuration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardHeight = 0.0;
    self.bottomViewBottomConstraint.constant = 0.0;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint fingerLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
    CGPoint absoluteFingerLocation = [scrollView convertPoint:fingerLocation toView:self.view];
    NSInteger keyboardOffsetFromBottom = self.view.frame.size.height - absoluteFingerLocation.y;
    
    if (self.isKeyboardOpen && scrollView.panGestureRecognizer.state == UIGestureRecognizerStateChanged && absoluteFingerLocation.y >= (self.view.frame.size.height - self.keyboardHeight)) {
        self.bottomViewBottomConstraint.constant = -keyboardOffsetFromBottom;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (self.keyboardHeight > 0) {
        [self scrollTableViewToLastCell];
    }
}

-(void)localNotificationSubscription{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleBecameActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
}

-(void)localNotificationUnSubscription{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleBecameActive:(NSNotification *)notification{

}

-(void)handleEnteredBackground:(NSNotification *)notification{
    
}


#pragma Growing text view delegates

- (void) textViewDidChange:(UITextView *)inputTextView{
    CGSize txtSize = [inputTextView sizeThatFits:CGSizeMake(inputTextView.frame.size.width, 140)];
    float height=txtSize.height;
    if((height)>=67){
        height=67;
        if(firstWordOnLine==YES){
            firstWordOnLine=NO;
        }else{
            inputTextView.scrollEnabled=YES;
        }
    }
    else{
        inputTextView.scrollEnabled=NO;
    }
    
    if (height > self.bottomViewHeightConstraint.constant) {
        self.bottomViewHeightConstraint.constant = height+10; //Fix this
        self.bottomViewBottomConstraint.constant = - self.keyboardHeight;
    }
    else{
        self.bottomViewHeightConstraint.constant = height+10; //Fix this
        self.bottomViewBottomConstraint.constant = - self.keyboardHeight;
    }
    inputTextView.frame=CGRectMake(inputTextView.frame.origin.x,inputTextView.frame.origin.y,inputTextView.frame.size.width,height);
    [self scrollTableViewToLastCell];
}

-(void)scrollTableViewToLastCell{
    NSInteger lastCellIndex =  self.messages.count - 1;
    if (lastCellIndex >0 ) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastCellIndex inSection:0];
        NSUInteger noOfRows = [self.tableView numberOfRowsInSection:indexPath.section];
        if (noOfRows==0) {
            [self.tableView reloadData];
        }
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(void)dealloc{
    [self localNotificationUnSubscription];
}

@end