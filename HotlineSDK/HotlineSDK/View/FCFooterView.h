//
//  FCFooterView.h
//  FreshchatSDK
//
//  Created by user on 04/12/17.
//  Copyright © 2017 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCFooterView : UIView

@property (nonatomic, strong) UIView *footerBgView;
@property (nonatomic, strong) UILabel *footerLabel;

- (instancetype)initFooterViewWithEmbedded :(BOOL)isEmbed;
- (void)setViewColor:(UIColor*) color;
@end
