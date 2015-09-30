#import "HLCategory.h"
#import <UIKit/UIKit.h>

@interface IconDownloader : NSObject

@property (nonatomic, strong) HLCategory *category;
@property (nonatomic, copy) void (^completionHandler)(void);

- (void)startDownload;
- (void)cancelDownload;

@end
