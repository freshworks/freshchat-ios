//
//  FDCSATView.h
//  HotlineSDK
//
//  Created by user on 17/10/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FDCSATViewDelegate <NSObject>

-(void)submittedCSATWithInfo:(NSDictionary *)info;

@end


@interface FDCSATView : UIView

@property (nonatomic,weak) id<FDCSATViewDelegate> delegate;

- (instancetype)initWithController:(UIViewController *)controller andDelegate:(id <FDCSATViewDelegate>)delegate;
- (void)show;
- (void)dismiss;

@end
