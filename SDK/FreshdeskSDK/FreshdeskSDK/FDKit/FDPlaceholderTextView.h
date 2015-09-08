//
//  Created by Luka Gabrić.
//  Copyright (c) 2013 Luka Gabrić. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FDPlaceholderTextView : UITextView
{
    UILabel *_placeholderLabel;
}


@property (strong, nonatomic) NSString *placeholderText;
@property (strong, nonatomic) UIColor *placeholderColor;


@end