//
//  FDResolvedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"
#import "FCTheme.h"

@protocol HLYesNoPromptViewDelegate <NSObject>

-(void)yesButtonClicked:(id)sender;
-(void)noButtonClicked:(id)sender;

@end

@interface FDYesNoPromptView : FDPromptView

@property (nonatomic, strong) FCTheme *theme;
@property (strong, nonatomic) UILabel *promptLabel;
@property (nonatomic, strong) UIButton *YesButton;
@property (nonatomic, strong) UIButton *NoButton;

@property (nonatomic,weak) id<HLYesNoPromptViewDelegate> delegate;
-(instancetype)initWithDelegate:(id<HLYesNoPromptViewDelegate>) delegate andKey:(NSString *)key;

@end
