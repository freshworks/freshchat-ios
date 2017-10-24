//
//  HLCSATView.m
//  HotlineSDK
//
//  Created by user on 17/10/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import "HLCSATView.h"
#import "HLStarRatingView.h"
#import "FDAutolayoutHelper.h"
#import "FCTheme.h"
#import "FDGrowingTextView.h"
#import "HLLocalization.h"

@interface HLCSATView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *transparentView;
@property (nonatomic, strong) UIView *CSATPrompt;
@property (nonatomic, strong) FDGrowingTextView *feedbackView;
@property (nonatomic) float rating;
@property (nonatomic, strong) FCTheme *theme;
@property (nonatomic, strong) UIButton *submitButton;


@end

@implementation HLCSATView

- (instancetype)initWithController:(UIViewController *)controller hideFeedbackView:(BOOL)hideFeedbackView isResolved:(BOOL)isResolved{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        
        self.isResolved = isResolved;
        self.theme = [FCTheme sharedInstance];
        
        //Transparent background view
        self.transparentView  = [UIView new];
        self.transparentView.translatesAutoresizingMaskIntoConstraints = NO;
        self.transparentView.backgroundColor =  [UIColor colorWithWhite:0.5 alpha:0.5];
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOutsidePrompt)];
        singleTap.delegate = self;
        singleTap.numberOfTapsRequired = 1;
        [self.transparentView addGestureRecognizer:singleTap];
        [controller.view addSubview:self.transparentView];

        //CSAT prompt
        self.CSATPrompt = [UIView new];
        self.CSATPrompt.translatesAutoresizingMaskIntoConstraints = NO;
        self.CSATPrompt.backgroundColor = self.theme.csatPromptBackgroundColor;
        self.CSATPrompt.center = self.transparentView.center;
        self.CSATPrompt.layer.cornerRadius = 15;
        [self.transparentView addSubview:self.CSATPrompt];
        
        UIView *starRatingView = [self createStarRatingView];
        [self.CSATPrompt addSubview:starRatingView];
        
        //Survey title
        self.surveyTitle = [UILabel new];
        self.surveyTitle.font = self.theme.csatPromptQuestionTextFont;
        self.surveyTitle.textColor = self.theme.csatPromptQuestionTextFontColor;
        self.surveyTitle.numberOfLines = 3;
        self.surveyTitle.textAlignment = NSTextAlignmentCenter;
        self.surveyTitle.translatesAutoresizingMaskIntoConstraints = NO;
        #if DEBUG
            self.surveyTitle.accessibilityIdentifier = @"lblSurveyTitle";
        #endif
        [self.CSATPrompt addSubview:self.surveyTitle];
        
        //Submit button
        self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.submitButton setTitleColor:self.theme.csatPromptSubmitButtonColor forState:UIControlStateNormal];
        self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.submitButton setTitle:HLLocalizedString(LOC_CUST_SAT_SUBMIT_BUTTON_TEXT) forState:(UIControlStateNormal)];
        [self.submitButton addTarget:self action:@selector(submitButtonPressed) forControlEvents:(UIControlEventTouchUpInside)];
        self.submitButton.backgroundColor = [self.theme csatPromptSubmitButtonBackgroundColor];
        [self.submitButton.titleLabel setFont:[self.theme csatPromptSubmitButtonTitleFont]];
        #if DEBUG
        self.submitButton.accessibilityIdentifier = @"btnFeedbackSubmit";
        #endif
        [self.CSATPrompt addSubview:self.submitButton];
        
        //Feedback textview
        self.feedbackView = [FDGrowingTextView new];
        self.feedbackView.placeholder = HLLocalizedString(LOC_CUST_SAT_USER_COMMENTS_PLACEHOLDER);
        self.feedbackView.opaque = NO;
        self.feedbackView.alpha = 0.7;
        self.feedbackView.font = self.theme.csatPromptInputTextFont;
        self.feedbackView.textColor = self.theme.csatPromptInputTextFontColor;
        self.feedbackView.layer.borderWidth = 0.5;
        self.feedbackView.layer.borderColor =  self.theme.csatPromptInputTextBorderColor.CGColor;
        self.feedbackView.translatesAutoresizingMaskIntoConstraints = NO;
        #if DEBUG
        self.feedbackView.accessibilityIdentifier = @"txtFeedback";
        #endif
        [self.CSATPrompt addSubview:self.feedbackView];
        
        //Horizontal line
        UIView *horizontalLine = [UIView new];
        horizontalLine.opaque = NO;
        horizontalLine.alpha = 0.3;
        horizontalLine.backgroundColor = self.theme.csatPromptHorizontalLineColor;
        horizontalLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self.CSATPrompt addSubview:horizontalLine];
        
        //Layout constraints
        NSDictionary *views = @{@"survey_title" : self.surveyTitle, @"submit_button" : self.submitButton,
                                @"horizontal_line" : horizontalLine, @"feedback_view" : self.feedbackView,
                                @"superview" : controller.view, @"transparent_view" : self.transparentView,
                                @"star_rating_view" : starRatingView};
        
        //Transparent view constraints
        [controller.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[transparent_view]|" options:0 metrics:nil views:views]];
        [controller.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[transparent_view]|" options:0 metrics:nil views:views]];
        
        //CSAT prompt constraints
        [FDAutolayoutHelper setWidth:280 forView:self.CSATPrompt inView:self.transparentView];
        [FDAutolayoutHelper centerX:self.CSATPrompt onView:self.transparentView];
        self.CSATPromptCenterYConstraint = [FDAutolayoutHelper centerY:self.CSATPrompt onView:self.transparentView];
        
        //CSAT prompt subviews
        [FDAutolayoutHelper setWidth:150 forView:starRatingView inView:self.CSATPrompt];
        [FDAutolayoutHelper setWidth:240 forView:self.surveyTitle inView:self.CSATPrompt];
        [FDAutolayoutHelper setWidth:240 forView:self.feedbackView inView:self.CSATPrompt];
        [self.CSATPrompt addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[horizontal_line]|" options:0 metrics:nil views:views]];
        
        CGFloat promptHeight, ratingbarHeight, feedbackviewHeight = 0;
        
        if (isResolved) {
            ratingbarHeight = 40;
            if (hideFeedbackView) {
                promptHeight = 150;
                feedbackviewHeight = 0;
            }else{
                promptHeight = 200;
                feedbackviewHeight = 50;
            }
            [self enableSubmitButton:NO];
       }else{
           ratingbarHeight = 0;
           promptHeight = 170;
           feedbackviewHeight = 50;
           [self enableSubmitButton:YES];
       }
        
        NSDictionary *metrics = @{@"feedbackview_height": @(feedbackviewHeight), @"ratingbar_height" : @(ratingbarHeight) };

        [FDAutolayoutHelper setHeight:promptHeight forView:self.CSATPrompt inView:self.transparentView];
        
        [self.CSATPrompt addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[survey_title(50)][star_rating_view(<=ratingbar_height@900)]-10-[feedback_view(<=feedbackview_height@500)]-[horizontal_line(1)]-8-[submit_button(20)]-8-|" options:NSLayoutFormatAlignAllCenterX metrics:metrics views:views]];
        
        //Initial view config
        self.transparentView.hidden = YES;
        self.CSATPrompt.hidden = YES;
    }
    return self;
}

-(void)enableSubmitButton:(BOOL)state{
    self.submitButton.enabled = state;
    if (state) {
        [self.submitButton setTitleColor:[self.theme csatPromptSubmitButtonColor] forState:UIControlStateNormal];
    }else{
        [self.submitButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }

}

-(UIView *)createStarRatingView{
    HLStarRatingView *starRatingView = [HLStarRatingView new];
    starRatingView.backgroundColor = self.theme.csatPromptBackgroundColor;
    starRatingView.translatesAutoresizingMaskIntoConstraints = NO;
    starRatingView.maximumValue = 5;
    starRatingView.minimumValue = 0;
    starRatingView.value = 0;
    starRatingView.tintColor = self.theme.csatPromptRatingBarColor;
    [starRatingView addTarget:self action:@selector(didChangeValue:) forControlEvents:UIControlEventValueChanged];
    return starRatingView;
}

- (IBAction)didChangeValue:(HLStarRatingView *)sender {
    if (sender.value > 0) {
        self.rating = sender.value;
        [self enableSubmitButton:YES];
    }else{
        [self enableSubmitButton:NO];
    }
}

-(void)submitButtonPressed{
    if (self.delegate) {
        
        HLCsatHolder *csatHolder = [[HLCsatHolder alloc]init];
        
        csatHolder.isIssueResolved = self.isResolved;
        
        if (self.rating > 0) {
            csatHolder.userRatingCount = self.rating;
        }
        
        if (self.feedbackView.text && ![self.feedbackView.text isEqualToString:@""]) {
            csatHolder.userComments = self.feedbackView.text;
        }
        [self.delegate submittedCSAT:csatHolder];
    }
    [self dismiss];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return (touch.view == self.transparentView);
}

//Submit CSAT without user input
-(void)tappedOutsidePrompt{
    if (self.delegate) {
        [self.delegate handleUserEvadedCSAT];
    }
    [self dismiss];
}

-(BOOL)isShowing{
    return !self.CSATPrompt.hidden;
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
