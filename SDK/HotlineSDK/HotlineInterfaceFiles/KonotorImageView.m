//
//  KonotorImageView.m
//  KonotorDemo
//
//  Created by Srikrishnan Ganesan on 12/05/14.
//  Copyright (c) 2014 Demach. All rights reserved.
//

#import "KonotorImageView.h"
#import "KonotorTextInputOverlay.h"

@implementation KonotorImageView
@synthesize imageView,backgroundView,sourceViewController,img,imgURL,imgHeight,imgWidth;

- (void) rotateToOrientation:(UIInterfaceOrientation) orientation duration:(NSTimeInterval) duration
{
    float screenHeight,screenWidth,height,width;
    height=imgHeight;width=imgWidth;

#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0)
    if(UIInterfaceOrientationIsPortrait(orientation)||(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")))
#else
        if(YES)
#endif
        {
        screenHeight=[UIScreen mainScreen].bounds.size.height;
        screenWidth=[UIScreen mainScreen].bounds.size.width;
    }
    else{
        screenHeight=[UIScreen mainScreen].bounds.size.width;
        screenWidth=[UIScreen mainScreen].bounds.size.height;
        
    }
    [self setFrame:CGRectMake(0,0, screenWidth, screenHeight)];
    [backgroundView setFrame:CGRectMake(0,0, screenWidth, screenHeight)];
    
    if(height>(screenHeight-50))
    {
        width=width*(screenHeight-50)/height;
        height=screenHeight-50;
        
    }
    if(width>screenWidth){
        height=height*screenWidth/width;
        width=screenWidth;
    }
    
    if(imageView.frame.size.height>100){
        [imageView setFrame:CGRectMake((screenWidth-width)/2, 50+(screenHeight-50-height)/2, width, height)];
    }
    else{
        if(height>100)
            [imageView setFrame:CGRectMake((screenWidth-110)/2, (screenHeight-100)/2, 110, 100)];
        else{
            [imageView setFrame:CGRectMake((screenWidth-height*110/100)/2, 50+(screenHeight-50-height)/2, height*110/100, height)];
        }
    }

}


- (void) showImageView
{
    float screenHeight, screenWidth, height, width;
    height=imgHeight;width=imgWidth;
    
    [KonotorTextInputOverlay dismissInput];
    
    [[sourceViewController navigationController] setNavigationBarHidden:YES animated:NO];

    
    if(![KonotorUtility KonotorIsInterfaceLandscape:(sourceViewController)]){
        screenHeight=[UIScreen mainScreen].bounds.size.height;
        screenWidth=[UIScreen mainScreen].bounds.size.width;
    }
    else{
        screenHeight=[UIScreen mainScreen].bounds.size.width;
        screenWidth=[UIScreen mainScreen].bounds.size.height;
        
    }

    [self setFrame:CGRectMake(0,0, screenWidth, screenHeight)];

    [self.sourceViewController.view.superview addSubview:self];
    
    backgroundView=[[UIView alloc] initWithFrame:CGRectMake(0,0, screenWidth, screenHeight)];
    [backgroundView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9]];
    [self addSubview:backgroundView];
    UIButton *closeButton=[UIButton buttonWithType:UIButtonTypeCustom];
    if([[KonotorUIParameters sharedInstance] closeButtonImage])
        [closeButton setImage:[[KonotorUIParameters sharedInstance] closeButtonImage] forState:UIControlStateNormal];
    else
        [closeButton setImage:[UIImage imageNamed:@"konotor_back"] forState:UIControlStateNormal];
    [closeButton setFrame:CGRectMake(2, 12, 36, 36)];
    [closeButton addTarget:sourceViewController action:@selector(dismissImageView) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:closeButton];
    
    if(height>(screenHeight-50))
    {
        width=width*(screenHeight-50)/height;
        height=screenHeight-50;
        
    }
    if(width>screenWidth){
        height=height*screenWidth/width;
        width=screenWidth;
    }
    
    imageView=[[UIImageView alloc] init];
    [self addSubview:imageView];
    if(img){
        
        [imageView setFrame:CGRectMake((screenWidth-width)/2, 50+(screenHeight-50-height)/2, width, height)];
        [imageView setImage:img];
        return;
    }
    
    if(height>100)
        [imageView setFrame:CGRectMake((screenWidth-110)/2, (screenHeight-100)/2, 110, 100)];
    else{
        [imageView setFrame:CGRectMake((screenWidth-height*110/100)/2, 50+(screenHeight-50-height)/2, height*110/100, height)];
    }
    [imageView setImage:[UIImage imageNamed:@"konotor_placeholder"]];
    
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(q, ^{
        /* Fetch the image from the server... */
        NSData *imgData = [NSData dataWithContentsOfURL:imgURL];
        UIImage *imgFromURL = [[UIImage alloc] initWithData:imgData];
        dispatch_async(dispatch_get_main_queue(), ^{
            /* This is the main thread again, where we set the image to
             be what we just fetched. */
            float screenHeight, screenWidth, height, width;
            height=imgHeight;width=imgWidth;
            
            if(![KonotorUtility KonotorIsInterfaceLandscape:sourceViewController]){
                screenHeight=[UIScreen mainScreen].bounds.size.height;
                screenWidth=[UIScreen mainScreen].bounds.size.width;
            }
            else{
                screenHeight=[UIScreen mainScreen].bounds.size.width;
                screenWidth=[UIScreen mainScreen].bounds.size.height;
                
            }
            
            if(height>(screenHeight-50))
            {
                width=width*(screenHeight-50)/height;
                height=screenHeight-50;
                
            }
            if(width>screenWidth){
                height=height*screenWidth/width;
                width=screenWidth;
            }


            [imageView setFrame:CGRectMake((screenWidth-width)/2, 50+(screenHeight-50-height)/2, width, height)];
            [imageView setImage:imgFromURL];
        });
        
    });

}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return imageView;
}




@end
