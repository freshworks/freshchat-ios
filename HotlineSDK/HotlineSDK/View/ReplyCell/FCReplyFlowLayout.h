//
//  FCReplyFlowLayout.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 21/08/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FCReplyDelegate <NSObject>
@required
-(CGSize) getSizeforRow:(int)row;
-(void) setCollectionViewHeight:(CGFloat) height;
@end

@interface FCReplyFlowLayout : UICollectionViewFlowLayout

@property(nonatomic, weak) id<FCReplyDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

