//
//  FDCSATView.m
//  HotlineSDK
//
//  Created by user on 17/10/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "FDCSATView.h"
#import "HCSStarRatingView.h"
#import "FDAutolayoutHelper.h"
#import "HLTheme.h"

@interface FDCSATView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *transparentView;
@property (nonatomic, strong) UIView *CSATPrompt;
@property (nonatomic, strong) UITextView *feedbackView;
@property (nonatomic) float rating;


@end

// Add autolayout
// Dismiss prompt & Add config
// Add theme

@implementation FDCSATView

- (instancetype)initWithController:(UIViewController *)controller andDelegate:(id <FDCSATViewDelegate>)delegate{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        
        self.delegate = delegate;
        
        self.transparentView  = [UIView new];

        self.transparentView.backgroundColor =  [UIColor colorWithWhite:0.5 alpha:0.5];
        self.transparentView.frame = controller.view.frame;

        //Add tap recognizer to dismiss CSAT view
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutsidePrompt)];
        singleTap.delegate = self;
        singleTap.numberOfTapsRequired = 1;
        [self.transparentView addGestureRecognizer:singleTap];

        self.CSATPrompt = [UIView new];
        self.CSATPrompt.backgroundColor = [UIColor whiteColor];
        self.CSATPrompt.frame = CGRectMake(0, 0, 250, 200);
        self.CSATPrompt.center = self.transparentView.center;
        
        //Layer changes
        self.CSATPrompt.layer.cornerRadius = 15;
        
        [controller.view addSubview:self.transparentView];
        [self.transparentView addSubview:self.CSATPrompt];
        
        [self addStarRatingView];
        
        //Hide by default
        self.transparentView.hidden = YES;
        self.CSATPrompt.hidden = YES;
        
        UILabel *surveyTitle = [UILabel new];
        surveyTitle.numberOfLines = 0;
        surveyTitle.textAlignment = NSTextAlignmentCenter;
        surveyTitle.translatesAutoresizingMaskIntoConstraints = NO;
        surveyTitle.text = @"How would you rate your interaction with us ?";
        [self.CSATPrompt addSubview:surveyTitle];
        
        UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        submitButton.translatesAutoresizingMaskIntoConstraints = NO;
        [submitButton setTitle:@"SUBMIT" forState:(UIControlStateNormal)];
        [submitButton addTarget:self action:@selector(submitButtonPressed) forControlEvents:(UIControlEventTouchUpInside)];
        [self.CSATPrompt addSubview:submitButton];
        
        self.feedbackView = [UITextView new];
        self.feedbackView.backgroundColor = [UIColor greenColor];
        self.feedbackView.text = @"Enter feedback here";
        self.feedbackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.CSATPrompt addSubview:self.feedbackView];
        
        UIView *horizontalLine = [UIView new];
        horizontalLine.backgroundColor = [UIColor lightGrayColor];
        horizontalLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self.CSATPrompt addSubview:horizontalLine];
        
        NSDictionary *views = @{@"survey_title" : surveyTitle, @"submit_button" : submitButton, @"horizontal_line" : horizontalLine, @"feedback_view" : self.feedbackView};
        
        [self.CSATPrompt addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[survey_title]" options:0 metrics:nil views:views]];
        [FDAutolayoutHelper centerX:surveyTitle onView:self.CSATPrompt];
        [FDAutolayoutHelper setWidth:200 forView:surveyTitle inView:self.CSATPrompt];
        [FDAutolayoutHelper centerX:submitButton onView:self.CSATPrompt];
        [self.CSATPrompt addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[horizontal_line]|" options:0 metrics:nil views:views]];
        [FDAutolayoutHelper centerX:self.feedbackView onView:self.CSATPrompt];
        [FDAutolayoutHelper setWidth:150 forView:self.feedbackView inView:self.CSATPrompt];
        [self.CSATPrompt addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[feedback_view(20)]-15-[horizontal_line(1)]-15-[submit_button(20)]-15-|" options:0 metrics:nil views:views]];

        //Add growing text view
    }
    return self;
}

-(void)addStarRatingView{
    HCSStarRatingView *starRatingView = [HCSStarRatingView new];
    starRatingView.translatesAutoresizingMaskIntoConstraints = NO;
    starRatingView.maximumValue = 5;
    starRatingView.minimumValue = 0;
    starRatingView.value = 0; // Initial value
    starRatingView.tintColor = [UIColor orangeColor];
    starRatingView.emptyStarImage = [[UIImage imageNamed:@"heart-empty"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    starRatingView.filledStarImage = [[UIImage imageNamed:@"heart-full"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [starRatingView addTarget:self action:@selector(didChangeValue:) forControlEvents:UIControlEventValueChanged];
    [self.CSATPrompt addSubview:starRatingView];
    
    // auto layout
    [FDAutolayoutHelper setWidth:150 forView:starRatingView inView:self.CSATPrompt];
    [FDAutolayoutHelper setHeight:50 forView:starRatingView inView:self.CSATPrompt];
    [FDAutolayoutHelper centerX:starRatingView onView:self.CSATPrompt];
    [FDAutolayoutHelper centerY:starRatingView onView:self.CSATPrompt].constant = -20;
}

- (IBAction)didChangeValue:(HCSStarRatingView *)sender {
    self.rating = sender.value;
}

-(void)submitButtonPressed{
    NSLog(@"User rated %d stars \n feedback: %@", (int)self.rating, self.feedbackView.text);
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return (touch.view == self.transparentView);
}

-(void)tappedOutsidePrompt{
    [self dismiss];
}

-(void)show{
    self.transparentView.hidden = NO;
    self.CSATPrompt.hidden = NO;
}

-(void)dismiss{
    self.transparentView.hidden = YES;
    self.CSATPrompt.hidden = YES;
}

@end
