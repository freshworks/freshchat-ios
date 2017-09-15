/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "FDWebImageCompat.h"

#if FD_UIKIT || FD_MAC

#import "FDWebImageManager.h"

@interface UIView (WebCacheOperation)

/**
 *  Set the image load operation (storage in a UIView based dictionary)
 *
 *  @param operation the operation
 *  @param key       key for storing the operation
 */
- (void)fd_setImageLoadOperation:(nullable id)operation forKey:(nullable NSString *)key;

/**
 *  Cancel all operations for the current UIView and key
 *
 *  @param key key for identifying the operations
 */
- (void)fd_cancelImageLoadOperationWithKey:(nullable NSString *)key;

/**
 *  Just remove the operations corresponding to the current UIView and key without cancelling them
 *
 *  @param key key for identifying the operations
 */
- (void)fd_removeImageLoadOperationWithKey:(nullable NSString *)key;

@end

#endif
