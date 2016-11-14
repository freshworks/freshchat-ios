//
//  FDGrowingTextView.h
//  HotlineSDK
//
//  Created by user on 14/11/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FDGrowingTextviewDelegate <NSObject>

-(void)FDGrowingTextViewKe:(NSDictionary *)info;

@end


@interface FDGrowingTextView : UITextView

@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;

@end
