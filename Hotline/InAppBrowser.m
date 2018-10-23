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
    [webView loadRequest:nsrequest];
    [self.webUIView addSubview:webView];
}
- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}
@end
