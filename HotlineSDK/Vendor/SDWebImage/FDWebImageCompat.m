/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "FDWebImageCompat.h"

#import "objc/runtime.h"

#if !__has_feature(objc_arc)
#error FDWebImage is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

inline UIImage *FDScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    
#if FD_MAC
    return image;
#elif FD_UIKIT || FD_WATCH
    if ((image.images).count > 0) {
        NSMutableArray<UIImage *> *scaledImages = [NSMutableArray array];

        for (UIImage *tempImage in image.images) {
            [scaledImages addObject:FDScaledImageForKey(key, tempImage)];
        }
        
        UIImage *animatedImage = [UIImage animatedImageWithImages:scaledImages duration:image.duration];
#ifdef FD_WEBP
        if (animatedImage) {
            SEL fd_webpLoopCount = NSSelectorFromString(@"fd_webpLoopCount");
            NSNumber *value = objc_getAssociatedObject(image, fd_webpLoopCount);
            NSInteger loopCount = value.integerValue;
            if (loopCount) {
                objc_setAssociatedObject(animatedImage, fd_webpLoopCount, @(loopCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
#endif
        return animatedImage;
    } else {
#if FD_WATCH
        if ([[WKInterfaceDevice currentDevice] respondsToSelector:@selector(screenScale)]) {
#elif FD_UIKIT
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
#endif
            CGFloat scale = 1;
            if (key.length >= 8) {
                NSRange range = [key rangeOfString:@"@2x."];
                if (range.location != NSNotFound) {
                    scale = 2.0;
                }
                
                range = [key rangeOfString:@"@3x."];
                if (range.location != NSNotFound) {
                    scale = 3.0;
                }
            }

            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }
        return image;
    }
#endif
}

NSString *const FDWebImageErrorDomain = @"FDWebImageErrorDomain";
