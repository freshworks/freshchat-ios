//
//  HLArticleDetailViewController.m
//  HotlineSDK
//
//  Created by kirthikas on 21/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "HLArticleDetailViewController.h"
#import "FDVotingManager.h"
#import "FDSecureStore.h"
#import "HLMacros.h"
#import "HLTheme.h"
#import "FDLocalNotification.h"
#import "Hotline.h"

@interface HLArticleDetailViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIWebView *webView;
//@property (strong, nonatomic) FDTheme *theme;
@property (strong, nonatomic) FDSecureStore *secureStore;
@property (strong, nonatomic) FDVotingManager *votingManager;
@property (strong,nonatomic) FDYesNoPromptView *articleVotePromptView;
@property (strong, nonatomic) FDAlertView *thankYouPromptView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSString *appAudioCategory;
@property (strong, nonatomic) NSMutableDictionary *promptHeightConstraintMap;

@end

@implementation HLArticleDetailViewController

#pragma mark - Lazy Instantiations

- (instancetype)init{
    self = [super init];
    if (self) {
        // _theme = [FDTheme sharedInstance];
         _secureStore = [FDSecureStore sharedInstance];
         _votingManager = [FDVotingManager sharedInstance];
        _promptHeightConstraintMap = [[NSMutableDictionary alloc]init];
    }
    return self;
}

-(NSString *)embedHTML{
    NSString *article = [self.articleDescription stringByReplacingOccurrencesOfString:@"src=\"//" withString:@"src=\"https://"];
    article = [article stringByReplacingOccurrencesOfString:@"value=\"//" withString:@"value=\"https://"];
    return [NSString stringWithFormat:@""
            "<html>"
            "<style type=\"text/css\">"
            "%@" // CSS Content
            "</style>"
            "<body>"
            "<div class='article-title'><h3>"
            "%@" // Article Title
            "<h3></div>"
            "<div class='article-body'>"
            "%@" // Article Content
            "</div>"
            "</body>"
            "</html>", [self normalizeCssContent],self.articleTitle,article];
}

-(NSString *)normalizeCssContent{
    return [[HLTheme sharedInstance] getCssFileContent:@"normalize"];
}
#pragma mark - Life cycle methods

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [self setNavigationItem];
    [self registerAppAudioCategory];
    [self theming];
    [self setSubviews];
    [self fixAudioPlayback];
    [self localNotificationSubscription];
    [self handleArticleVoteAfterSometime];
}

-(void)localNotificationSubscription{
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_NETWORK_REACHABLE object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf.webView loadHTMLString:self.embedHTML baseURL:nil];
        [self handleArticleVoteAfterSometime];
    }];
}

-(void)handleArticleVoteAfterSometime{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self handleArticleVotePrompt];
    });
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self resetAudioPlayback];
}

-(void)theming{
    self.view.backgroundColor = [[HLTheme sharedInstance] backgroundColorSDK];
}

-(void)setNavigationItem{
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[HLTheme sharedInstance] getImageWithKey:@"BackArrow"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self.navigationController
                                                                  action:@selector(popViewControllerAnimated:)];
    self.parentViewController.navigationItem.rightBarButtonItem = rightBarButton;
    self.parentViewController.navigationItem.leftBarButtonItem = backButton;
    
    if (self.parentViewController) {
        self.parentViewController.navigationController.interactivePopGestureRecognizer.delegate = self;
    }else{
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }

}

-(void)setUpHeightConstraint:(FDPromptView *)promptView {
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:promptView
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0
                                  constant:[promptView getPromptHeight]];
    [self.promptHeightConstraintMap setObject:heightConstraint forKey:[self getKeyForObject:promptView]];
}

-(NSString *) getKeyForObject:(NSObject *) object {
    return [NSString stringWithFormat:@"%lu" , (unsigned long)[object hash]];
}

-(NSLayoutConstraint *) getHeightConstraint:(FDPromptView *) promptView {
    return [self.promptHeightConstraintMap  valueForKey:[self getKeyForObject:promptView]];
}


-(void)setSubviews{
    self.webView = [[UIWebView alloc]init];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.delegate = self;
    self.webView.dataDetectorTypes = UIDataDetectorTypeAll;
    self.webView.scrollView.scrollEnabled = YES;
    self.webView.scrollView.delegate = self;
    [self.webView loadHTMLString:self.embedHTML baseURL:nil];
    [self.view addSubview:self.webView];
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    
    //Article Vote Prompt View
    self.articleVotePromptView = [[FDYesNoPromptView alloc] initWithDelegate:self andKey:@"ARTICLE_VOTE_PROMPT"];
    self.articleVotePromptView.delegate = self;
    self.articleVotePromptView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //Thank you prompt view
    self.thankYouPromptView = [[FDAlertView alloc] initWithDelegate:self andKey:@"THANK_YOU_PROMPT"];
    self.thankYouPromptView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.webView];
    [self.view addSubview:self.articleVotePromptView];
    [self.view addSubview:self.thankYouPromptView];
    
    [self setUpHeightConstraint:self.articleVotePromptView];
    [self setUpHeightConstraint:self.thankYouPromptView];
    
    NSDictionary *views = @{@"webView" : self.webView, @"articleVotePromptView" : self.articleVotePromptView, @"contactUsVotePromptView" : self.thankYouPromptView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[articleVotePromptView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contactUsVotePromptView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView][articleVotePromptView][contactUsVotePromptView]|" options:0 metrics:nil views:views]];
    
    [self modifyConstraint:[self getHeightConstraint:self.thankYouPromptView] withHeight:0];
    [self modifyConstraint:[self getHeightConstraint:self.articleVotePromptView] withHeight:0];
    
    [self.thankYouPromptView setHidden:YES];
    [self.articleVotePromptView setHidden:YES];
}

-(void)modifyConstraint:(NSLayoutConstraint *)constraint withHeight:(CGFloat)height{
    constraint.constant = height;
    [self.view addConstraint:constraint];
}

#pragma mark - Webview delegate

-(BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if (inType == UIWebViewNavigationTypeLinkClicked){
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    [self.activityIndicator startAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self.activityIndicator stopAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityIndicator stopAnimating];
}

//Hack for playing audio on WebView
-(void)registerAppAudioCategory{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    self.appAudioCategory = audioSession.category;
}

-(void) fixAudioPlayback {
    if([ self needAudioFix] ) {
        [self setAudioCategory:AVAudioSessionCategoryPlayback];
    }
}

-(BOOL) needAudioFix {
    return (self.appAudioCategory &&
            ( self.appAudioCategory != AVAudioSessionCategoryPlayAndRecord
             && self.appAudioCategory != AVAudioSessionCategoryPlayback ) );
}

-(void)resetAudioPlayback{
    if([self needAudioFix]) {
        [self setAudioCategory:self.appAudioCategory];
    }
}

-(void)setAudioCategory:(NSString *) audioSessionCategory{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    
    if (![audioSession setCategory:audioSessionCategory error:&setCategoryError]) {
        FDLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }
    
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self handleArticleVotePrompt];
}

-(void)handleArticleVotePrompt{
    if (self.webView.scrollView.contentOffset.y >= ((self.webView.scrollView.contentSize.height-20) - self.webView.scrollView.frame.size.height)) {
        BOOL isArticleVoted = [self.votingManager isArticleVoted:self.articleID];
        BOOL articleVote = [self.votingManager getArticleVoteFor:self.articleID];
        if (!isArticleVoted) {
            [self showArticleRatingPrompt];
        }
        else{
            if (articleVote == NO) {
                [self showContactUsPrompt];
            }
        }
    }
    else if(self.webView.scrollView.contentOffset.y >= 0 && self.webView.scrollView.contentOffset.y < (self.webView.scrollView.contentSize.height - self.webView.scrollView.frame.size.height)){
        [self hideArticleRatingPrompt];
        [self hideContactUsPrompt];
    }
}

-(void) hidePrompt:(FDPromptView *)promptView {
    [UIView animateWithDuration:.5 animations:^{
        [promptView setHidden:YES];
        [self modifyConstraint:[self getHeightConstraint:promptView] withHeight:0];
        [self.view layoutIfNeeded];
    }];
}

-(void)showPrompt:(FDPromptView *)promptView {
    [UIView animateWithDuration:.5 animations:^{
        [promptView setHidden:NO];
        [self modifyConstraint:[self getHeightConstraint:promptView] withHeight:[promptView getPromptHeight]];
        [self.view layoutIfNeeded];
    }];
}

-(void) showArticleRatingPrompt{
    [self showPrompt:self.articleVotePromptView];
}

-(void) hideArticleRatingPrompt{
    [self hidePrompt:self.articleVotePromptView];
}

-(void)showContactUsPrompt{
    self.thankYouPromptView.Button1.hidden = NO;
    [self showPrompt:self.thankYouPromptView];
}

-(void)showThankYouPrompt{
    self.thankYouPromptView.Button1.hidden = YES;
    [self showPrompt:self.thankYouPromptView];
}

-(void)hideContactUsPrompt{
   [self hidePrompt:self.thankYouPromptView];
}

-(void)yesButtonClicked:(id)sender{
    [self hideArticleRatingPrompt];
    [self showThankYouPrompt];
    [self.votingManager upVoteForArticle:self.articleID inCategory:self.categoryID withCompletion:^(NSError *error) {
        FDLog(@"Voting Completed");
    }];
}

-(void)noButtonClicked:(id)sender{
    [self hideArticleRatingPrompt];
    [self showContactUsPrompt];
    [self.votingManager downVoteForArticle:self.articleID inCategory:self.categoryID withCompletion:^(NSError *error) {
        FDLog(@"Voting Completed");
    }];
}

-(void)buttonClickedEvent:(id)sender{
    [self hideContactUsPrompt];
    [[Hotline sharedInstance] presentFeedback:self];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end