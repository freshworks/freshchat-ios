//
//  FDClosedPromptView.h
//  FreshdeskSDK
//
//  Created by Arvchz on 23/02/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import "FDPromptView.h"

@protocol FDAlertViewDelegate <NSObject>

-(void)buttonClickedEvent:(id)sender;

@end

@interface FDAlertView : FDPromptView

-(instancetype)initWithDelegate:(id <FDAlertViewDelegate>)delegate andKey:(NSString *)key;

@end
