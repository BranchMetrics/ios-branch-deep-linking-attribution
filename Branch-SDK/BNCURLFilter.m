/**
 @file          BNCURLFilter.m
 @package       Branch-SDK
 @brief         Manages a list of URLs that we should ignore.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCURLFilter.h"
#import "Branch.h"

@interface BNCURLFilter () {
    NSArray<NSString*>*_patternList;
}
@property (strong, nonatomic) NSArray<NSRegularExpression*> *ignoredURLRegex;
@property (assign, nonatomic) NSInteger listVersion;
@property (strong, nonatomic) id<BNCNetworkServiceProtocol> networkService;
@property (assign, nonatomic) BOOL hasUpdatedPatternList;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSURL *jsonURL;
@end

@implementation BNCURLFilter

- (instancetype) init {
    self = [super init];
    if (!self) return self;

    self.patternList = @[
        @"^fb\\d+:",
        @"^li\\d+:",
        @"^pdk\\d+:",
        @"^twitterkit-.*:",
        @"^com\\.googleusercontent\\.apps\\.\\d+-.*:\\/oauth",
        @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b",
        @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b",
    ];
    self.listVersion = -1; // First time always refresh the list version, version 0.

    NSArray *storedList = [BNCPreferenceHelper sharedInstance].savedURLPatternList;
    if (storedList.count > 0) {
        self.patternList = storedList;
        self.listVersion = [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion;
    }

    NSError *error = nil;
    _ignoredURLRegex = [self.class compileRegexArray:self.patternList error:&error];
    self.error = error;

    return self;
}

- (void) dealloc {
    [self.networkService cancelAllOperations];
    self.networkService = nil;
}

- (void) setPatternList:(NSArray<NSString *> *)patternList {
    @synchronized (self) {
        _patternList = patternList;
        _ignoredURLRegex = [self.class compileRegexArray:_patternList error:nil];
    }
}

- (NSArray<NSString*>*) patternList {
    @synchronized (self) {
        return _patternList;
    }
}

+ (NSArray<NSRegularExpression*>*) compileRegexArray:(NSArray<NSString*>*)patternList
                                               error:(NSError*_Nullable __autoreleasing *_Nullable)error_ {
    if (error_) *error_ = nil;
    NSMutableArray *array = [NSMutableArray new];
    for (NSString *pattern in patternList) {
        NSError *error = nil;
        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:pattern
                options: NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnicodeWordBoundaries
                error:&error];
        if (error || !regex) {
            BNCLogError([NSString stringWithFormat:@"Invalid regular expression '%@': %@.", pattern, error]);
            if (error_ && !*error_) *error_ = error;
        } else {
            [array addObject:regex];
        }
    }
    return array;
}

- (NSString*_Nullable) patternMatchingURL:(NSURL*_Nullable)url {
    NSString *urlString = url.absoluteString;
    if (urlString == nil || urlString.length <= 0) return nil;
    NSRange range = NSMakeRange(0, urlString.length);

    for (NSRegularExpression* regex in self.ignoredURLRegex) {
        NSUInteger matches = [regex numberOfMatchesInString:urlString options:0 range:range];
        if (matches > 0) return regex.pattern;
    }

    return nil;
}

- (BOOL) shouldIgnoreURL:(NSURL *)url {
    return ([self patternMatchingURL:url]) ? YES : NO;
}

- (void) updatePatternList {
    [self updatePatternListWithCompletion:nil];
}

- (void) updatePatternListWithCompletion:(void (^) (NSError*error, NSArray*list))completion {
    @synchronized(self) {
        if (self.hasUpdatedPatternList) {
            if (completion) completion(self.error, self.patternList);
            return;
        }
        self.hasUpdatedPatternList = YES;
    }

    self.error = nil;
    NSString *urlString = [self.jsonURL absoluteString];
    if (!urlString) {
        urlString = [NSString stringWithFormat:@"%@/sdk/uriskiplist_v%ld.json", [BNCPreferenceHelper sharedInstance].patternListURL, (long) self.listVersion+1];
    }
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
            timeoutInterval:30.0];

    self.networkService = [[Branch networkServiceClass] new];
    id<BNCNetworkOperationProtocol> operation =
        [self.networkService networkOperationWithURLRequest:request completion:
            ^(id<BNCNetworkOperationProtocol> operation) {
                [self processServerOperation:operation];
                if (completion) completion(self.error, self.patternList);
                [self.networkService cancelAllOperations];
                self.networkService = nil;
            }
        ];
    [operation start];
}

- (void) processServerOperation:(id<BNCNetworkOperationProtocol>)operation {
    NSError *error = nil;
    NSString *responseString = nil;
    if (operation.responseData)
        responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
    if (operation.response.statusCode == 404) {
        BNCLogDebugSDK(@"No new URL ignore list found.");
    } else {
        BNCLogDebugSDK([NSString stringWithFormat:@"URL ignore list update result. Error: %@ status: %ld body:\n%@.",
            operation.error, (long)operation.response.statusCode, responseString]);
    }
    if (operation.error || operation.responseData == nil || operation.response.statusCode != 200) {
        self.error = operation.error;
        return;
    }

    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:&error];
    if (error) {
        self.error = error;
        BNCLogError([NSString stringWithFormat:@"Can't parse JSON: %@.", error]);
        return;
    }

    NSArray *urls = dictionary[@"uri_skip_list"];
    if (![urls isKindOfClass:NSArray.class]) return;

    NSNumber *version = dictionary[@"version"];
    if (![version isKindOfClass:NSNumber.class]) return;

    self.patternList = urls;
    self.listVersion = [version longValue];
    [BNCPreferenceHelper sharedInstance].savedURLPatternList = self.patternList;
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = self.listVersion;
}

@end
