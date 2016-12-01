//
//  ViewController.m
//  Hotline
//
//  Created by AravinthChandran on 9/7/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "ViewController.h"
#import "HotlineSDK/Hotline.h"
#import "FDSettingsController.h"
#import "AppDelegate.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSURL *soundUrl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [self setupSubview];
    
    self.view.backgroundColor = [UIColor colorWithHue:0 saturation:0 brightness:0.95 alpha:1];
    [super viewDidLoad];
    
    // Construct URL to sound file
    NSString *path = [NSString stringWithFormat:@"%@/youraudio.mp3", [[NSBundle mainBundle] resourcePath]];
    _soundUrl = [NSURL fileURLWithPath:path];
    
    // Create audio player object and initialize with URL to sound
    if(_soundUrl){
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_soundUrl error:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveHLPlayNotification:)
                                                 name:HOTLINE_DID_FINISH_PLAYING_AUDIO_MESSAGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveHLPauseNotification:)
                                                 name:HOTLINE_WILL_PLAY_AUDIO_MESSAGE
                                               object:nil];
    
}

- (void) receiveHLPlayNotification:(NSNotification *) notification{
    if(_soundUrl){
        [_audioPlayer play];
    }
}

- (void) receiveHLPauseNotification:(NSNotification *) notification{
    if(_soundUrl){
        [_audioPlayer pause];
    }
}

-(void)setupSubview{
    self.imageView = [[UIImageView alloc]init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.imageView atIndex:0];
    
    NSDictionary *views = @{@"imgView" : self.imageView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imgView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imgView]|" options:0 metrics:nil views:views]];
}

-(void)viewWillAppear:(BOOL)animated{
    
    if(![_audioPlayer isPlaying]){
        [_audioPlayer play];
    }
    [super viewWillAppear:animated];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.pickedImage) {
        self.imageView.image = appDelegate.pickedImage;
    }else{
        self.imageView.image = [UIImage imageNamed:@"background"];
    }
}

- (IBAction)chatButtonPressed:(id)sender {
    FAQOptions *options = [FAQOptions new];
    options.showFaqCategoriesAsGrid = YES;
    options.showContactUsOnFaqScreens = YES;
//    [options filterByTags : @[ @"sample"] withTitle:@"newTag"];
    //options.showContactUsOnAppBar = YES;
    [[Hotline sharedInstance]showFAQs:self withOptions:options];
}

@end
