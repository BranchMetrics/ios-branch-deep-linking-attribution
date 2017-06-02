//
//  BNCNetworkService.m
//  Branch-SDK
//
//  Created by Edward Smith on 5/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCNetworkService.h"
#import "BNCEncodingUtils.h"
#import "BNCLog.h"
#import "BNCDebug.h"

#pragma mark BNCNetworkOperation

@interface BNCNetworkOperation ()
@property (copy)   NSMutableURLRequest*request;
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
    NSURLSession    *_session;
    NSTimeInterval  _defaultTimeoutInterval;
    NSInteger       _maximumConcurrentOperations;
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
    if (!self) return self;
    _defaultTimeoutInterval = 60.0;
    _maximumConcurrentOperations = 3;
    return self;
}

#pragma mark - Setters & Getters

- (void) setDefaultTimeoutInterval:(NSTimeInterval)defaultTimeoutInterval {
    @synchronized (self) {
        _defaultTimeoutInterval = MAX(defaultTimeoutInterval, 0.0);
    }
}

- (NSTimeInterval) defaultTimeoutInterval {
    @synchronized (self) {
        return _defaultTimeoutInterval;
    }
}

- (void) setMaximumConcurrentOperations:(NSInteger)maximumConcurrentOperations {
    @synchronized (self) {
        _maximumConcurrentOperations = MAX(maximumConcurrentOperations, 0);
        self.sessionQueue.maxConcurrentOperationCount = _maximumConcurrentOperations;
    }
}

- (NSInteger) maximumConcurrentOperations {
    @synchronized (self) {
        return _maximumConcurrentOperations;
    }
}

- (NSURLSession*) session {
    @synchronized (self) {
        if (_session) return _session;

        NSURLSessionConfiguration *configuration =
            [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = self.defaultTimeoutInterval;
        configuration.timeoutIntervalForResource = self.defaultTimeoutInterval;
        configuration.URLCache = nil;

        self.sessionQueue = [NSOperationQueue new];
        self.sessionQueue.name = @"io.branch.network.queue";
        self.sessionQueue.maxConcurrentOperationCount = self.maximumConcurrentOperations;
        self.sessionQueue.qualityOfService = NSQualityOfServiceUserInteractive;

        _session =
            [NSURLSession sessionWithConfiguration:configuration
                delegate:self
                delegateQueue:self.sessionQueue];
        _session.sessionDescription = @"io.branch.network.session";

        return _session;
    }
}

- (void) setSuspendOperations:(BOOL)suspendOperations {
    self.sessionQueue.suspended = suspendOperations;
}

- (BOOL) operationsAreSuspended {
    return self.sessionQueue.isSuspended;
}

#pragma mark - Operations

- (BNCNetworkOperation*) networkOperationWithURLRequest:(NSMutableURLRequest*)request
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
    if (!operation.timeoutDate) {
        operation.timeoutDate =
            [[operation dateStart] dateByAddingTimeInterval:self.defaultTimeoutInterval];
    }
    operation.request.timeoutInterval = [operation.timeoutDate timeIntervalSinceDate:[NSDate date]];
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

- (void) URLSession:(NSURLSession *)session
               task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    BOOL trusted = NO;
    uint8_t kNonce[] = "Branch Rocks";
    uint8_t encryptedString[2048];
    size_t encryptedLength = sizeof(encryptedString);
    SecTrustResultType trustResult = 0;
    OSStatus err = 0;
    NSData *data = nil;
    NSString *string = nil;
    NSString *hostName = nil;

    // Release these:
    SecKeyRef key = nil;
    SecPolicyRef hostPolicy = nil;

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wobjc-string-concatenation"
    NSArray<NSString*> *encodedNonces = @[
        @"BD26E0318889E71233FD5570D6FCAF111CF2C8F7793C67DC4CF2101142B2F581AB5695FDB4EE8F2DFF561311"
         "AE3C025447ACE3BEB0CD9A14C4CDF56F15DBD37C371B1598A4172BF7E386709FC60AEEF7ED72B37C3C5226E0"
         "618EA7B2224E019B44161A4A6CCEE929A4F6C3B61C06CBAA0E38C572192442CB1921A97CB7FA358A26974D35"
         "986AFDC108B6E052C8176DED421F9DBDBD7963D7146208AC3EA378F8AACDDE65287A5A9815C18F3D02CDFB98"
         "523C65357FC7F633F26755F64FFFBFC03B444ACF169564D17CD80A7976B5665AD3645DAC931257CE5759BD9A"
         "608C981BF38694293C0F9F6CBA7E2707642D87FF6B2A7EE26B62A52646620BADA70A11A5",
    ];
    #pragma clang diagnostic pop

    // Get remote certificate
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;

    // Set SSL policies for domain name check
    hostPolicy = SecPolicyCreateSSL(true, (__bridge CFStringRef)challenge.protectionSpace.host);
    if (!hostPolicy) goto exit;
    SecTrustSetPolicies(serverTrust, (__bridge CFTypeRef _Nonnull)(@[ (__bridge id)hostPolicy ]));

    // TODO: SecTrustEvaluate is not thread safe. This is a temporary fix.
    @synchronized (self.class) {
        // Evaluate server certificate
        SecTrustEvaluate(serverTrust, &trustResult);
        if (! (trustResult == kSecTrustResultUnspecified || trustResult == kSecTrustResultProceed)) {
            goto exit;
        }
    }

    hostName = task.originalRequest.URL.host;
    if (![hostName hasSuffix:@"branch.io"]) {
        trusted = YES;
        goto exit;
    }

    key = SecTrustCopyPublicKey(serverTrust);
    if (!key) goto exit;
    err = SecKeyEncrypt(key, kSecPaddingNone, kNonce, sizeof(kNonce), encryptedString, &encryptedLength);
    if (err)  goto exit;

    data = [NSData dataWithBytes:encryptedString length:encryptedLength];
    string = [BNCEncodingUtils hexStringFromData:data];
    for (NSString* encodedNonce in encodedNonces) {
        if ([string isEqualToString:encodedNonce]) {
            trusted = YES;
            goto exit;
        }
    }

exit:
    if (err) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        BNCLogError(@"Error while validating cert: %@.", error);
    }
    if (key) CFRelease(key);
    if (hostPolicy) CFRelease(hostPolicy);

    if (trusted) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    }
}

@end
