//
//  InAppBrowser.m
//  Hotline Demo
//
//  Created by Sanjith Kanagavel on 23/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

#import "InAppBrowser.h"

@implementation InAppBrowser

- (void)viewDidLoad {
    [super viewDidLoad];
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width ,self.webUIView.frame.size.height ) configuration:theConfiguration];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:_url];
    self.urlLabel.text = [self.url absoluteString];
    webView.navigationDelegate = self;
    [webView loadRequest:nsrequest];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webUIView addSubview:webView];
    [self.webUIView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:@{@"webView":webView}]];
    [self.webUIView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:@{@"webView":webView}]];
    
    [self.loadingView startAnimating];
    self.loadingView.hidesWhenStopped = true;
}
- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.loadingView stopAnimating];
}
@end
