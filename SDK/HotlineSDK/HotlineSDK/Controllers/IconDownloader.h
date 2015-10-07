#import "HLCategory.h"
#import <UIKit/UIKit.h>

@interface IconDownloader : NSObject

@property (nonatomic,strong) NSString *iconURL;
@property (nonatomic, copy) void (^completionHandler)(NSData *imageData);

- (void)startDownload;
- (void)cancelDownload;

@end
