//
//  FDClosedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FCPromptView.h"

@protocol FCAlertViewDelegate <NSObject>

-(void)buttonClickedEvent:(id)sender;

@end

@interface FCAlertView : FCPromptView

@property (nonatomic, strong) UIButton *Button1;
@property (nonatomic, strong) UILabel *promptLabel;

-(instancetype)initWithDelegate:(id <FCAlertViewDelegate>)delegate andKey:(NSString *)key;

@end
