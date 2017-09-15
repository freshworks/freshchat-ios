/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSData+ImageContentType.h"


@implementation NSData (ImageContentType)

+ (FDImageFormat)fd_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return FDImageFormatUndefined;
    }
    
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return FDImageFormatJPEG;
        case 0x89:
            return FDImageFormatPNG;
        case 0x47:
            return FDImageFormatGIF;
        case 0x49:
        case 0x4D:
            return FDImageFormatTIFF;
        case 0x52:
            // R as RIFF for WEBP
            if (data.length < 12) {
                return FDImageFormatUndefined;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return FDImageFormatWebP;
            }
    }
    return FDImageFormatUndefined;
}

@end
