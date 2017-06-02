//
//  BNCNetworkService.m
//  Branch-SDK
//
//  Created by Edward Smith on 5/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCNetworkService.h"
#import "BNCLog.h"

#pragma mark BNCNetworkOperation

@interface BNCNetworkOperation ()
@property (copy)   NSURLRequest       *request;
@property (copy)   NSHTTPURLResponse  *response;
@property (strong) NSData             *responseData;
@property (copy)   NSError            *error;
@property (strong) NSDate             *dateStart;
@property (strong) NSDate             *dateFinish;

@property (strong) BNCNetworkService  *networkService;
@property (strong) NSURLSessionTask   *sessionTask;
@property (copy) void (^completionBlock)(BNCNetworkOperation*operation);
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService () <NSURLSessionDelegate, NSURLSessionTaskDelegate> {
    NSURLSession *_session;
}

- (void) startOperation:(BNCNetworkOperation*)operation;

@property (strong, readonly) NSURLSession *session;
@property (strong) NSOperationQueue *sessionQueue;
@end

#pragma mark - BNCNetworkOperation

@implementation BNCNetworkOperation

- (void) start {
    [self.networkService startOperation:self];
}

- (void) cancel {
    [self.sessionTask cancel];
}

- (NSString*) stringFromResponseData {
    NSString *string = nil;
    if ([self.responseData isKindOfClass:[NSData class]]) {
        string = [[NSString alloc] initWithData:(NSData*)self.responseData encoding:NSUTF8StringEncoding];
    }
    if (!string && [self.responseData isKindOfClass:[NSData class]]) {
        string = [NSString stringWithFormat:@"<NSData of length %ld.>",
            (long)[(NSData*)self.responseData length]];
    }
    if (!string) {
        string = self.responseData.description;
    }
    return string;
}

@end

#pragma mark - BNCNetworkService

@implementation BNCNetworkService

+ (id<BNCNetworkServiceProtocol>) new {
    return [[self alloc] init];
}

- (instancetype) init {
    self = [super init];
    return self;
}

- (NSURLSession*) session {
    @synchronized (self) {
        if (_session) return _session;

        NSURLSessionConfiguration *configuration =
            [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 60.0;
        configuration.timeoutIntervalForResource = 60.0;
        configuration.URLCache =
            [[NSURLCache alloc]
                initWithMemoryCapacity:20*1024*1024
                diskCapacity:200*1024*1024
                diskPath:@"io.branch.network.cache"];

        self.sessionQueue = [NSOperationQueue new];
        self.sessionQueue.name = @"io.branch.network.queue";
        self.sessionQueue.maxConcurrentOperationCount = 3;
        self.sessionQueue.qualityOfService = NSQualityOfServiceUserInteractive;

        _session =
            [NSURLSession sessionWithConfiguration:configuration
                delegate:self
                delegateQueue:self.sessionQueue];
        _session.sessionDescription = @"io.branch.network.session";

        return _session;
    }
}

- (void) setMaximumConcurrentOperations:(NSInteger)maximumConcurrentOperations {
    @synchronized (self) {
        maximumConcurrentOperations = MAX(maximumConcurrentOperations, 0);
        self.sessionQueue.maxConcurrentOperationCount = maximumConcurrentOperations;
    }
}

- (NSInteger) maximumConcurrentOperations {
    @synchronized (self) {
        return self.sessionQueue.maxConcurrentOperationCount;
    }
}

- (void) setSuspendOperations:(BOOL)suspendOperations {
    self.sessionQueue.suspended = suspendOperations;
}

- (BOOL) operationsAreSuspended {
    return self.sessionQueue.isSuspended;
}

- (BNCNetworkOperation*) networkOperationWithURLRequest:(NSURLRequest*)request
                completion:(void (^)(BNCNetworkOperation*operation))completion {

    BNCNetworkOperation *operation = [BNCNetworkOperation new];
    operation.request = request;
    operation.networkService = self;
    operation.completionBlock = completion;
    return operation;
}

- (void) startOperation:(BNCNetworkOperation*)operation {
    operation.networkService = self;
    if (!operation.dateStart)
        operation.dateStart = [NSDate date];
    operation.sessionTask =
        [self.session dataTaskWithRequest:operation.request
            completionHandler:
            ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                operation.responseData = data;
                operation.response = (NSHTTPURLResponse*) response;
                operation.error = error;
                operation.dateFinish = [NSDate date];
                BNCLogDebug(@"Network finish operation %@ %1.3fs. Status %ld error %@.\n%@.",
                    operation.request.URL.absoluteString,
                    [operation.dateFinish timeIntervalSinceDate:operation.dateStart],
                    (long)operation.response.statusCode,
                    operation.error,
                    operation.stringFromResponseData);
                if (operation.completionBlock)
                    operation.completionBlock(operation);
            }];
    BNCLogDebug(@"Network start operation %@.", operation.request.URL);
    [operation.sessionTask resume];
}

- (void) cancelAllOperations {
    [self.session invalidateAndCancel];
    _session = nil;
}

@end
