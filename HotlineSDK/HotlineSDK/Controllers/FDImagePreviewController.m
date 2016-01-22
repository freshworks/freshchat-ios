//
//  FDImagePreviewController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 04/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDImagePreviewController.h"
#import "HLTheme.h"

@interface FDImagePreviewController (){
    CGFloat beginX, beginY;
    CGFloat scrollZoomScale;
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, assign) CGSize originalBounds;

- (void)centerScrollViewContents;
- (void)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer;

@end

static const CGFloat THROWING_THRESHOLD = 1600;

@implementation FDImagePreviewController

@synthesize scrollView = _scrollView, imageView = _imageView;

-(instancetype)initWithImage:(UIImage *)image{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    
    UIImage *image = self.image;
    self.imageView = [[UIImageView alloc]initWithImage:image];
    self.imageView.frame = (CGRect){.origin=CGPointMake(0.0f, 0.0f), .size=image.size};
    
    [self.scrollView addSubview:self.imageView];
    self.scrollView.delegate = self;
    
    self.originalCenter = self.scrollView.center;
    self.scrollView.clipsToBounds = YES;
    
    self.scrollView.contentSize = image.size;
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDoubleTapped:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTapRecognizer];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImage:)];
    panGesture.delegate = self;
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    [self.scrollView addGestureRecognizer:panGesture];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton addTarget:self
               action:@selector(dismissImagePicPreview)
     forControlEvents:UIControlEventTouchUpInside];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setImage:[[HLTheme sharedInstance] getImageWithKey:IMAGE_CLOSE_PREVIEW] forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    
    NSDictionary *views = @{ @"closeBtn" :closeButton, @"scrollView" :self.scrollView, @"imageView" :self.imageView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[closeBtn(20)]-15-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-15-[closeBtn(20)]" options:0 metrics:nil views:views]];

}

-(void)presentOnController:(UIViewController *)controller{
    [controller presentViewController:self animated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGRect scrollViewFrame = self.scrollView.frame;
    CGFloat scaleWidth = scrollViewFrame.size.width / self.scrollView.contentSize.width;
    CGFloat scaleHeight = scrollViewFrame.size.height / self.scrollView.contentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    
    self.scrollView.minimumZoomScale = minScale;
    self.scrollView.maximumZoomScale = 4.0f;
    self.scrollView.zoomScale = minScale;
    
    self.originalBounds = self.scrollView.contentSize;
    
    [self centerScrollViewContents];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)moveImage:(UIPanGestureRecognizer *)recognizer{
    
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    
    CGPoint newCenter = [recognizer translationInView:self.imageView];
    
    if([recognizer state] == UIGestureRecognizerStateBegan) {
        beginX = self.imageView.center.x;
        beginY = self.imageView.center.y;
    }
    
    newCenter = CGPointMake(beginX + newCenter.x, beginY + newCenter.y);
    
    [self.imageView setCenter:newCenter];
    
    if([recognizer state] == UIGestureRecognizerStateEnded){
        
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        
        if ( lroundf(self.originalBounds.height) == lroundf(self.scrollView.contentSize.height)) {
            NSLog(@"state ended");
            
            if (magnitude > THROWING_THRESHOLD){
                
                if (velocity.y >0)   // panning down
                {
                    NSLog (@"down");
                    [UIView animateWithDuration:.2 delay:0.0
                                        options: UIViewAnimationCurveEaseIn
                                     animations:^{
                                         self.imageView.frame = CGRectMake(0, self.view.frame.size.height+self.imageView.frame.size.height, 0, 0);
                                     }
                                     completion:^(BOOL finished){
                                         if (finished){
                                             self.imageView.hidden = YES;
                                             //                                                 [self.imageView removeFromSuperview];
                                             [self dismissModalViewControllerAnimated:NO];
                                         }
                                     }];
                    
                }
                else                // panning up
                {
                    NSLog (@"up");
                    [UIView animateWithDuration:.5 delay:0.0
                                        options: UIViewAnimationCurveEaseIn animations:^{
                                            self.imageView.frame = CGRectMake(self.imageView.frame.origin.x, -(self.view.frame.size.height+self.imageView.frame.size.height), 0, 0);
                                        }
                                     completion:^(BOOL finished){
                                         if (finished){
                                             self.imageView.hidden = YES;
                                             //                                                [self.imageView removeFromSuperview];
                                             [self dismissModalViewControllerAnimated:NO];
                                         }
                                     }];
                }
            }
            else{
                [self.imageView setCenter:self.scrollView.center];
            }
        }
        
    }
    
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that we want to zoom
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // The scroll view has zoomed, so we need to re-center the contents
    [self centerScrollViewContents];
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.imageView.frame = contentsFrame;
}

- (void)scrollViewDoubleTapped:(UITapGestureRecognizer*)recognizer {
    // Get the location within the image view where we tapped
    
    if ((int)self.originalBounds.height == (int)self.scrollView.contentSize.height) {
        CGPoint pointInView = [recognizer locationInView:self.imageView];
        
        // Get a zoom scale that's zoomed in slightly, capped at the maximum zoom scale specified by the scroll view
        CGFloat newZoomScale = self.scrollView.zoomScale * 1.7f;
        newZoomScale = MIN(newZoomScale, self.scrollView.maximumZoomScale);
        
        // Figure out the rect we want to zoom to, then zoom to it
        CGSize scrollViewSize = self.scrollView.bounds.size;
        
        CGFloat w = scrollViewSize.width / newZoomScale;
        CGFloat h = scrollViewSize.height / newZoomScale;
        CGFloat x = pointInView.x - (w / 2.0f);
        CGFloat y = pointInView.y - (h / 2.0f);
        
        CGRect rectToZoomTo = CGRectMake(x, y, w, h);
        
        [self.scrollView zoomToRect:rectToZoomTo animated:YES];
    }
    else{
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale];
    }
}

-(void)didChangeOrientation:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        NSLog(@"Landscape");
        [self performSelector:@selector(centerScrollViewContents) withObject:nil afterDelay:0.01f];
        //[self centerScrollViewContents];
    }
    else {
        NSLog(@"potrait ... ");
       // [self centerScrollViewContents];
        [self performSelector:@selector(centerScrollViewContents) withObject:nil afterDelay:0.01f];
    }
}

-(void) dismissImagePicPreview{
    
    [self dismissModalViewControllerAnimated:YES];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

@end