//
//  HLArticleDetailViewController.m
//  HotlineSDK
//
//  Created by kirthikas on 21/09/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDReachability.h"
#import "HLArticleDetailViewController.h"
//#import "FDVotingManager.h"
//#import "FDSecureStore.h"
//#import "FDTheme.h"
//#import "FDBarButtonItem.h"
#import "HLMacros.h"
//#import "FDConstants.h"
#import <AVFoundation/AVFoundation.h>
#define HL_THEMES_DIR @"Themes"

@interface HLArticleDetailViewController ()

@property (strong, nonatomic) UIWebView *webView;
//@property (strong, nonatomic) FDTheme *theme;
@property (strong, nonatomic) FDReachability *reachability;
//@property (strong, nonatomic) FDSecureStore *secureStore;
//@property (strong, nonatomic) FDVotingManager *votingManager;
@property (strong, nonatomic) NSLayoutConstraint         *promptViewHeightConstraint;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSString *appAudioCategory;

@end

@implementation HLArticleDetailViewController

@synthesize promptViewHeightConstraint;

#pragma mark - Lazy Instantiations

- (instancetype)init{
    self = [super init];
    if (self) {
        // _theme = [FDTheme sharedInstance];
        // _secureStore = [FDSecureStore sharedInstance];
        // _votingManager = [FDVotingManager sharedInstance];
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
            "%@" // Article Content
            "</body>"
            "</html>", [self normalizeCssContent],article];
}

-(NSString *)normalizeCssContent{
    NSBundle *hlResourceBundle = [self getHLResourceBundle];
    NSString  *cssFilePath = [hlResourceBundle pathForResource:@"normalize" ofType:@"css" inDirectory:HL_THEMES_DIR];
    NSData *cssContent = [NSData dataWithContentsOfFile:cssFilePath];
    return [[NSString alloc]initWithData:cssContent encoding:NSUTF8StringEncoding];
}

-(NSBundle *)getHLResourceBundle{
    NSBundle *HLResourceBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"MHResources" withExtension:@"bundle"]];
    return HLResourceBundle;
}

#pragma mark - Life cycle methods

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [self setNavigationItem];
    [self registerAppAudioCategory];
    //[self theming];
    [self setSubviews];
    [self checkNetworkReachability];
    [self fixAudioPlayback];
    //[self handleArticleVoteAfterSometime];
}


//-(void)handleArticleVoteAfterSometime{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self handleArticleVotePrompt];
//    });
//}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [self resetAudioPlayback];
}

//-(void)theming{
//    self.view.backgroundColor = [self.theme backgroundColorSDK];
//}

-(void)setNavigationItem{
    [self.navigationItem setTitle:@"Solution Article"];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    [self.parentViewController.navigationItem setRightBarButtonItem:barButton animated:YES];
}

-(void)setSubviews{
    self.webView = [[UIWebView alloc]init];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.delegate = self;
    self.webView.dataDetectorTypes = UIDataDetectorTypeAll;
    self.webView.scrollView.delegate = self;
    [self.webView loadHTMLString:self.embedHTML baseURL:nil];
    [self.view addSubview:self.webView];
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    
//    FDYesNoPromptView *articleVotePrompt = [[FDYesNoPromptView alloc] initWithDelegate:self andKey:@"Article Vote Prompt"];
//    articleVotePrompt.delegate = self;
//    articleVotePrompt.translatesAutoresizingMaskIntoConstraints = NO;
//    [self.view addSubview:articleVotePrompt];
//    
//
//    
//    self.promptViewHeightConstraint = [NSLayoutConstraint constraintWithItem:articleVotePrompt
//                                                                   attribute:NSLayoutAttributeHeight
//                                                                   relatedBy:NSLayoutRelationEqual
//                                                                      toItem:nil
//                                                                   attribute:NSLayoutAttributeNotAnAttribute
//                                                                  multiplier:1.0
//                                                                    constant:0];
//    
//    [self.view addConstraint:self.promptViewHeightConstraint];
    
    NSDictionary *views = @{@"webView" : self.webView};
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[promptView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:views]];
    
}

-(void)checkNetworkReachability{
    self.reachability = [FDReachability reachabilityWithHostname:@"www.google.com"];
    __weak typeof(self)weakSelf = self;
    //Internet is reachable
    self.reachability.reachableBlock = ^(FDReachability*reach){
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.webView loadHTMLString:weakSelf.embedHTML baseURL:nil];
        });
    };
    [self.reachability startNotifier];
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
    //    [self handleArticleVotePrompt];
}

//-(void)handleArticleVotePrompt{
//    if (self.webView.scrollView.contentOffset.y >= (self.webView.scrollView.contentSize.height - self.webView.scrollView.frame.size.height)) {
//        BOOL isArticleVoted = [self.votingManager isArticleVoted:self.articleID];
//        if (!isArticleVoted) {
//            [self showArticleRatingPrompt];
//        }
//    }
//    else if(self.webView.scrollView.contentOffset.y >= 0 && self.webView.scrollView.contentOffset.y < (self.webView.scrollView.contentSize.height - self.webView.scrollView.frame.size.height)){
//        [self hideArticleRatingPrompt];
//    }
//}
//
//-(void) showArticleRatingPrompt{
//    [UIView animateWithDuration:.5 animations:^{
//        self.promptViewHeightConstraint.constant = PROMPT_VIEW_HEIGHT;
//        [self.view layoutIfNeeded];
//    }];
//}
//
//-(void) hideArticleRatingPrompt{
//    [UIView animateWithDuration:.5 animations:^{
//        self.promptViewHeightConstraint.constant = 0;
//        [self.view layoutIfNeeded];
//    }];
//}
//
//-(void)yesButtonClicked:(id)sender{
//    [self hideArticleRatingPrompt];
//    [self.votingManager upVoteForArticle:self.articleID withCompletion:^(NSError *error) {
//        FDLog(@"Voting Completed");
//    }];
//}
//
//-(void)noButtonClicked:(id)sender{
//    [self hideArticleRatingPrompt];
//    [self.votingManager downVoteForArticle:self.articleID withCompletion:^(NSError *error) {
//        FDLog(@"Voting Completed");
//    }];
//}

@end