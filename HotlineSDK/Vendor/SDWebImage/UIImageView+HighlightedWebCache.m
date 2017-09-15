/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+HighlightedWebCache.h"

#if FD_UIKIT

#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"

@implementation UIImageView (HighlightedWebCache)

- (void)fd_setHighlightedImageWithURL:(nullable NSURL *)url {
    [self fd_setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)fd_setHighlightedImageWithURL:(nullable NSURL *)url options:(FDWebImageOptions)options {
    [self fd_setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)fd_setHighlightedImageWithURL:(nullable NSURL *)url completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setHighlightedImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)fd_setHighlightedImageWithURL:(nullable NSURL *)url options:(FDWebImageOptions)options completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setHighlightedImageWithURL:url options:options progress:nil completed:completedBlock];
}

- (void)fd_setHighlightedImageWithURL:(nullable NSURL *)url
                              options:(FDWebImageOptions)options
                             progress:(nullable FDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable FDExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self fd_internalSetImageWithURL:url
                    placeholderImage:nil
                             options:options
                        operationKey:@"UIImageViewImageOperationHighlighted"
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           weakSelf.highlightedImage = image;
                       }
                            progress:progressBlock
                           completed:completedBlock];
}

@end

#endif
