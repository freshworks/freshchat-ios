//
//  FCReplyFlowLayout.m
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 21/08/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

#import "FCReplyFlowLayout.h"

@interface FCReplyFlowLayout()

@property(nonatomic) CGFloat contentHeight;
@property(nonatomic, strong) NSMutableArray<UICollectionViewLayoutAttributes *> * attributesForElementsInRect;
@end

@implementation FCReplyFlowLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if(self.attributesForElementsInRect) {
        return self.attributesForElementsInRect;
    }
    NSArray<UICollectionViewLayoutAttributes *> * attributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray<UICollectionViewLayoutAttributes *> * newAttributesForElementsInRect = [NSMutableArray new];
    CGFloat leftMargin = self.minimumInteritemSpacing;
    CGFloat height = self.minimumLineSpacing;
    CGFloat maxHeight = 0.0;
    for(int i=0; i< attributesForElementsInRect.count; i++) {
        UICollectionViewLayoutAttributes *attribute = attributesForElementsInRect[i];
        CGSize size = [self.delegate getSizeforRow:i];
        if (size.width < 50) {
            size.width = 50;
        }
        size= CGSizeMake(size.width + 16 , size.height + 16);
        if (leftMargin == self.minimumInteritemSpacing) {
            leftMargin = self.minimumInteritemSpacing;
            CGRect newFrame = attribute.frame;
            newFrame.origin.x = leftMargin;
            newFrame.origin.y = height;
            newFrame.size= size;
            attribute.frame = newFrame;
            leftMargin += attribute.frame.size.width + self.minimumInteritemSpacing;
            maxHeight = attribute.frame.size.height + self.minimumLineSpacing;
        } else {
            CGRect newFrame = attribute.frame;
            newFrame.origin.x = leftMargin;
            newFrame.size= size;
            if (newFrame.origin.x + newFrame.size.width + self.minimumInteritemSpacing > self.collectionView.frame.size.width) {
                newFrame.origin.x = self.minimumInteritemSpacing;
                height += maxHeight;
                newFrame.origin.y = height;
                leftMargin = newFrame.origin.x + newFrame.size.width +  self.minimumInteritemSpacing;
            } else {
                newFrame.origin.x = leftMargin;
                newFrame.origin.y = height;
                leftMargin += newFrame.size.width + self.minimumInteritemSpacing;
            }
            if(maxHeight < newFrame.size.height + self.minimumLineSpacing + height) {
                maxHeight = newFrame.size.height + self.minimumLineSpacing;
            }
            attribute.frame = newFrame;
        }
        
        [newAttributesForElementsInRect addObject:attribute];
    }
    if (newAttributesForElementsInRect.lastObject) {
        self.contentHeight = newAttributesForElementsInRect.lastObject.frame.size.height + newAttributesForElementsInRect.lastObject.frame.origin.y + self.minimumLineSpacing;
        self.collectionView.contentSize =  CGSizeMake(self.collectionView.frame.size.width, self.contentHeight);
        [self.delegate setCollectionViewHeight:self.contentHeight];
    } else {
        self.contentHeight = 0.0;
    }
    self.attributesForElementsInRect = newAttributesForElementsInRect;
    return newAttributesForElementsInRect;
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.frame.size.width, self.contentHeight);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    return attributes;
}

- (void)prepareLayout{
    [super prepareLayout];
    self.attributesForElementsInRect = nil;
}

@end
