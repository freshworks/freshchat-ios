//
//  FDUserInfoField.h
//  FreshdeskSDK
//
//  Created by Arvchz on 27/05/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Mobihelp.h"

@interface FDUserInfoForm : UIView

-(instancetype)initWithName:(NSString *)name withEmail:(NSString *)email andFeedBackType:(FEEDBACK_TYPE)feedbackType;
-(NSString *)getUserName;
-(NSString *)getEmailAddress;
-(BOOL)isValid;

@end
