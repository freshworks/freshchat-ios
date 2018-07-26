//
//  HLEmptyResultView.h
//  HotlineSDK
//
//  Created by Harish Kumar on 08/03/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

enum SupportType {
    SOLUTIONS  = 1,
    CONVERSATION = 2
};

@interface FCEmptyResultView : UIView

@property (strong, nonatomic) UIImageView *emptyResultImage;
@property (strong, nonatomic) UILabel *emptyResultLabel;

-(id)initWithImage:(UIImage *)image withType:(enum SupportType)solType andText:(NSString *)text;

@end
