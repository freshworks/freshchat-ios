/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "MKAnnotationView+WebCache.h"

#if FD_UIKIT || FD_MAC

#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"

@implementation MKAnnotationView (WebCache)

- (void)fd_setImageWithURL:(nullable NSURL *)url {
    [self fd_setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(FDWebImageOptions)options {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)fd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable FDExternalCompletionBlock)completedBlock {
    [self fd_setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}


- (void)fd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(FDWebImageOptions)options
                 completed:(nullable FDExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self fd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           weakSelf.image = image;
                       }
                            progress:nil
                           completed:completedBlock];
}

@end

#endif
