//
//  InAppBrowser.h
//  Hotline Demo
//
//  Created by Sanjith Kanagavel on 23/10/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//
#import "InAppBrowser.h"
#import <WebKit/WebKit.h>

@interface InAppBrowser : UIViewController
    @property NSURL *url;
@property (weak, nonatomic) IBOutlet UIView *webUIView;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@end
