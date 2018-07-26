//
//  FDMarginalView.h
//  HotlineSDK
//
//  Created by user on 28/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCTheme.h"

@class FCMarginalView;

@protocol FDMarginalViewDelegate <NSObject>

-(void)marginalView:(FCMarginalView*)marginalView handleTap:(id)sender;

@end

@interface FCMarginalView : UIView

-(id)initWithDelegate:(id <FDMarginalViewDelegate>)delegate;

@property (nonatomic,weak) id<FDMarginalViewDelegate> delegate;

@end
