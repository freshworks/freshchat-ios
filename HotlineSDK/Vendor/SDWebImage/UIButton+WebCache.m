/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+WebCache.h"

#if FD_UIKIT

#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"

static char imageURLStorageKey;

typedef NSMutableDictionary<NSNumber *, NSURL *> FDStateImageURLDictionary;

@implementation UIButton (WebCache)

- (nullable NSURL *)fd_currentImageURL {
    NSURL *url = self.imageURLStorage[@(self.state)];

    if (!url) {
        url = self.imageURLStorage[@(UIControlStateNormal)];
    }

    return url;
}

- (nullable NSURL *)fd_imageURLForState:(UIControlState)state {
    return self.imageURLStorage[@(state)];
}

#pragma mark - Image

- (void)fd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self fd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self fd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(FDWebImageOptions)options {
    [self fd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
          placeholderImage:(nullable UIImage *)placeholder
                   options:(FDWebImageOptions)options
                 completed:(nullable FDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:@(state)];
        return;
    }
    
    self.imageURLStorage[@(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self fd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

#pragma mark - Background image

- (void)fd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self fd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)fd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self fd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)fd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(FDWebImageOptions)options {
    [self fd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)fd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)fd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)fd_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
                    placeholderImage:(nullable UIImage *)placeholder
                             options:(FDWebImageOptions)options
                           completed:(nullable FDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:@(state)];
        return;
    }
    
    self.imageURLStorage[@(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self fd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setBackgroundImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

- (void)fd_setImageLoadOperation:(id<FDWebImageOperation>)operation forState:(UIControlState)state {
    [self fd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)fd_cancelImageLoadForState:(UIControlState)state {
    [self fd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)fd_setBackgroundImageLoadOperation:(id<FDWebImageOperation>)operation forState:(UIControlState)state {
    [self fd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (void)fd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self fd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (FDStateImageURLDictionary *)imageURLStorage {
    FDStateImageURLDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end

#endif
