//
//  FDResolvedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"

@protocol FDYesNoPromptViewDelegate <NSObject>

-(void)yesButtonClicked:(id)sender;
-(void)noButtonClicked:(id)sender;

@end

@interface FDYesNoPromptView : FDPromptView

@property (nonatomic,strong) id<FDYesNoPromptViewDelegate> delegate;
-(instancetype)initWithDelegate:(id<FDYesNoPromptViewDelegate>) delegate andKey:(NSString *)key;

@end