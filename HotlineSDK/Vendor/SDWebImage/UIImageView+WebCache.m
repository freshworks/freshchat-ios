/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"

#if FD_UIKIT || FD_MAC

#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"

@implementation UIImageView (WebCache)

- (void)fd_setImageWithURL:(nullable NSURL *)url {
    [self fd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(FDWebImageOptions)options {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(FDWebImageOptions)options completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(FDWebImageOptions)options
                  progress:(nullable FDWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:nil
                            progress:progressBlock
                           completed:completedBlock];
}

- (void)fd_setImageWithPreviousCachedImageWithURL:(nullable NSURL *)url
                                 placeholderImage:(nullable UIImage *)placeholder
                                          options:(FDWebImageOptions)options
                                         progress:(nullable FDWebImageDownloaderProgressBlock)progressBlock
                                        completed:(nullable FDExternalCompletionBlock)completedBlock {
    NSString *key = [[FDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[FDImageCache sharedImageCache] imageFromCacheForKey:key];
    
    [self fd_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];
}

#if FD_UIKIT

#pragma mark - Animation of multiple images

- (void)fd_setAnimationImagesWithURLs:(nonnull NSArray<NSURL *> *)arrayOfURLs {
    [self fd_cancelCurrentAnimationImagesLoad];
    __weak __typeof(self)wself = self;

    NSMutableArray<id<FDWebImageOperation>> *operationsArray = [[NSMutableArray alloc] init];

    [arrayOfURLs enumerateObjectsUsingBlock:^(NSURL *logoImageURL, NSUInteger idx, BOOL * _Nonnull stop) {
        id <FDWebImageOperation> operation = [FDWebImageManager.sharedManager loadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, FDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_async_safe(^{
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image) {
                    NSMutableArray<UIImage *> *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    
                    // We know what index objects should be at when they are returned so
                    // we will put the object at the index, filling any empty indexes
                    // with the image that was returned too "early". These images will
                    // be overwritten. (does not require additional sorting datastructure)
                    while ([currentImages count] < idx) {
                        [currentImages addObject:image];
                    }
                    
                    currentImages[idx] = image;

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        [operationsArray addObject:operation];
    }];

    [self fd_setImageLoadOperation:[operationsArray copy] forKey:@"UIImageViewAnimationImages"];
}

- (void)fd_cancelCurrentAnimationImagesLoad {
    [self fd_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}
#endif

@end

#endif
