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
#import "HLLocalization.h"

@implementation FDActionButton

@synthesize actionUrlString,articleID;

- (void) setUpStyle
{
    float padding = 10;
    [self setFrame:CGRectZero];
    [self setContentEdgeInsets:UIEdgeInsetsMake(padding/8, padding/2, padding/8, padding/2)];
    self.layer.cornerRadius=5.0;
    [self setBackgroundColor:[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0]];
    self.layer.borderColor=[[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0] CGColor];
    self.layer.borderWidth=0.5;
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
        actionLabel=HLLocalizedString(LOC_DEFAULT_ACTION_BUTTON_TEXT);
    
    UITextView* txtView=[[UITextView alloc] init];
    [txtView setFont:actionLabelFont];
    [txtView setText:actionLabel];
    CGSize labelSize=[txtView sizeThatFits:CGSizeMake(messageFrameWidth, KONOTOR_ACTIONBUTTON_HEIGHT)];
    
    float labelWidth=padding + 20+labelSize.width;
    float buttonWidth=MIN(labelWidth, maxButtonWidth);//MAX(MIN(labelWidth, maxButtonWidth), maxButtonWidth*percentWidth);
    
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
         [[NSAttributedString alloc] initWithString:actionLabel attributes:[NSDictionary dictionaryWithObjectsAndKeys:actionLabelFont,NSFontAttributeName,[UIColor blackColor],NSForegroundColorAttributeName,nil]] forState:UIControlStateNormal];
    }
    else{
        [self setHidden:YES];
    }
    
}

@end
