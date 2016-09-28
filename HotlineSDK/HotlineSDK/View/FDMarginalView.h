//
//  FDMarginalView.h
//  HotlineSDK
//
//  Created by user on 28/10/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLTheme.h"

@class FDMarginalView;

@protocol FDMarginalViewDelegate <NSObject>

-(void)marginalView:(FDMarginalView*)marginalView handleTap:(id)sender;

@end

@interface FDMarginalView : UIView

-(id)initWithDelegate:(id <FDMarginalViewDelegate>)delegate;

@property (nonatomic,weak) id<FDMarginalViewDelegate> delegate;

@end
