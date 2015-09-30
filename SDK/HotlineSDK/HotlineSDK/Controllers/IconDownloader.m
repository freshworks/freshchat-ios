
#import "IconDownloader.h"

@interface IconDownloader ()

@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@end

@implementation IconDownloader

- (void)startDownload{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.category.iconURL]];
    self.sessionTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil){
            if ([error code] == NSURLErrorAppTransportSecurityRequiresSecureConnection){
                abort();
            }
        }
                                                       
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            self.category.icon = data;
            if (self.completionHandler != nil){
                self.completionHandler();
            }
        }];
    }];
    [self.sessionTask resume];
}

- (void)cancelDownload{
    [self.sessionTask cancel];
    self.sessionTask = nil;
}

@end