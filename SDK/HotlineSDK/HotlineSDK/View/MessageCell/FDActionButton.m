//
//  FDActionButton.m
//  HotlineSDK
//
//  Created by Srikrishnan Ganesan on 27/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDActionButton.h"
#import "FDMessageCell.h"
#import "HLArticleDetailViewController.h"

@implementation FDActionButton

@synthesize actionUrlString,articleID;

- (void) setUpStyle
{
    float padding = 10;
    [self setFrame:CGRectZero];
    [self setContentEdgeInsets:UIEdgeInsetsMake(padding/8, padding/2, padding/8, padding/2)];
    self.layer.cornerRadius=10.0;
    [self setBackgroundColor:[UIColor darkGrayColor]];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
}

- (void) setupWithLabel:(NSString*)actionLabel frame:(CGRect)messageFrame
{
    float messageFrameWidth=messageFrame.size.width;
    float messageFrameHeight=messageFrame.size.height;
    float messageOriginX=messageFrame.origin.x;
    float messageOriginY=messageFrame.origin.y;
    float horizontalPadding=KONOTOR_HORIZONTAL_PADDING*3;
    float percentWidth=0.5;
    float padding = 10;
    float maxButtonWidth =messageFrameWidth-horizontalPadding*2;
    
    UIFont *actionLabelFont=KONOTOR_MESSAGETEXT_FONT;
    
    if([actionLabel isEqualToString:@""]||(actionLabel==nil))
        actionLabel=KONOTOR_BUTTON_DEFAULTACTIONLABEL;
    
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:actionLabelFont];
    [txtView setText:actionLabel];
    CGSize labelSize=[txtView sizeThatFits:CGSizeMake(messageFrameWidth, KONOTOR_ACTIONBUTTON_HEIGHT)];
    
    float labelWidth=padding + 20+labelSize.width;
    float buttonWidth=MAX(MIN(labelWidth, maxButtonWidth), maxButtonWidth*percentWidth);
    
    float buttonXCenterAlign=messageOriginX-horizontalPadding/3.0+(messageFrameWidth-buttonWidth)/2;
    
    if([FDMessageCell hasButtonForURL:actionUrlString articleID:articleID]){
        self.articleID=articleID;
        self.actionUrlString=actionUrlString;
        [self setFrame:CGRectMake(buttonXCenterAlign,
                                          messageOriginY+messageFrameHeight,
                                          buttonWidth,
                                          KONOTOR_ACTIONBUTTON_HEIGHT)];
        [self setHidden:NO];
   
        [self setAttributedTitle:
         [[NSAttributedString alloc] initWithString:actionLabel attributes:[NSDictionary dictionaryWithObjectsAndKeys:actionLabelFont,NSFontAttributeName,[UIColor whiteColor],NSForegroundColorAttributeName,nil]] forState:UIControlStateNormal];
    }
    else{
        [self setHidden:YES];
    }
    
}

@end
