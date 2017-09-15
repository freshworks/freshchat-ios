/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "FDWebImageDownloader.h"
#import "FDWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

@implementation FDWebImageDownloadToken
@end


@interface FDWebImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;
@property (weak, nonatomic, nullable) NSOperation *lastAddedOperation;
@property (assign, nonatomic, nullable) Class operationClass;
@property (strong, nonatomic, nonnull) NSMutableDictionary<NSURL *, FDWebImageDownloaderOperation *> *URLOperations;
@property (strong, nonatomic, nullable) FDHTTPHeadersMutableDictionary *HTTPHeaders;
// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (FDDispatchQueueSetterSementics, nonatomic, nullable) dispatch_queue_t barrierQueue;

// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation FDWebImageDownloader

+ (void)initialize {
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"FDNetworkActivityIndicator")) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"FDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:FDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:FDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:FDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:FDWebImageDownloadStopNotification object:nil];
    }
}

+ (nonnull instancetype)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (nonnull instancetype)init {
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration {
    if ((self = [super init])) {
        _operationClass = [FDWebImageDownloaderOperation class];
        _shouldDecompressImages = YES;
        _executionOrder = FDWebImageDownloaderFIFOExecutionOrder;
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"com.hackemist.FDWebImageDownloader";
        _URLOperations = [NSMutableDictionary new];
#ifdef FD_WEBP
        _HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
#else
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
        _barrierQueue = dispatch_queue_create("com.hackemist.FDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;

        [self createNewSessionWithConfiguration:sessionConfiguration];
    }
    return self;
}

- (void)createNewSessionWithConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    [self cancelAllDownloads];

    if (self.session) {
        [self.session invalidateAndCancel];
    }

    sessionConfiguration.timeoutIntervalForRequest = self.downloadTimeout;

    /**
     *  Create the session for this task
     *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
     *  method calls and completion handler calls.
     */
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;

    [self.downloadQueue cancelAllOperations];
    FDDispatchQueueRelease(_barrierQueue);
}

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field {
    if (value) {
        self.HTTPHeaders[field] = value;
    } else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field {
    return self.HTTPHeaders[field];
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount;
}

- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

- (NSURLSessionConfiguration *)sessionConfiguration {
    return self.session.configuration;
}

- (void)setOperationClass:(nullable Class)operationClass {
    if (operationClass && [operationClass isSubclassOfClass:[NSOperation class]] && [operationClass conformsToProtocol:@protocol(FDWebImageDownloaderOperationInterface)]) {
        _operationClass = operationClass;
    } else {
        _operationClass = [FDWebImageDownloaderOperation class];
    }
}

- (nullable FDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
                                                   options:(FDWebImageDownloaderOptions)options
                                                  progress:(nullable FDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(nullable FDWebImageDownloaderCompletedBlock)completedBlock {
    __weak FDWebImageDownloader *wself = self;

    return [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^FDWebImageDownloaderOperation *{
        __strong __typeof (wself) sself = wself;
        NSTimeInterval timeoutInterval = sself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }

        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        NSURLRequestCachePolicy cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        if (options & FDWebImageDownloaderUseNSURLCache) {
            if (options & FDWebImageDownloaderIgnoreCachedResponse) {
                cachePolicy = NSURLRequestReturnCacheDataDontLoad;
            } else {
                cachePolicy = NSURLRequestUseProtocolCachePolicy;
            }
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
        
        request.HTTPShouldHandleCookies = (options & FDWebImageDownloaderHandleCookies);
        request.HTTPShouldUsePipelining = YES;
        if (sself.headersFilter) {
            request.allHTTPHeaderFields = sself.headersFilter(url, [sself.HTTPHeaders copy]);
        }
        else {
            request.allHTTPHeaderFields = sself.HTTPHeaders;
        }
        FDWebImageDownloaderOperation *operation = [[sself.operationClass alloc] initWithRequest:request inSession:sself.session options:options];
        operation.shouldDecompressImages = sself.shouldDecompressImages;
        
        if (sself.urlCredential) {
            operation.credential = sself.urlCredential;
        } else if (sself.username && sself.password) {
            operation.credential = [NSURLCredential credentialWithUser:sself.username password:sself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        if (options & FDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & FDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        }

        [sself.downloadQueue addOperation:operation];
        if (sself.executionOrder == FDWebImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            [sself.lastAddedOperation addDependency:operation];
            sself.lastAddedOperation = operation;
        }

        return operation;
    }];
}

- (void)cancel:(nullable FDWebImageDownloadToken *)token {
    dispatch_barrier_async(self.barrierQueue, ^{
        FDWebImageDownloaderOperation *operation = self.URLOperations[token.url];
        BOOL canceled = [operation cancel:token.downloadOperationCancelToken];
        if (canceled) {
            [self.URLOperations removeObjectForKey:token.url];
        }
    });
}

- (nullable FDWebImageDownloadToken *)addProgressCallback:(FDWebImageDownloaderProgressBlock)progressBlock
                                           completedBlock:(FDWebImageDownloaderCompletedBlock)completedBlock
                                                   forURL:(nullable NSURL *)url
                                           createCallback:(FDWebImageDownloaderOperation *(^)())createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return nil;
    }

    __block FDWebImageDownloadToken *token = nil;

    dispatch_barrier_sync(self.barrierQueue, ^{
        FDWebImageDownloaderOperation *operation = self.URLOperations[url];
        if (!operation) {
            operation = createCallback();
            self.URLOperations[url] = operation;

            __weak FDWebImageDownloaderOperation *woperation = operation;
            operation.completionBlock = ^{
				dispatch_barrier_sync(self.barrierQueue, ^{
					FDWebImageDownloaderOperation *soperation = woperation;
					if (!soperation) return;
					if (self.URLOperations[url] == soperation) {
						[self.URLOperations removeObjectForKey:url];
					};
				});
            };
        }
        id downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock completed:completedBlock];

        token = [FDWebImageDownloadToken new];
        token.url = url;
        token.downloadOperationCancelToken = downloadOperationCancelToken;
    });

    return token;
}

- (void)setSuspended:(BOOL)suspended {
    self.downloadQueue.suspended = suspended;
}

- (void)cancelAllDownloads {
    [self.downloadQueue cancelAllOperations];
}

#pragma mark Helper methods

- (FDWebImageDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
    FDWebImageDownloaderOperation *returnOperation = nil;
    for (FDWebImageDownloaderOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    FDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {

    // Identify the operation that runs this task and pass it the delegate method
    FDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    FDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Identify the operation that runs this task and pass it the delegate method
    FDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];

    [dataOperation URLSession:session task:task didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    FDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];

    [dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
}

@end
