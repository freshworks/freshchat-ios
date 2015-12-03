//
//  FDAttachmentImageController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 03/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDAttachmentImageController.h"
#import "Konotor.h"

@interface FDAttachmentImageController ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation FDAttachmentImageController

-(instancetype)initWithImage:(UIImage *)image{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationItem];
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc]initWithImage:self.image];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    NSDictionary *views = @{ @"imageView" : self.imageView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[imageView]-20-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[imageView]-20-|" options:0 metrics:nil views:views]];
}

-(void)setNavigationItem{
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc]initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendButton:)];
    self.navigationItem.rightBarButtonItem = sendButton;
    self.navigationController.navigationBar.translucent = NO;
}

-(void)sendButton:(UIBarButtonItem *)button{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate attachmentController:self didFinishSelectingImage:self.image];
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

@end