//
//  FCHybridMessageController.m
//  FreshchatSDK
//
//  Created by Sanjith Kanagavel on 03/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import "FCHybridMessageController.h"
#import <WebKit/WebKit.h>

@interface FCHybridMessageController() <WKNavigationDelegate>
@property(strong, nonnull, nonatomic) NSURL *webURL;
@property(strong, nonatomic) WKWebView *webView;
@property(strong, nonatomic) WKWebViewConfiguration *configuration;
@property(strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation FCHybridMessageController

-(id)initWithURL:(nonnull NSURL *) url {
    self = [super init];
    if(self) {
        _webURL = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityIdentifier = @"FCHybridMessageController";
    _configuration = [[WKWebViewConfiguration alloc]init];
    _webView = [[WKWebView alloc] initWithFrame:CGRectNull configuration:_configuration];
    _webView.navigationDelegate = self;
    _webView.accessibilityIdentifier = @"WebView";
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.accessibilityIdentifier = @"ActivityIndicator";
    _activityIndicator.hidesWhenStopped = true;
    [self setUpViews];
    [self loadURL];
}

- (void) setUpViews {
    [self.view addSubview:_webView];
    [self.view addSubview:_activityIndicator];
    _webView.translatesAutoresizingMaskIntoConstraints = false;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
    NSDictionary<NSString *, id> *views= @{@"webView":_webView,@"indicator":_activityIndicator};
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[webView]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[webView]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[indicator]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[indicator]-|" options:0 metrics:nil views:views]];
}

-(void)loadURL {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:_webURL];
    [_webView loadRequest:request];
    [_activityIndicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_activityIndicator stopAnimating];
    });
}

@end
