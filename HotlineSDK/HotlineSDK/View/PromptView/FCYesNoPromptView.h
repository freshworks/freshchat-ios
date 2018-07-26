//
//  FDResolvedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCPromptView.h"
#import "FCTheme.h"

@protocol FCYesNoPromptViewDelegate <NSObject>

-(void)yesButtonClicked:(id)sender;
-(void)noButtonClicked:(id)sender;

@end

@interface FCYesNoPromptView : FCPromptView

@property (nonatomic, strong) FCTheme *theme;
@property (strong, nonatomic) UILabel *promptLabel;
@property (nonatomic, strong) UIButton *YesButton;
@property (nonatomic, strong) UIButton *NoButton;

@property (nonatomic,weak) id<FCYesNoPromptViewDelegate> delegate;
-(instancetype)initWithDelegate:(id<FCYesNoPromptViewDelegate>) delegate andKey:(NSString *)key;

@end
