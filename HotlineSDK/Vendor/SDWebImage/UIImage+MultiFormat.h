/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "FDWebImageCompat.h"
#import "NSData+ImageContentType.h"

@interface UIImage (MultiFormat)

+ (nullable UIImage *)fd_imageWithData:(nullable NSData *)data;
- (nullable NSData *)fd_imageData;
- (nullable NSData *)fd_imageDataAsFormat:(FDImageFormat)imageFormat;

@end
