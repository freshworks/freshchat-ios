/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCache.h"

#if FD_UIKIT || FD_MAC

#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"

static char imageURLKey;

#if FD_UIKIT
static char TAG_ACTIVITY_INDICATOR;
static char TAG_ACTIVITY_STYLE;
#endif
static char TAG_ACTIVITY_SHOW;

@implementation UIView (WebCache)

- (nullable NSURL *)fd_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)fd_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(FDWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
                     setImageBlock:(nullable FDSetImageBlock)setImageBlock
                          progress:(nullable FDWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable FDExternalCompletionBlock)completedBlock {
    NSString *validOperationKey = operationKey ?: NSStringFromClass([self class]);
    [self fd_cancelImageLoadOperationWithKey:validOperationKey];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (!(options & FDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            [self fd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock];
        });
    }
    
    if (url) {
        // check if activityView is enabled or not
        if ([self fd_showActivityIndicatorView]) {
            [self fd_addActivityIndicator];
        }
        
        __weak __typeof(self)wself = self;
        id <FDWebImageOperation> operation = [FDWebImageManager.sharedManager loadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSData *data, NSError *error, FDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            __strong __typeof (wself) sself = wself;
            [sself fd_removeActivityIndicator];
            if (!sself) {
                return;
            }
            dispatch_main_async_safe(^{
                if (!sself) {
                    return;
                }
                if (image && (options & FDWebImageAvoidAutoSetImage) && completedBlock) {
                    completedBlock(image, error, cacheType, url);
                    return;
                } else if (image) {
                    [sself fd_setImage:image imageData:data basedOnClassOrViaCustomSetImageBlock:setImageBlock];
                    [sself fd_setNeedsLayout];
                } else {
                    if ((options & FDWebImageDelayPlaceholder)) {
                        [sself fd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock];
                        [sself fd_setNeedsLayout];
                    }
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        [self fd_setImageLoadOperation:operation forKey:validOperationKey];
    } else {
        dispatch_main_async_safe(^{
            [self fd_removeActivityIndicator];
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:FDWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
                completedBlock(nil, error, FDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)fd_cancelCurrentImageLoad {
    [self fd_cancelImageLoadOperationWithKey:NSStringFromClass([self class])];
}

- (void)fd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(FDSetImageBlock)setImageBlock {
    if (setImageBlock) {
        setImageBlock(image, imageData);
        return;
    }
    
#if FD_UIKIT || FD_MAC
    if ([self isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)self;
        imageView.image = image;
    }
#endif
    
#if FD_UIKIT
    if ([self isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)self;
        [button setImage:image forState:UIControlStateNormal];
    }
#endif
}

- (void)fd_setNeedsLayout {
#if FD_UIKIT
    [self setNeedsLayout];
#elif FD_MAC
    [self setNeedsLayout:YES];
#endif
}

#pragma mark - Activity indicator

#pragma mark -
#if FD_UIKIT
- (UIActivityIndicatorView *)activityIndicator {
    return (UIActivityIndicatorView *)objc_getAssociatedObject(self, &TAG_ACTIVITY_INDICATOR);
}

- (void)setActivityIndicator:(UIActivityIndicatorView *)activityIndicator {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_INDICATOR, activityIndicator, OBJC_ASSOCIATION_RETAIN);
}
#endif

- (void)fd_setShowActivityIndicatorView:(BOOL)show {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_SHOW, @(show), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)fd_showActivityIndicatorView {
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_SHOW) boolValue];
}

#if FD_UIKIT
- (void)fd_setIndicatorStyle:(UIActivityIndicatorViewStyle)style{
    objc_setAssociatedObject(self, &TAG_ACTIVITY_STYLE, [NSNumber numberWithInt:style], OBJC_ASSOCIATION_RETAIN);
}

- (int)fd_getIndicatorStyle{
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_STYLE) intValue];
}
#endif

- (void)fd_addActivityIndicator {
#if FD_UIKIT
    dispatch_main_async_safe(^{
        if (!self.activityIndicator) {
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[self fd_getIndicatorStyle]];
            self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        
            [self addSubview:self.activityIndicator];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                              constant:0.0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:0.0]];
        }
        [self.activityIndicator startAnimating];
    });
#endif
}

- (void)fd_removeActivityIndicator {
#if FD_UIKIT
    dispatch_main_async_safe(^{
        if (self.activityIndicator) {
            [self.activityIndicator removeFromSuperview];
            self.activityIndicator = nil;
        }
    });
#endif
}

@end

#endif
