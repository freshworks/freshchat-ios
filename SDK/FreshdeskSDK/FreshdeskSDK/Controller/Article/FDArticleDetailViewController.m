//
//  FDArticleDetailViewController.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 06/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDReachability.h"
#import "FDFooterView.h"
#import "FDArticleDetailViewController.h"
#import "FDSecureStore.h"
#import "FDTheme.h"
#import "FDBarButtonItem.h"
#import "FDMacros.h"
#import <AVFoundation/AVFoundation.h>

@interface FDArticleDetailViewController ()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) FDTheme *theme;
@property (strong, nonatomic) FDReachability *reachability;
@property (strong, nonatomic) FDFooterView *footerView;
@property (strong, nonatomic) FDSecureStore *secureStore;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSString *appAudioCategory;
@property (nonatomic) BOOL isModalView;

@end

@implementation FDArticleDetailViewController

#pragma mark - Lazy Instantiations
-(instancetype)initWithModalPresentationType:(BOOL)isModalPresentation {
    self = [super init];
    if (self) {
        self.isModalView = isModalPresentation;
    }
    return self;
}


-(FDTheme *)theme{
    if(!_theme){
        _theme = [FDTheme sharedInstance];
    }
    return _theme;
}

-(FDSecureStore *)secureStore{
    if(!_secureStore){
        _secureStore = [FDSecureStore sharedInstance];
    }
    return _secureStore;
}

-(NSString *)embedHTML{
    NSString *article = [self.articleDescription stringByReplacingOccurrencesOfString:@"src=\"//" withString:@"src=\"http://"];
    article = [article stringByReplacingOccurrencesOfString:@"value=\"//" withString:@"value=\"http://"];
    return [NSString stringWithFormat:@""
            "<html>"
            "<style type=\"text/css\">"
            "%@" // CSS Content
            "</style>"
            "<body>"
            "%@" // Article Content
            "</body>"
            "</html>", [[self theme] normalizeCssContent],article];
}

#pragma mark - Life cycle methods

-(void)viewDidLoad{
    [super viewDidLoad];
    [self registerAppAudioCategory];
    [self theming];
    [self setNavigationItem];
    [self setSubviews];
    [self checkNetworkReachability];
    [self fixAudioPlayback];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self resetAudioPlayback];
}

-(void)theming{
    self.view.backgroundColor = [self.theme backgroundColorSDK];
}

-(void)setNavigationItem{
    [self.navigationItem setTitle:FDLocalizedString(@"Solutions Detail Nav Bar Title Text" )];
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    [self.navigationItem setRightBarButtonItem:barButton animated:YES];
    if(self.isModalView)
    {
        FDBarButtonItem *backButton = [[FDBarButtonItem alloc]initWithTitle:FDLocalizedString(@"Solutions Detail Nav Bar Back Button Text") style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];
        [self.navigationItem setLeftBarButtonItem:backButton];
    }
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)setSubviews{

    //Webview
    self.webView = [[UIWebView alloc]init];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.delegate = self;
    self.webView.dataDetectorTypes = UIDataDetectorTypeAll;
    [self.webView loadHTMLString:self.embedHTML baseURL:nil];
    [self.view addSubview:self.webView];
    
    //FooterView
    self.footerView = [[FDFooterView alloc]initWithController:self];
    [self.view addSubview:self.footerView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    if ([self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_PAID_USER]) {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    }
    else{
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:-20.0]];
    }
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1.0
                                                           constant:0.0]];
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

@end