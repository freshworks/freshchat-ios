//
//  FDImagePreviewController.m
//  HotlineSDK
//
//  Created by Aravinth Chandran on 04/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDImagePreviewController.h"

@interface FDImagePreviewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) UIAttachmentBehavior *attachmentBehavior;
@property (nonatomic) UIPushBehavior *pushBehavior;
@property (nonatomic) UIDynamicItemBehavior *itemBehavior;

@property (nonatomic, assign) CGRect originalBounds;
@property (nonatomic, assign) CGPoint originalCenter;


@end

static const CGFloat ThrowingThreshold = 700;
static const CGFloat ThrowingVelocityPadding = 175;

@implementation FDImagePreviewController

-(instancetype)initWithImage:(UIImage *)image{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.imageView = [[UIImageView alloc]initWithImage:self.image];
    self.imageView.frame = CGRectMake(self.view.center.x, self.view.center.y, 300, 300);
    self.imageView.center = self.view.center;
    self.imageView.clipsToBounds = YES;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.layer.allowsEdgeAntialiasing = YES;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.originalBounds = self.imageView.bounds;
    self.originalCenter = self.imageView.center;

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // creat and configure the pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDetected:)];
    [panGestureRecognizer setDelegate:self];
    [self.imageView addGestureRecognizer:panGestureRecognizer];
    
    // create and configure the pinch gesture
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureDetected:)];
    [pinchGestureRecognizer setDelegate:self];
    [self.imageView addGestureRecognizer:pinchGestureRecognizer];
    
    // create and configure the rotation gesture
    UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGestureDetected:)];
    [rotationGestureRecognizer setDelegate:self];
    [self.imageView addGestureRecognizer:rotationGestureRecognizer];
    
    [self.view addSubview:self.imageView];
}

-(void)presentOnController:(UIViewController *)controller{
    [controller presentViewController:self animated:NO completion:nil];
}

- (void)pinchGestureDetected:(UIPinchGestureRecognizer *)recognizer{
    UIGestureRecognizerState state = [recognizer state];
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged){
        CGFloat scale = [recognizer scale];
        [recognizer.view setTransform:CGAffineTransformScale(recognizer.view.transform, scale, scale)];
        [recognizer setScale:1.0];
    }
}

- (void)rotationGestureDetected:(UIRotationGestureRecognizer *)recognizer{
    UIGestureRecognizerState state = [recognizer state];
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged){
        CGFloat rotation = [recognizer rotation];
        [recognizer.view setTransform:CGAffineTransformRotate(recognizer.view.transform, rotation)];
        [recognizer setRotation:0];
    }
}


- (void)panGestureDetected:(UIPanGestureRecognizer *)recognizer{
    
    
    [self.attachmentBehavior setAnchorPoint:[recognizer locationInView:self.view]];
    
    CGPoint location = [recognizer locationInView:self.view];
    CGPoint boxLocation = [recognizer locationInView:self.imageView];
    UIOffset centerOffset = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.imageView.bounds),
                                         boxLocation.y - CGRectGetMidY(self.imageView.bounds));
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:{
            [self.animator removeAllBehaviors];
            
            
            self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.imageView
                                                                offsetFromCenter:centerOffset
                                                                attachedToAnchor:location];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            
            [self.animator removeBehavior:self.attachmentBehavior];
            CGPoint velocity = [recognizer velocityInView:self.imageView];
            CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
            
            if (magnitude > ThrowingThreshold) {
                UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.imageView] mode:UIPushBehaviorModeInstantaneous];
                pushBehavior.pushDirection = CGVectorMake((velocity.x / 10) , (velocity.y / 10));
                
                pushBehavior.pushDirection = CGVectorMake(velocity.x*0.1, velocity.y*0.1);
                
                [pushBehavior setTargetOffsetFromCenter:centerOffset forItem:self.imageView];

                pushBehavior.action = ^{
                    [self.animator removeAllBehaviors];
                    self.attachmentBehavior = nil;
                    [self performSelector:@selector(throw) withObject:nil afterDelay:0.2];
                };

                [self.animator addBehavior:pushBehavior];

                
                pushBehavior.magnitude = magnitude / ThrowingVelocityPadding;
                
                self.pushBehavior = pushBehavior;
                [self.animator addBehavior:self.pushBehavior];
                
                NSInteger angle = arc4random_uniform(20) - 10;
                
                self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.imageView]];
                self.itemBehavior.friction = 0.2;
                self.itemBehavior.allowsRotation = YES;
                
                [self.itemBehavior addAngularVelocity:angle forItem:self.imageView];
                [self.animator addBehavior:self.itemBehavior];
                
            }else{
                [self reset];
            }
        }
        default:
            [self.animator addBehavior:self.attachmentBehavior];
            break;
    }
}

-(void)reset{
    [self.animator removeAllBehaviors];
    [UIView animateWithDuration:0.45 animations:^{
        self.imageView.bounds = self.originalBounds;
        self.imageView.center = self.originalCenter;
        self.imageView.transform = CGAffineTransformIdentity;
    }];
}

-(void)throw{
    [self.imageView removeFromSuperview];
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end