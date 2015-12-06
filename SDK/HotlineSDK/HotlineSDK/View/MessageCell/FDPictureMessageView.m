//
//  FDPictureMessageUnit.m
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 30/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDPictureMessageView.h"
#import "FDMessageCell.h"
#define KONOTOR_PICTURE_TAG 89

#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET_IMESSAGECALLOUT
#define KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET_IMESSAGECALLOUT 14

@implementation FDPictureMessageView

- (void) setUpPictureMessageInteractionsForMessage:(KonotorMessageData*)currentMessage withMessageWidth:(float)messageWidth{
    self.message=currentMessage;
    [self setHidden:NO];
    
    CGSize picSize=[FDPictureMessageView getSizeForImageFromMessage:currentMessage];
    
    float height=picSize.height;
    float imgwidth=picSize.width;
    
    TapOnPictureRecognizer* tapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
    tapGesture.numberOfTapsRequired=1;
    if([currentMessage picData]){
        tapGesture.image=[UIImage imageWithData:[currentMessage picData]];
    }
    else{
        tapGesture.imageURL=[NSURL URLWithString:[currentMessage picUrl]];
        tapGesture.image=nil;
    }
    tapGesture.height=[[currentMessage picHeight] floatValue];
    tapGesture.width=[[currentMessage picWidth] floatValue];
    self.userInteractionEnabled=YES;
    
    if([currentMessage picThumbData]){
        UIImage *picture=[UIImage imageWithData:[currentMessage picThumbData]];
        [self setFrame:CGRectMake((messageWidth-imgwidth)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, 8, imgwidth, height)];
        [self setImage:picture];
        
        if(![currentMessage picData]){
            dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(q, ^{
                /* Fetch the image from the server... */
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[currentMessage picUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(data){
                        [Konotor setBinaryImage:data forMessageId:[currentMessage messageId]];
                        currentMessage.picData=data;
                        self.layer.cornerRadius=10.0;
                        self.layer.masksToBounds=YES;
                        self.tag=KONOTOR_PICTURE_TAG;
                        TapOnPictureRecognizer* tapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
                        tapGesture.numberOfTapsRequired=1;
                        if(data)
                            tapGesture.image=[UIImage imageWithData:data];
                        else{
                            tapGesture.imageURL=[NSURL URLWithString:[currentMessage picUrl]];
                            tapGesture.image=nil;
                        }
                        tapGesture.height=[[currentMessage picHeight] floatValue];
                        tapGesture.width=[[currentMessage picWidth] floatValue];
                        self.userInteractionEnabled=YES;
                    }
                });
            });
            
        }
    }
    else{
        if(height>100)
            [self setFrame:CGRectMake((messageWidth-110)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, (height-100)/2, 110, 100)];
        else{
            [self setFrame:CGRectMake((messageWidth-height*110/100)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, 8, height*110/100, height)];
        }
        [self setImage:[UIImage imageNamed:@"konotor_placeholder"]];
        
        dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(q, ^{
            /* Fetch the image from the server... */
            NSData *thumbData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[currentMessage picThumbUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(thumbData){
                    [Konotor setBinaryImageThumbnail:thumbData forMessageId:[currentMessage messageId]];
                    currentMessage.picThumbData=thumbData;
                    UIImage *img = [[UIImage alloc] initWithData:thumbData];
                    
                    /* This is the main thread again, where we set the image to
                     be what we just fetched. */
                    [self setFrame:CGRectMake((messageWidth-imgwidth)/2-KONOTOR_MESSAGE_BACKGROUND_IMAGE_LEFT_INSET/2, 8, imgwidth, height)];
                    [self setImage:img];
                }
            });
            
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[currentMessage picUrl] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(data){
                    [Konotor setBinaryImage:data forMessageId:[currentMessage messageId]];
                    currentMessage.picData=data;
                    self.layer.cornerRadius=10.0;
                    self.layer.masksToBounds=YES;
                    self.tag=KONOTOR_PICTURE_TAG;
                    TapOnPictureRecognizer* tapGesture=[[TapOnPictureRecognizer alloc] initWithTarget:self action:@selector(tappedOnPicture:)];
                    tapGesture.numberOfTapsRequired=1;
                    if(data)
                        tapGesture.image=[UIImage imageWithData:data];
                    else{
                        tapGesture.imageURL=[NSURL URLWithString:[currentMessage picUrl]];
                        tapGesture.image=nil;
                    }
                    tapGesture.height=[[currentMessage picHeight] floatValue];
                    tapGesture.width=[[currentMessage picWidth] floatValue];
                    self.userInteractionEnabled=YES;
                    NSArray* gestureRecognizers=[self gestureRecognizers];
                    for(UIGestureRecognizer* gr in gestureRecognizers){
//                        if([gr isKindOfClass:[TapOnPictureRecognizer class]])
//                            [self removeGestureRecognizer:gr];
                    }
                 //   [self addGestureRecognizer:tapGesture];
                    
                }
            });
        });
    }
}

+ (CGSize) getSizeForImageFromMessage:(KonotorMessageData*) message{
    CGSize picSize=CGSizeZero;
    
    float height=MIN([[message picThumbHeight] floatValue],KONOTOR_IMAGE_MAXHEIGHT);
    float imgwidth=[[message picThumbWidth] floatValue];
    if(height!=[[message picThumbHeight] floatValue]){
        imgwidth=[[message picThumbWidth] floatValue]*(height/[[message picThumbHeight] floatValue]);
    }
    if(imgwidth>KONOTOR_IMAGE_MAXWIDTH)
    {
        imgwidth=KONOTOR_IMAGE_MAXWIDTH;
        height=[[message picThumbHeight] floatValue]*(imgwidth/[[message picThumbWidth] floatValue]);
    }
    picSize.width=imgwidth;
    picSize.height=height;
    
    return picSize;
}

@end