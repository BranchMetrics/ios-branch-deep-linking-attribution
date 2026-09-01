//
//  Branch_SDK.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConfiguration+Private.h"
#import "BNCConfig.h"
#import "BNCCrashlyticsWrapper.h"
#import "BNCDeepLinkViewControllerInstance.h"
#import "BNCEncodingUtils.h"
#import "BNCLinkData.h"
#import "BNCNetworkService.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequest.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerResponse.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BranchInstallRequest.h"
#import "BranchJsonConfig.h"
#import "BranchOpenRequest.h"
#import "BranchShortUrlRequest.h"
#import "BranchShortUrlSyncRequest.h"
#import "BranchSpotlightUrlRequest.h"
#import "BranchUniversalObject.h"
#import "NSMutableDictionary+Branch.h"
#import "NSString+Branch.h"
#import "Branch+Validator.h"
#import "BNCApplication.h"
#import "BNCURLFilter.h"
#import "BNCDeviceInfo.h"
#import "BNCCallbackMap.h"
#import "BNCSKAdNetwork.h"
#import "BNCAppGroupsData.h"
#import "BNCPartnerParameters.h"
#import "BranchEvent.h"
#import "BNCPasteboard.h"
#import "NSError+Branch.h"
#import "BranchLogger.h"
#import "UIViewController+Branch.h"
#import "BNCReferringURLUtility.h"
#import "BNCServerAPI.h"
#import "BranchPluginSupport.h"
#import "BranchLogger.h"
#import "Private/BranchConfigurationController.h"
#import "BranchRequestOpen.h"
#import "BranchRequestDeepLink.h"

#if !TARGET_OS_TV
#import "BNCUserAgentCollector.h"
#import "BNCSpotlightService.h"
#import "BNCContentDiscoveryManager.h"
#import "BranchContentDiscoverer.h"
#import "BNCODMInfoCollector.h"
#endif

NSString * const BRANCH_FEATURE_TAG_SHARE = @"share";
NSString * const BRANCH_FEATURE_TAG_REFERRAL = @"referral";
NSString * const BRANCH_FEATURE_TAG_INVITE = @"invite";
NSString * const BRANCH_FEATURE_TAG_DEAL = @"deal";
NSString * const BRANCH_FEATURE_TAG_GIFT = @"gift";

NSString * const BRANCH_INIT_KEY_CHANNEL = @"~channel";
NSString * const BRANCH_INIT_KEY_FEATURE = @"~feature";
NSString * const BRANCH_INIT_KEY_TAGS = @"~tags";
NSString * const BRANCH_INIT_KEY_CAMPAIGN = @"~campaign";
NSString * const BRANCH_INIT_KEY_STAGE = @"~stage";
NSString * const BRANCH_INIT_KEY_CREATION_SOURCE = @"~creation_source";
NSString * const BRANCH_INIT_KEY_REFERRER = @"+referrer";
NSString * const BRANCH_INIT_KEY_PHONE_NUMBER = @"+phone_number";
NSString * const BRANCH_INIT_KEY_IS_FIRST_SESSION = @"+is_first_session";
NSString * const BRANCH_INIT_KEY_CLICKED_BRANCH_LINK = @"+clicked_branch_link";
static NSString * const BRANCH_PUSH_NOTIFICATION_PAYLOAD_KEY = @"branch";
static NSString * const BRANCH_DEFER_INIT_FOR_PLUGIN_RUNTIME_KEY = @"deferInitForPluginRuntime";

NSString * const BNCCanonicalIdList = @"$canonical_identifier_list";
NSString * const BNCPurchaseAmount = @"$amount";
NSString * const BNCPurchaseCurrency = @"$currency";
NSString * const BNCRegisterViewEvent = @"View";
NSString * const BNCAddToWishlistEvent = @"Add to Wishlist";
NSString * const BNCAddToCartEvent = @"Add to Cart";
NSString * const BNCPurchaseInitiatedEvent = @"Purchase Started";
NSString * const BNCPurchasedEvent = @"Purchased";
NSString * const BNCShareInitiatedEvent = @"Share Started";
NSString * const BNCShareCompletedEvent = @"Share Completed";

NSString * const BNCSpotlightFeature = @"spotlight";

BranchAttributionLevel const BranchAttributionLevelFull = @"FULL";
BranchAttributionLevel const BranchAttributionLevelReduced = @"REDUCED";
BranchAttributionLevel const BranchAttributionLevelMinimal = @"MINIMAL";
BranchAttributionLevel const BranchAttributionLevelNone = @"NONE";

static BOOL bnc_disableAutomaticOpenTracking = NO;
static dispatch_source_t bnc_disableAutomaticOpenTimer = nil;
static NSTimeInterval const BNC_DEFAULT_DISABLE_FOREGROUND_TIMEOUT = 30.0;

#ifndef CSSearchableItemActivityIdentifier
#define CSSearchableItemActivityIdentifier @"kCSSearchableItemActivityIdentifier"
#endif

#pragma mark - Load Categories

// Depending on linker settings, static compilation can omit ObjC categories leading to a runtime error.
// These no-op static initializers force the category to load.
void ForceCategoriesToLoad(void);
void ForceCategoriesToLoad(void) {
    BNCForceNSErrorCategoryToLoad();
    BNCForceNSStringCategoryToLoad();
    BNCForceNSMutableDictionaryCategoryToLoad();
    BNCForceBranchValidatorCategoryToLoad();
    BNCForceUIViewControllerCategoryToLoad();
}

#pragma mark - BranchLink

@implementation BranchLink

+ (BranchLink*) linkWithUniversalObject:(BranchUniversalObject*)universalObject
                             properties:(BranchLinkProperties*)linkProperties {
    BranchLink *link = [[BranchLink alloc] init];
    link.universalObject = universalObject;
    link.linkProperties = linkProperties;
    return link;
}

@end

#pragma mark - Branch

@interface Branch() <BranchDeepLinkingControllerCompletionDelegate> {
    NSInteger _networkCount;
}

// This isolation queue protects branch initialization and ensures things are processed in order.
@property (nonatomic, strong, readwrite) dispatch_queue_t isolationQueue;

@property (strong, nonatomic) BNCServerInterface *serverInterface;
@property (strong, nonatomic) BNCServerRequestQueue *requestQueue;
@property (strong, nonatomic) dispatch_semaphore_t processing_sema;
@property (assign, nonatomic) NSInteger networkCount;
@property (strong, nonatomic) BNCLinkCache *linkCache;
@property (strong, nonatomic) BNCPreferenceHelper *preferenceHelper;
@property (strong, nonatomic) NSMutableDictionary *deepLinkControllers;
@property (weak,   nonatomic) UIViewController *deepLinkPresentingController;
@property (strong, nonatomic) NSDictionary *deepLinkDebugParams;
@property (strong, nonatomic) NSMutableArray *allowedSchemeList;
@property (strong, nonatomic) BNCURLFilter *urlFilter;
@property (strong, nonatomic, readwrite) BNCURLFilter *userURLFilter;

@property (strong, nonatomic) BNCServerAPI *serverAPI;

#if !TARGET_OS_TV
@property (strong, nonatomic) BNCContentDiscoveryManager *contentDiscoveryManager;
#endif

// Support for deferred SDK initialization. Used to support slow plugin runtime startup.
// This is enabled by setting deferInitForPluginRuntime to true in branch.json
@property (nonatomic, assign, readwrite) BOOL deferInitForPluginRuntime;
@property (nonatomic, copy, nullable) void (^cachedInitBlock)(void);
@property (nonatomic, copy, readwrite) NSString *cachedURLString;

// Private method used internally
- (void)clearLinkIdentifiers;

+ (void)applyDeprecatedSettersFromConfiguration:(BranchConfiguration *)configuration
                                        toBranch:(Branch *)branch;

@end

@implementation Branch

#pragma mark - Public methods

#pragma mark - Shared Instance Accessor

// Tracks whether +initialize: has already created and configured the singleton, so a second call
// warns and no-ops rather than re-applying setter side-effects to a running SDK.
static BOOL bnc_didInitializeWithConfiguration = NO;

+ (instancetype)sharedInstance {
    // The singleton must be configured exactly once at launch via +initialize:. Accessing it before
    // then is a programming error: there is no key/configuration to build the instance from, and any
    // deep link handling would silently drop attribution.
    @synchronized ([Branch class]) {
        if (!bnc_didInitializeWithConfiguration) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"[Branch sharedInstance] was called before [Branch initialize:]. "
                               @"Call +[Branch initialize:] with a BranchConfiguration in your "
                               @"application:didFinishLaunchingWithOptions: before accessing the "
                               @"shared instance."];
        }
    }
    return [Branch getInstanceInternal:self.class.branchKey];
}

// Test-only: clears the reinitialization guard so a subsequent +initialize: runs its side-effects
// again. Not declared in the public header; exposed to tests via a category.
+ (void)resetInitializationGuardForTesting {
    @synchronized ([Branch class]) {
        bnc_didInitializeWithConfiguration = NO;
    }
}

+ (Branch *)initialize:(BranchConfiguration *)configuration {
    if (!configuration) {
        NSString *errorMessage = @"A BranchConfiguration is required to initialize Branch.";
        NSError *configurationError = [NSError branchErrorWithCode:BNCInvalidConfigurationError localizedMessage:errorMessage];
        [[BranchLogger shared] logError:errorMessage error:configurationError];
        [[BranchLogger shared] logError:@"Failed to initialize Branch" error:nil];
        return nil;
    }

    // Logging is applied before validation: a rejected configuration is reported only through the
    // logger, so the caller's logLevel/loggingCallback must be live before anything can be rejected.
    [Branch applyLoggingConfiguration:configuration];

    // Logs an actionable message naming the first invalid field.
    if (![configuration validate:NULL]) {
        [[BranchLogger shared] logError:@"Failed to initialize Branch" error:nil];
        return nil;
    }

    // Single canonical initialization entry point. Guard against reinitializing the singleton:
    // once created, re-running the setter side-effects below would mutate a running SDK.

    Branch *branch = nil;
    @synchronized ([Branch class]) {
        if (bnc_didInitializeWithConfiguration) {
            [[BranchLogger shared] logWarning:@"Warning, attempted to reinitialize Branch SDK singleton!" error:nil];
            return [Branch getInstanceInternal:self.class.branchKey];
        }
        bnc_didInitializeWithConfiguration = YES;

        // --- Settings that must be applied before the singleton is created ---
        // These setters are deprecated for external callers, but +initialize: is their canonical
        // internal application point, so suppress the deprecation warning at these call sites.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

        // Test key must be resolved before the branch key is read.
        [Branch setUseTestBranchKey:configuration.testMode];

        // Custom network service class is set-once and must precede singleton creation.
        if (configuration.remoteInterface) {
            [Branch setNetworkServiceClass:configuration.remoteInterface];
        }

#pragma clang diagnostic pop

        // Set the branch key explicitly so it takes precedence over Info.plist / branch.json.
        self.branchKey = configuration.branchKey;
        [BranchConfigurationController sharedInstance].branchKeySource = BRANCH_KEY_SOURCE_INIT_FUNCTION;

        // --- Create (or fetch) the singleton ---
        // Note: the constructor applies branch.json values (apiUrl, logging, cppLevel). Caller-supplied
        // settings that overlap with branch.json are (re)applied AFTER this so the caller wins and
        // branch.json serves only as a fallback.
        branch = [Branch getInstanceInternal:self.branchKey];

        // --- Settings applied to the instance / shared preference helper (caller wins) ---
        [Branch applyConfiguration:configuration toBranch:branch];
    }

    return branch;
}

// A caller who supplied a callback or assigned logLevel owns the logger state. Called twice: once
// before validation, so a rejected configuration still reports through the caller's own logger, and
// again from applyConfiguration: after singleton creation, so the branch.json enableLogging toggle
// cannot override an explicit choice. Both paths are plain assignments, so the repeat is a no-op.
+ (void)applyLoggingConfiguration:(BranchConfiguration *)configuration {
    if (configuration.loggingCallback) {
        [Branch enableLoggingAtLevel:configuration.logLevel withCallback:configuration.loggingCallback];
    } else if (configuration.logLevelWasSet) {
        BranchLogger *logger = [BranchLogger shared];
        logger.loggingEnabled = YES;
        logger.logLevelThreshold = configuration.logLevel;
    }
}

// Applies every configuration value that depends on the singleton already existing.
+ (void)applyConfiguration:(BranchConfiguration *)configuration toBranch:(Branch *)branch {
    [Branch applyLoggingConfiguration:configuration];

    [Branch applyDeprecatedSettersFromConfiguration:configuration toBranch:branch];

    // Identity & environment. These mutate the BNCServerAPI / BNCPreferenceHelper singletons, whose
    // values are read lazily at request time, so they don't need to precede singleton creation.
    // Assigned rather than only turned on, so `euEndpoint = NO` can undo a prior -useEUEndpoints
    // call. A configuration that never touches euEndpoint leaves the current routing alone.
    if (configuration.euEndpointWasSet) {
        [BNCServerAPI sharedInstance].useEUServers = configuration.euEndpoint;
    }
    if (configuration.cdnBaseUrl) {
        [BranchPluginSupport setCDNBaseUrl:configuration.cdnBaseUrl];
    }

    // Network
    [branch setNetworkTimeout:configuration.networkTimeout];
    [branch setMaxRetries:configuration.retryCount];
    [branch setRetryInterval:configuration.retryInterval];
    [Branch setSDKWaitTimeForThirdPartyAPIs:configuration.thirdPartyAPIsWaitTime];

    // Privacy & attribution
    [branch disableAdNetworkCallouts:configuration.adNetworkCalloutsDisabled];
    [BNCPreferenceHelper sharedInstance].limitFacebookTracking = configuration.limitFacebookAttribution;

    if (configuration.attributionLevel) {
        [branch setConsumerProtectionAttributionLevel:configuration.attributionLevel resetSession:NO];
    }

    if (configuration.dmaParameters) {
        // DMA parameters are config-only: written to preferences here so BNCRequestFactory picks them up.
        BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
        prefs.eeaRegion = configuration.dmaParameters.eeaRegion;
        prefs.adPersonalizationConsent = configuration.dmaParameters.adPersonalizationConsent;
        prefs.adUserDataUsageConsent = configuration.dmaParameters.adUserDataUsageConsent;
    }

    // URL collection
    if (configuration.allowedSchemes.count > 0) {
        [branch setAllowedSchemes:configuration.allowedSchemes];
    }
    if (configuration.urlPatternsToIgnore.count > 0) {
        [branch setUrlPatternsToIgnore:configuration.urlPatternsToIgnore];
    }

    // Request metadata
    for (NSString *key in configuration.requestMetadata) {
        [branch setRequestMetadataKey:key value:configuration.requestMetadata[key]];
    }

    // App Clip
    if (configuration.appClipAppGroup) {
        [branch setAppClipAppGroup:configuration.appClipAppGroup];
    }

    // Debugging
    if (configuration.deepLinkDebugParams) {
        [branch setDeepLinkDebugMode:configuration.deepLinkDebugParams];
    }

    // Open tracking: when automatic open tracking is disabled the developer is responsible for -sendOpen.
    if (!configuration.automaticOpenEvents) {
        [Branch disableNextForegroundForTimeInterval:0];
    }
}

// Applies the setters below that are deprecated for external callers but still needed internally.
+ (void)applyDeprecatedSettersFromConfiguration:(BranchConfiguration *)configuration
                                        toBranch:(Branch *)branch {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (configuration.requestTracingCallback) {
        [Branch setCallbackForTracingRequests:configuration.requestTracingCallback];
    }
    if (configuration.apiUrl) {
        [Branch setAPIUrl:configuration.apiUrl];
    }
    if (configuration.safeTrackAPIUrl) {
        [Branch setSafetrackAPIURL:configuration.safeTrackAPIUrl];
    }
    // Pasteboard
    if (configuration.checkPasteboardOnInstall) {
        [branch checkPasteboardOnInstall];
    }
#pragma clang diagnostic pop
}

- (id)initWithInterface:(BNCServerInterface *)interface
                  queue:(BNCServerRequestQueue *)queue
                  cache:(BNCLinkCache *)cache
       preferenceHelper:(BNCPreferenceHelper *)preferenceHelper
                    key:(NSString *)key {

    self = [super init];
    if (!self) return self;

    // Initialize instance variables
    self.isolationQueue = dispatch_queue_create([@"branchIsolationQueue" UTF8String], DISPATCH_QUEUE_SERIAL);

    _serverInterface = interface;
    _serverInterface.preferenceHelper = preferenceHelper;
    _requestQueue = queue;
    _linkCache = cache;
    _preferenceHelper = preferenceHelper;
    _processing_sema = dispatch_semaphore_create(1);
    _networkCount = 0;
    _deepLinkControllers = [[NSMutableDictionary alloc] init];
    _allowedSchemeList = [[NSMutableArray alloc] init];
    _serverAPI = [BNCServerAPI sharedInstance];

    #if !TARGET_OS_TV
    _contentDiscoveryManager = [[BNCContentDiscoveryManager alloc] init];
    #endif

    self.class.branchKey = key;
    self.urlFilter = [BNCURLFilter new];
    [self.urlFilter useSavedPatternList];
    self.userURLFilter = nil;

    [BranchOpenRequest setWaitNeededForOpenResponseLock];

    // Register for notifications
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter
        addObserver:self
        selector:@selector(applicationWillResignActive)
        name:UIApplicationWillResignActiveNotification
        object:nil];

    [notificationCenter
        addObserver:self
        selector:@selector(applicationDidBecomeActive)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];

    // queue up async data loading
    [self loadApplicationData];
    [self loadUserAgent];

    BranchJsonConfig *config = BranchJsonConfig.instance;
    self.deferInitForPluginRuntime = config.deferInitForPluginRuntime;
    [BranchConfigurationController sharedInstance].deferInitForPluginRuntime = self.deferInitForPluginRuntime;


    // These setters are deprecated for external callers; the branch.json fallback path applies them
    // internally, so suppress the deprecation warning at these call sites.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (config.apiUrl) {
        [Branch setAPIUrl:config.apiUrl];
    }

    if (config.enableLogging) {
        [Branch enableLogging];
    }

    if (config.checkPasteboardOnInstall) {
        [self checkPasteboardOnInstall];
    }
#pragma clang diagnostic pop

    if (config.cppLevel) {
        // Runs during singleton construction, so route through self rather than the shared accessor
        // (which would re-enter this constructor's dispatch_once).
        if ([config.cppLevel caseInsensitiveCompare:@"FULL"] == NSOrderedSame) {
            [self setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
        } else if ([config.cppLevel caseInsensitiveCompare:@"REDUCED"] == NSOrderedSame) {
            [self setConsumerProtectionAttributionLevel:BranchAttributionLevelReduced];
        } else if ([config.cppLevel caseInsensitiveCompare:@"MINIMAL"] == NSOrderedSame) {
            [self setConsumerProtectionAttributionLevel:BranchAttributionLevelMinimal];
        } else if ([config.cppLevel caseInsensitiveCompare:@"NONE"] == NSOrderedSame) {
            [self setConsumerProtectionAttributionLevel:BranchAttributionLevelNone];
        } else {
            NSLog(@"Invalid CPP Level set in branch.json: %@", config.cppLevel);
        }
    }

    [self.requestQueue configureWithServerInterface:_serverInterface branchKey:key preferenceHelper:preferenceHelper];
    return self;
}

static Class bnc_networkServiceClass = NULL;
static callbackForTracingRequests bnc_tracingCallback = nil;

+ (void)setNetworkServiceClass:(Class)networkServiceClass {
    @synchronized ([Branch class]) {
        if (bnc_networkServiceClass) {
            [[BranchLogger shared] logError:@"The Branch network service class is already set. Ignoring attempt to set it again." error:nil];
            return;
        }
        if (![networkServiceClass conformsToProtocol:@protocol(BNCNetworkServiceProtocol)]) {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Class '%@' doesn't conform to protocol '%@'.",
                                             NSStringFromClass(networkServiceClass),
                                             NSStringFromProtocol(@protocol(BNCNetworkServiceProtocol))] error:nil];

            return;
        }
        bnc_networkServiceClass = networkServiceClass;
    }
}

+ (Class)networkServiceClass {
    @synchronized ([Branch class]) {
        if (!bnc_networkServiceClass) bnc_networkServiceClass = [BNCNetworkService class];
        return bnc_networkServiceClass;
    }
}

#pragma mark - BrachActivityItemProvider methods
#if !TARGET_OS_TV

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:nil stage:nil campaign:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:nil campaign:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:stage campaign:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage campaign:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage campaign:(NSString *)campaign tags:(NSArray *)tags alias:(NSString *)alias {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage campaign:campaign alias:alias delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags alias:(NSString *)alias {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage campaign:nil alias:alias delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags alias:(NSString *)alias delegate:(id <BranchActivityItemProviderDelegate>)delegate {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage campaign:nil alias:alias delegate:delegate];
}

#endif

#pragma mark - Configuration methods

static BOOL bnc_useTestBranchKey = NO;
static NSString *bnc_branchKey = nil;

+ (void)resetBranchKey {
    bnc_branchKey = nil;
}

+ (void)setUseTestBranchKey:(BOOL)useTestKey {
    @synchronized (self) {
        if (bnc_branchKey && !!useTestKey != !!bnc_useTestBranchKey) {
            [[BranchLogger shared] logError:@"Can't switch the Branch key once it's in use." error:nil];
            return;
        }
        bnc_useTestBranchKey = useTestKey;
    }
}

+ (BOOL)useTestBranchKey {
    @synchronized (self) {
        return bnc_useTestBranchKey;
    }
}

+ (void)setBranchKey:(NSString *)branchKey {
    NSError *error;
    [self setBranchKey:branchKey error:&error];

    if (error) {
        [[BranchLogger shared] logError:@"Failed to set Branch Key" error:error];
    }
}

+ (void)setBranchKey:(NSString*)branchKey error:(NSError **)error {
    @synchronized (self) {
        if (bnc_branchKey) {
            if (branchKey &&
                [branchKey isKindOfClass:[NSString class]] &&
                [branchKey isEqualToString:bnc_branchKey]) {
                return;
            }

            NSString *errorMessage = [NSString stringWithFormat:@"Branch key can only be set once."];
            *error = [NSError branchErrorWithCode:BNCInitError localizedMessage:errorMessage];
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Branch key can only be set once."] error:*error];

            return;
        }

        if (![branchKey isKindOfClass:[NSString class]]) {
            NSString *typeName = (branchKey) ? NSStringFromClass(branchKey.class) : @"<nil>";

            NSString *errorMessage = [NSString stringWithFormat:@"Invalid Branch key of type '%@'.", typeName];
            *error = [NSError branchErrorWithCode:BNCInitError localizedMessage:errorMessage];
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Invalid Branch key of type '%@'.", typeName] error:*error];
            return;
        }

        if ([branchKey hasPrefix:@"key_test"]) {
            bnc_useTestBranchKey = YES;
            [[BranchLogger shared] logWarning: @"You are using your test app's Branch Key. Remember to change it to live Branch Key for production deployment." error:nil];

        } else if ([branchKey hasPrefix:@"key_live"]) {
            bnc_useTestBranchKey = NO;

        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"Invalid Branch key format. Did you add your Branch key to your Info.plist? Passed key is '%@'.", branchKey];
            *error = [NSError branchErrorWithCode:BNCInitError localizedMessage:errorMessage];
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Invalid Branch key format. Did you add your Branch key to your Info.plist? Passed key is '%@'.", branchKey] error:*error];
            return;
        }
        [BranchConfigurationController sharedInstance].branchKeySource = BRANCH_KEY_SOURCE_SET_BRANCH_KEY_API;
        bnc_branchKey = branchKey;
    }
}

+ (NSString *)branchKey {
    @synchronized (self) {
        if (bnc_branchKey) return bnc_branchKey;

        NSString *branchKey = nil;
        NSString *branchKeySource = @"Unknown";

        BranchJsonConfig *config = BranchJsonConfig.instance;
        BOOL usingTestInstance = bnc_useTestBranchKey || config.useTestInstance;
        branchKey = config.branchKey ?: usingTestInstance ? config.testKey : config.liveKey;
        // +setUseTestBranchKey: is deprecated for external callers; this internal resolution path
        // still needs it, so suppress the deprecation warning at this call site.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self setUseTestBranchKey:usingTestInstance];
#pragma clang diagnostic pop

        if (branchKey) {
            branchKeySource = BRANCH_KEY_SOURCE_CONFIG_JSON;
        } else {
            NSDictionary *branchDictionary = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"branch_key"];
            if ([branchDictionary isKindOfClass:[NSString class]]) {
                branchKey = (NSString*) branchDictionary;
            } else
            if ([branchDictionary isKindOfClass:[NSDictionary class]]) {
                branchKey =
                    ([self useTestBranchKey]) ? branchDictionary[@"test"] : branchDictionary[@"live"];
            }
            if (branchKey)
                branchKeySource = BRANCH_KEY_SOURCE_INFO_PLIST;
        }

        self.branchKey = branchKey;
        if (!bnc_branchKey) {
            [[BranchLogger shared] logError:@"Your Branch key is not set in your Info.plist file. See https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/#configure-xcode-project for configuration instructions." error:nil];
        }
        [BranchConfigurationController sharedInstance].branchKeySource = branchKeySource;
        return bnc_branchKey;
    }
}

+ (BOOL)branchKeyIsSet {
    @synchronized (self) {
        return (bnc_branchKey.length) ? YES : NO;
    }
}

- (void)enableLogging {
    [Branch enableLogging];
}

- (void)enableLoggingAtLevel:(BranchLogLevel)logLevel withCallback:(nullable BranchLogCallback)callback {
    [Branch enableLoggingAtLevel:logLevel withCallback:callback];
}

+ (void)enableLogging {
    BranchLogger *logger = [BranchLogger shared];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = BranchLogLevelDebug;
}

+ (void)enableLoggingAtLevel:(BranchLogLevel)logLevel withCallback:(nullable BranchLogCallback)callback {
    BranchLogger *logger = [BranchLogger shared];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = logLevel;
    if (callback) {
        logger.logCallback = callback;
    }
}

+ (void)enableLoggingAtLevel:(BranchLogLevel)logLevel withAdvancedCallback:(BranchAdvancedLogCallback)callback {
    BranchLogger *logger = [BranchLogger shared];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = logLevel;
    if (callback) {
        logger.advancedLogCallback = callback;
    }
}

- (void)useEUEndpoints {
    [BNCServerAPI sharedInstance].useEUServers = YES;
}

+ (void)setAPIUrl:(NSString *)url {
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] ){
        [BNCServerAPI sharedInstance].customAPIURL = url;
    } else {
        [[BranchLogger shared] logWarning:@"Ignoring invalid custom API URL" error:nil];
    }
}

+ (void)setSafetrackAPIURL:(NSString *)url {
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] ){
        [BNCServerAPI sharedInstance].customSafeTrackAPIURL = url;
    } else {
        [[BranchLogger shared] logWarning:@"Ignoring invalid custom Safe Track API URL" error:nil];
    }
}

- (void)validateSDKIntegration {
    [self validateSDKIntegrationCore];
}

- (BOOL)isUserIdentified {
    return self.preferenceHelper.userIdentity != nil;
}

- (void)disableAdNetworkCallouts:(BOOL)disableCallouts {
    self.preferenceHelper.disableAdNetworkCallouts = disableCallouts;
}

- (void)setNetworkTimeout:(NSTimeInterval)timeout {
    self.preferenceHelper.timeout = timeout;
}

- (void)setMaxRetries:(NSInteger)maxRetries {
    self.preferenceHelper.retryCount = maxRetries;
}

- (void)setRetryInterval:(NSTimeInterval)retryInterval {
    self.preferenceHelper.retryInterval = retryInterval;
}

+ (void)setSDKWaitTimeForThirdPartyAPIs:(NSTimeInterval)waitTime {
    @synchronized(self) {
        if (waitTime <= 0) {
            [[BranchLogger shared] logWarning:@"Invalid waitTime value. It must be greater than 0. Using default value." error:nil];
            return;
        }
        if (waitTime > 10) {
            [[BranchLogger shared] logWarning:@"Invalid waitTime value. It must not exceed 10 seconds. Using default value." error:nil];
            return;
        }
        [BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime = waitTime;
    }
}

- (void)setRequestMetadataKey:(NSString *)key value:(NSString *)value {
    [self.preferenceHelper setRequestMetadataKey:key value:value];
}

+ (BOOL)attributionLevelNone {
    @synchronized (self) {
        return [[BNCPreferenceHelper sharedInstance].attributionLevel isEqualToString:BranchAttributionLevelNone];
    }
}

+ (void)disableNextForeground {
    [self disableNextForegroundForTimeInterval:BNC_DEFAULT_DISABLE_FOREGROUND_TIMEOUT];
}

+ (void)disableNextForegroundForTimeInterval:(NSTimeInterval)timeout {
    @synchronized(self) {
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"disableNextForegroundForTimeInterval: %.2f seconds", timeout] error:nil];

        if (bnc_disableAutomaticOpenTimer) {
            dispatch_source_cancel(bnc_disableAutomaticOpenTimer);
            bnc_disableAutomaticOpenTimer = nil;
        }

        bnc_disableAutomaticOpenTracking = YES;

        if (timeout > 0) {
            bnc_disableAutomaticOpenTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
            dispatch_source_set_timer(bnc_disableAutomaticOpenTimer,
                                      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)),
                                      DISPATCH_TIME_FOREVER,
                                      (int64_t)(0.1 * NSEC_PER_SEC));
            // Capture current timer to guard against a stale handler firing after a new
            // disableNextForegroundForTimeInterval: call replaced the timer.
            // dispatch_source_cancel prevents future events but cannot dequeue an already-dispatched handler.
            // Use __weak to avoid a retain cycle (source → handler block → source).
            dispatch_source_t currentTimer = bnc_disableAutomaticOpenTimer;
            __weak dispatch_source_t weakTimer = currentTimer;
            dispatch_source_set_event_handler(currentTimer, ^{
                dispatch_source_t strongTimer = weakTimer;
                @synchronized ([Branch class]) {
                    if (strongTimer != nil && bnc_disableAutomaticOpenTimer == strongTimer) {
                        [Branch resumeSession];
                    }
                }
            });
            dispatch_resume(bnc_disableAutomaticOpenTimer);
        }
    }
}

+ (void)resumeSession {
    @synchronized(self) {
        [[BranchLogger shared] logVerbose:@"resumeSession: re-enabling automatic open tracking" error:nil];

        if (bnc_disableAutomaticOpenTimer) {
            dispatch_source_cancel(bnc_disableAutomaticOpenTimer);
            bnc_disableAutomaticOpenTimer = nil;
        }

        bnc_disableAutomaticOpenTracking = NO;
    }
}

+ (BOOL)automaticOpenTrackingDisabled {
    @synchronized (self) {
        return bnc_disableAutomaticOpenTracking;
    }
}

+ (void)setReferrerGbraidValidityWindow:(NSTimeInterval)validityWindow{
    @synchronized(self) {
        [BNCPreferenceHelper sharedInstance].referringURLQueryParameters[BRANCH_REQUEST_KEY_REFERRER_GBRAID][BRANCH_URL_QUERY_PARAMETERS_VALIDITY_WINDOW_KEY] = @(validityWindow);
    }
}

+ (void) setDMAParamsForEEA:(BOOL)eeaRegion AdPersonalizationConsent:(BOOL)adPersonalizationConsent AdUserDataUsageConsent:(BOOL)adUserDataUsageConsent{
    [BNCPreferenceHelper sharedInstance].eeaRegion = eeaRegion;
    [BNCPreferenceHelper sharedInstance].adPersonalizationConsent = adPersonalizationConsent;
    [BNCPreferenceHelper sharedInstance].adUserDataUsageConsent = adUserDataUsageConsent;
}

+ (void)setODMInfo:(NSString *)odmInfo andFirstOpenTimestamp:(NSDate *) firstOpenTimestamp {
#if !TARGET_OS_TV
    @synchronized (self) {
        [[BNCPreferenceHelper sharedInstance] setOdmInfo:odmInfo];
        [BNCPreferenceHelper sharedInstance].odmInfoInitDate = firstOpenTimestamp;
    }
#else
    [[BranchLogger shared] logWarning:@"setODMInfo not supported on tvOS." error:nil];
#endif

}

+ (void)setAnonID:(NSString *)anonID {
    @synchronized (self) {
        if (anonID && [anonID isKindOfClass:[NSString class]]) {
            [BNCPreferenceHelper sharedInstance].anonID = anonID;
        } else {
            [[BranchLogger shared] logWarning:@"Invalid anonID provided. Must be a non-nil NSString." error:nil];
        }
    }
}

- (void)setConsumerProtectionAttributionLevel:(BranchAttributionLevel)level {
    [self setConsumerProtectionAttributionLevel:level resetSession:YES];
}

- (void)setConsumerProtectionAttributionLevel:(BranchAttributionLevel)level resetSession:(BOOL)resetSession {
    self.preferenceHelper.attributionLevel = level;

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Setting Consumer Protection Attribution Level to %@", level] error:nil];

    //Set tracking to disabled if consumer protection attribution level is changed to BranchAttributionLevelNone. Otherwise, keep tracking enabled.
    if (level == BranchAttributionLevelNone) {
        //Disable Tracking
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Disabling attribution events due to Consumer Protection Attribution Level being %@.", level] error:nil];

        // Clear partner parameters
        [[BNCPartnerParameters shared] clearAllParameters];

        // This is an instance method on the singleton, and it can run during singleton construction
        // (via the branch.json cppLevel path), so operate on self rather than re-entering the accessor.
        [self clearNetworkQueue];
        [self.linkCache clear];
        // Release the lock in case it's locked:
        [BranchOpenRequest releaseOpenResponseLock];
    } else {
        //Enable Tracking
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Enabling attribution events due to Consumer Protection Attribution Level being %@.", level] error:nil];

        if (resetSession) {
            [self sendOpen];
        }
    }
}

+ (void) setCallbackForTracingRequests: (callbackForTracingRequests) callback {
    bnc_tracingCallback = callback;
}

- (void)setDeepLinkDebugMode:(NSDictionary *)debugParams {
    self.deepLinkDebugParams = debugParams;
}

- (void)setAllowedSchemes:(NSArray *)schemes {
    self.allowedSchemeList = [schemes mutableCopy];
}

- (void)addAllowedScheme:(NSString *)scheme {
    [self.allowedSchemeList addObject:scheme];
}

- (void)setUrlPatternsToIgnore:(NSArray<NSString*>*)urlsToIgnore {
    self.userURLFilter = [[BNCURLFilter alloc] init];
    [self.userURLFilter useCustomPatternList:urlsToIgnore];
}

// This is currently the same as handleDeeplink
- (BOOL)handleDeepLinkWithNewSession:(NSURL *)url {
    return [self handleDeepLink:url sceneIdentifier:nil];
}

- (BOOL)handleDeepLink:(NSURL *)url {
    return [self handleDeepLink:url sceneIdentifier:nil];
}

- (BOOL)handleDeepLink:(NSURL *)url sceneIdentifier:(NSString *)sceneIdentifier {
    BOOL filtered = NO;
    BOOL handled = [self processDeepLinkURL:url sceneIdentifier:sceneIdentifier filtered:&filtered];

    // processDeepLinkURL: only populates the preferenceHelper; the entry point owns the enqueue so
    // that the legacy handlers and the requestDeepLinkData* convenience methods each enqueue exactly
    // one request. A skiplisted URL is never sent to Branch.
    if (!filtered) {
        [self requestDeepLinkData:url.absoluteString callback:nil];
    }

    return handled;
}

- (BOOL)processDeepLinkURL:(NSURL *)url sceneIdentifier:(NSString *)sceneIdentifier {
    return [self processDeepLinkURL:url sceneIdentifier:sceneIdentifier filtered:NULL];
}

// Populates the preferenceHelper with everything a deep link request needs from an incoming URL:
// referring-URL query parameters, URL skiplist / dropURLOpen handling, custom-scheme intent URIs and
// link_click_id extraction, and universal link URLs. This is the single source of truth shared by the
// legacy handleDeepLink: entry points and the requestDeepLinkData* convenience methods so that none of
// these checks are skipped regardless of which API the integrator adopts. It never enqueues a request
// itself — that is the caller's job.
// Returns YES if the URL was recognized as a Branch link. On return `filtered` is YES only when the
// URL matched the skiplist, which is the one case where the caller must not send the URL to Branch. A
// NO return on its own just means "not a Branch link", which still warrants a deferred data lookup.
- (BOOL)processDeepLinkURL:(NSURL *)url sceneIdentifier:(NSString *)sceneIdentifier filtered:(BOOL *)filtered {
    if (filtered) {
        *filtered = NO;
    }

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Handle deep link %@", url] error:nil];

    //Check the referring url/uri for query parameters and save them
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    [utility parseReferringURL:url];

    NSString *pattern = nil;
    pattern = [self.urlFilter patternMatchingURL:url];
    if (!pattern) {
        pattern = [self.userURLFilter patternMatchingURL:url];
    }
    if (pattern) {
        if (filtered) {
            *filtered = YES;
        }

        self.preferenceHelper.dropURLOpen = YES;

        NSString *urlString = [url absoluteString];
        self.preferenceHelper.externalIntentURI = urlString;
        self.preferenceHelper.referringURL = urlString;

        return NO;
    }

    NSString *scheme = [url scheme];
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        return [self handleUniversalDeepLink_private:url.absoluteString sceneIdentifier:sceneIdentifier];
    } else {
        return [self handleSchemeDeepLink_private:url sceneIdentifier:sceneIdentifier];
    }
}

- (BOOL)handleSchemeDeepLink_private:(NSURL*)url sceneIdentifier:(NSString *)sceneIdentifier {
    BOOL handled = NO;
    self.preferenceHelper.referringURL = nil;
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Set referringURL to %@", self.preferenceHelper.referringURL] error:nil];

    if (url && ![url isEqual:[NSNull null]]) {

        NSString *urlScheme = [url scheme];

        // save the incoming url in the preferenceHelper in the externalIntentURI field
        if ([self.allowedSchemeList count]) {
            for (NSString *scheme in self.allowedSchemeList) {
                if (urlScheme && [scheme isEqualToString:urlScheme]) {
                    self.preferenceHelper.externalIntentURI = [url absoluteString];
                    self.preferenceHelper.referringURL = [url absoluteString];
                    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Allowed scheme list, set externalIntentURI and referringURL to %@", [url absoluteString]] error:nil];
                    break;
                }
            }
        } else {
            self.preferenceHelper.externalIntentURI = [url absoluteString];
            self.preferenceHelper.referringURL = [url absoluteString];
            [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Set externalIntentURI and referringURL to %@", [url absoluteString]] error:nil];
        }

        NSString *query = [url fragment];
        if (!query) {
            query = [url query];
        }

        NSDictionary *params = [BNCEncodingUtils decodeQueryStringToDictionary:query];
        if (params[@"link_click_id"]) {
            handled = YES;
            self.preferenceHelper.linkClickIdentifier = params[@"link_click_id"];
        }
    }

    return handled;
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [self handleDeepLink:url sceneIdentifier:nil];
}

- (BOOL)sceneIdentifier:(NSString *)sceneIdentifier
                openURL:(NSURL *)url
      sourceApplication:(NSString *)sourceApplication
             annotation:(id)annotation {
    return [self  handleDeepLink:url sceneIdentifier:sceneIdentifier];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    NSString *source = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    NSString *annotation = options[UIApplicationOpenURLOptionsAnnotationKey];
    return [self application:application openURL:url sourceApplication:source annotation:annotation];
}

- (BOOL)handleUniversalDeepLink_private:(NSString*)urlString sceneIdentifier:(NSString *)sceneIdentifier {
    if (urlString.length) {
        self.preferenceHelper.universalLinkUrl = urlString;
        self.preferenceHelper.referringURL = urlString;
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Set universalLinkUrl and referringURL to %@", urlString] error:nil];
    }

    return [Branch isBranchLink:urlString];
}

- (BOOL)continueUserActivity:(NSUserActivity *)userActivity {
    return [self continueUserActivity:userActivity sceneIdentifier:nil];
}

- (BOOL)continueUserActivity:(NSUserActivity *)userActivity sceneIdentifier:(NSString *)sceneIdentifier {
    BOOL filtered = NO;
    BOOL handled = [self processUserActivity:userActivity sceneIdentifier:sceneIdentifier filtered:&filtered];

    // As in handleDeepLink:sceneIdentifier:, the entry point owns the enqueue. webpageURL is nil for a
    // Spotlight activity, which enqueues a deferred data lookup rather than resolving a link.
    if (!filtered) {
        [self requestDeepLinkData:userActivity.webpageURL.absoluteString callback:nil];
    }

    return handled;
}

- (BOOL)processUserActivity:(NSUserActivity *)userActivity sceneIdentifier:(NSString *)sceneIdentifier {
    return [self processUserActivity:userActivity sceneIdentifier:sceneIdentifier filtered:NULL];
}

// Populates the preferenceHelper from an incoming NSUserActivity: the initial referrer, browsing-web
// universal links, and Spotlight identifiers (both Branch and non-Branch). URL-bearing activities are
// funneled through processDeepLinkURL: so the referring-URL, skiplist and link_click_id checks run
// on every path. This is the single source of truth shared by the legacy continueUserActivity: entry
// points and the requestDeepLinkData* convenience methods. It never enqueues a request itself — that
// is the caller's job.
// Returns YES if a Branch link or Spotlight identifier was recognized. `filtered` follows the same
// contract as processDeepLinkURL:sceneIdentifier:filtered:.
- (BOOL)processUserActivity:(NSUserActivity *)userActivity sceneIdentifier:(NSString *)sceneIdentifier filtered:(BOOL *)filtered {
    if (filtered) {
        *filtered = NO;
    }

    if (userActivity.referrerURL) {
        self.preferenceHelper.initialReferrer = userActivity.referrerURL.absoluteString;
    }

    [[BranchLogger shared] logVerbose:userActivity.debugDescription error:nil];
    // Check to see if a browser activity needs to be handled
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return [self processDeepLinkURL:userActivity.webpageURL sceneIdentifier:sceneIdentifier filtered:filtered];
    }

    NSString *spotlightIdentifier = nil;

    #if !TARGET_OS_TV
    // Check to see if a spotlight activity needs to be handled
    spotlightIdentifier = [self.contentDiscoveryManager spotlightIdentifierFromActivity:userActivity];
    NSURL *webURL = userActivity.webpageURL;

    if ([Branch isBranchLink:userActivity.userInfo[CSSearchableItemActivityIdentifier]]) {
        return [self processDeepLinkURL:[NSURL URLWithString:userActivity.userInfo[CSSearchableItemActivityIdentifier]] sceneIdentifier:sceneIdentifier filtered:filtered];
    } else if (webURL != nil && [Branch isBranchLink:[webURL absoluteString]]) {
        return [self processDeepLinkURL:webURL sceneIdentifier:sceneIdentifier filtered:filtered];
    } else if (spotlightIdentifier) {
        self.preferenceHelper.spotlightIdentifier = spotlightIdentifier;
    } else {
        NSString *nonBranchSpotlightIdentifier = [self.contentDiscoveryManager standardSpotlightIdentifierFromActivity:userActivity];
        if (nonBranchSpotlightIdentifier) {
            self.preferenceHelper.spotlightIdentifier = nonBranchSpotlightIdentifier;
        }
    }
    #endif

    return spotlightIdentifier != nil;
}

// checks if URL string looks like a branch link
+ (BOOL)isBranchLink:(NSString *)urlString {
    id branchUniversalLinkDomains = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"branch_universal_link_domains"];

    // check url list in bundle
    if ([branchUniversalLinkDomains isKindOfClass:[NSString class]] && [urlString containsString:branchUniversalLinkDomains]) {
        return YES;
    } else if ([branchUniversalLinkDomains isKindOfClass:[NSArray class]]) {
        for (id oneDomain in branchUniversalLinkDomains) {
            if ([oneDomain isKindOfClass:[NSString class]] && [urlString containsString:oneDomain]) {
                return YES;
            }
        }
    }

    // check default urls
    NSString *userActivityURL = urlString;
    NSArray *branchDomains = [NSArray arrayWithObjects:@"bnc.lt", @"app.link", @"test-app.link", nil];
    for (NSString* domain in branchDomains) {
        if ([userActivityURL containsString:domain]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - async data collection

- (void)loadUserAgent {
    #if !TARGET_OS_TV
    dispatch_async(self.isolationQueue, ^(){
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[BNCUserAgentCollector instance] loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
    #endif
}

- (void)loadApplicationData {
    dispatch_async(self.isolationQueue, ^(){
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [BNCApplication loadCurrentApplicationWithCompletion:^(BNCApplication *application) {
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
}


#pragma mark - Apple Search Ad Check

- (void)checkPasteboardOnInstall {
    [BNCPasteboard sharedInstance].checkOnInstall = YES;
    [BranchConfigurationController sharedInstance].checkPasteboardOnInstall = YES;
}

- (BOOL)willShowPasteboardToast {
    if (!self.preferenceHelper.randomizedBundleToken &&
        [BNCPasteboard sharedInstance].checkOnInstall &&
        [BNCPasteboard sharedInstance].isUrlOnPasteboard) {
        return YES;
    }
    return NO;
}

- (void)setAppClipAppGroup:(NSString *)appGroup {
    [BNCAppGroupsData shared].appGroup = appGroup;
}

- (void)handleATTAuthorizationStatus:(NSUInteger)status {
    // limits impact if the client fails to check that status = notDetermined before calling
    if ([BNCPreferenceHelper sharedInstance].hasCalledHandleATTAuthorizationStatus) {
        return;
    } else {
        [BNCPreferenceHelper sharedInstance].hasCalledHandleATTAuthorizationStatus = YES;
    }

    BranchEvent *event;
    switch (status) {
        case 2:
            // denied
            event = [BranchEvent standardEvent:BranchStandardEventOptOut];
            break;
        case 3:
            // authorized
            event = [BranchEvent standardEvent:BranchStandardEventOptIn];
            break;
        default:
            break;
    }
    if (event) {
        [event logEvent];
    }
}

- (void)setSKAdNetworkCalloutMaxTimeSinceInstall:(NSTimeInterval)maxTimeInterval {
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        [[BranchLogger shared] logDebug:@"Not supported SKAN 4.0+, iOS 16.1+" error:nil];
    } else {
        [BNCSKAdNetwork sharedInstance].maxTimeSinceInstall = maxTimeInterval;
    }
}

#pragma mark - Partner Parameters

- (void)clearPartnerParameters {
    [[BNCPartnerParameters shared] clearAllParameters];
}

- (void)addFacebookPartnerParameterWithName:(NSString *)name value:(NSString *)value {
    if (![Branch attributionLevelNone]) {
        [[BNCPartnerParameters shared] addFacebookParameterWithName:name value:value];
    }
}

- (void)addSnapPartnerParameterWithName:(NSString *)name value:(NSString *)value {
    if (![Branch attributionLevelNone]) {
        [[BNCPartnerParameters shared] addSnapParameterWithName:name value:value];
    }
}

#pragma mark - Pre-initialization support

- (void) dispatchToIsolationQueue:(dispatch_block_t) initBlock {
    dispatch_async(self.isolationQueue, initBlock);
}

#pragma mark - Deep Link Controller methods

- (void)registerDeepLinkController:(UIViewController <BranchDeepLinkingController> *)controller forKey:(NSString *)key {
    self.deepLinkControllers[key] = controller;
}

- (void)registerDeepLinkController:(UIViewController <BranchDeepLinkingController> *)controller forKey:(NSString *)key withPresentation:(BNCViewControllerPresentationOption)option{

    BNCDeepLinkViewControllerInstance* deepLinkModal = [[BNCDeepLinkViewControllerInstance alloc] init];

    deepLinkModal.viewController = controller;
    deepLinkModal.option         = option;

    self.deepLinkControllers[key] = deepLinkModal;
}


#pragma mark - Identity methods

- (void)setIdentity:(NSString *)userId {
    [self setIdentity:userId withCallback: nil];
}

- (void)setIdentity:(NSString *)userId withCallback:(callbackWithParams)callback {
    if (userId) {
        self.preferenceHelper.userIdentity = userId;
    }
    if (callback) {
        callback([self getFirstReferringParams], nil);
    }
}

- (void)logout {
    [self logoutWithCallback:nil];
}

- (void)logoutWithCallback:(callbackWithStatus)callback {
    if ([Branch attributionLevelNone]) {
        NSError *error = [NSError branchErrorWithCode:BNCAttributionLevelNoneError];
        [[BranchLogger shared] logWarning:@"Branch attribution level is set to NONE, cannot logout." error:error];
        if (callback) {callback(NO, error);}
        return;
    }

    // Clear cached links
    self.linkCache = [[BNCLinkCache alloc] init];

    // Removed stored values
    self.preferenceHelper.userIdentity = nil;

    if (callback) {
        callback(YES, nil);
    }
}

- (void)sendServerRequest:(BNCServerRequest*)request {
    dispatch_async(self.isolationQueue, ^(){
        [self.requestQueue enqueue:request];
    });
}

// deprecated, use sendServerRequest
- (void)sendServerRequestWithoutSession:(BNCServerRequest*)request {
    [self sendServerRequest:request];
}

- (BranchUniversalObject *)getFirstReferringBranchUniversalObject {
    NSDictionary *params = [self getFirstReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchUniversalObject objectWithDictionary:params];
    }
    return nil;
}

- (BranchLinkProperties *)getFirstReferringBranchLinkProperties {
    NSDictionary *params = [self getFirstReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchLinkProperties getBranchLinkPropertiesFromDictionary:params];
    }
    return nil;
}

- (NSDictionary *)getFirstReferringParams {
    NSDictionary *origInstallParams = [BNCEncodingUtils decodeJsonStringToDictionary:self.preferenceHelper.installParams];

    if (self.deepLinkDebugParams) {
        NSMutableDictionary* debugInstallParams =
            [[BNCEncodingUtils decodeJsonStringToDictionary:self.preferenceHelper.sessionParams]
                mutableCopy];
        [debugInstallParams addEntriesFromDictionary:self.deepLinkDebugParams];
        return debugInstallParams;
    }
    return origInstallParams;
}

- (NSDictionary *)getLatestReferringParams {
    NSDictionary *origSessionParams = [BNCEncodingUtils decodeJsonStringToDictionary:self.preferenceHelper.sessionParams];

    if (self.deepLinkDebugParams) {
        NSMutableDictionary* debugSessionParams = [origSessionParams mutableCopy];
        [debugSessionParams addEntriesFromDictionary:self.deepLinkDebugParams];
        return debugSessionParams;
    }
    return origSessionParams;
}

- (NSDictionary *)getLatestReferringParamsSynchronous {
    [BranchOpenRequest waitForOpenResponseLock];
    [BranchRequestDeepLink waitForDeepLinkResponseLock];
    [BranchRequestOpen waitForOpenResponseLock];
    NSDictionary *result = [self getLatestReferringParams];
    [BranchOpenRequest releaseOpenResponseLock];
    [BranchRequestDeepLink releaseDeepLinkResponseLock];
    [BranchRequestOpen releaseOpenResponseLock];
    return result;
}

- (BranchUniversalObject *)getLatestReferringBranchUniversalObject {
    NSDictionary *params = [self getLatestReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchUniversalObject objectWithDictionary:params];
    }
    return nil;
}

- (BranchLinkProperties *)getLatestReferringBranchLinkProperties {
    NSDictionary *params = [self getLatestReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] boolValue]) {
        return [BranchLinkProperties getBranchLinkPropertiesFromDictionary:params];
    }
    return nil;
}

#pragma mark - Query methods

- (void)lastAttributedTouchDataWithAttributionWindow:(NSInteger)window completion:(void(^) (BranchLastAttributedTouchData * _Nullable latd, NSError * _Nullable error))completion {
    dispatch_async(self.isolationQueue, ^(){
        [BranchLastAttributedTouchData requestLastTouchAttributedData:self.serverInterface key:self.class.branchKey attributionWindow:window completion:completion];
    });
}

#pragma mark - ShortUrl methods

- (NSString *)getShortURL {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andCampaign:nil andParams:nil ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias ignoreUAString:(NSString *)ignoreUAString {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:ignoreUAString forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCampaign:(NSString *)campaign andAlias:(NSString *)alias ignoreUAString:(NSString *)ignoreUAString forceLinkCreation:(BOOL)forceLinkCreation {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:campaign andParams:params ignoreUAString:ignoreUAString forceLinkCreation:forceLinkCreation];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type {
    return [self generateShortUrl:tags andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateShortUrl:nil andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type {
    return [self generateShortUrl:nil andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:nil andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andAlias:(NSString *)alias andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCampaign:(NSString *)campaign andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:campaign andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (NSString *)getShortUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andAlias:(NSString *)alias andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params ignoreUAString:nil forceLinkCreation:YES];
}

- (void)getShortURLWithCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andCampaign:nil andParams:nil andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:nil andCampaign:nil andParams:params andCallback:callback];
}

- (void)getShortUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andAlias:(NSString *)alias andMatchDuration:(NSUInteger)duration andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCampaign:campaign andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:campaign andParams:params andCallback:callback];
}

- (void)getShortUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andAlias:(NSString *)alias andMatchDuration:(NSUInteger)duration andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andCampaign:nil andParams:params andCallback:callback];
}

- (void)getSpotlightUrlWithParams:(NSDictionary *)params callback:(callbackWithParams)callback {
    dispatch_async(self.isolationQueue, ^(){
        BranchSpotlightUrlRequest *req = [[BranchSpotlightUrlRequest alloc] initWithParams:params callback:callback];
        [self.requestQueue enqueue:req];
    });
}

#pragma mark - LongUrl methods
- (NSString *)getLongURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateLongURLWithParams:params andChannel:channel andTags:tags andFeature:feature andStage:stage andAlias:alias];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:nil andStage:nil andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:feature andStage:nil andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:feature andStage:stage andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags {
    return [self generateLongURLWithParams:params andChannel:nil andTags:tags andFeature:feature andStage:stage andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:feature andStage:stage andAlias:alias];
}

- (NSString *)getLongAppLinkURLWithParams:(NSDictionary *)params andChannel:(nullable NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateLongAppLinkURLWithParams:params andChannel:channel andTags:tags andFeature:feature andStage:stage andAlias:alias];
}

#pragma mark - Discoverable content methods
#if !TARGET_OS_TV

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams publiclyIndexable:(BOOL)publiclyIndexable {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable thumbnailUrl:thumbnailUrl userInfo:linkParams];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams callback:callback];
}
- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams expirationDate:expirationDate callback:callback];
}
- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl canonicalId:canonicalId linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description canonicalId:canonicalId publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams expirationDate:expirationDate callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description canonicalId:nil publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams expirationDate:expirationDate callback:nil spotlightCallback:spotlightCallback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl canonicalId:(NSString *)canonicalId linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description canonicalId:canonicalId publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams expirationDate:expirationDate callback:nil spotlightCallback:spotlightCallback];
}

- (void)indexOnSpotlightWithBranchUniversalObject:(BranchUniversalObject*)universalObject
                                   linkProperties:(BranchLinkProperties*)linkProperties
                                       completion:(void (^) (BranchUniversalObject *universalObject, NSString * url,NSError *error))completion {
    BNCSpotlightService *spotlightService = [[BNCSpotlightService alloc] init];

    if (!universalObject) {
        NSError* error = [NSError branchErrorWithCode:BNCInitError localizedMessage:@"Branch Universal Object is nil"];
        if (completion) completion(universalObject,nil,error);
        return;
    } else {
        [spotlightService indexWithBranchUniversalObject:universalObject
                                          linkProperties:linkProperties
                                                callback:^(BranchUniversalObject * _Nullable universalObject,
                                                           NSString * _Nullable url,
                                                           NSError * _Nullable error) {
                                              if (completion) completion(universalObject,url,error);
                                          }];
    }
}

/* Indexing of multiple BUOs
 * Content privately indexed irrestive of the value of contentIndexMode
 */


- (void)indexOnSpotlightUsingSearchableItems:(NSArray<BranchUniversalObject*>* )universalObjects
                                  completion:(void (^) (NSArray<BranchUniversalObject *>* universalObjects,
                                                        NSError* error))completion {

    BNCSpotlightService *spotlight = [[BNCSpotlightService alloc] init];
    [spotlight indexPrivatelyWithBranchUniversalObjects:universalObjects
                                             completion:^(NSArray<BranchUniversalObject *> * _Nullable universalObjects,
                                                          NSError * _Nullable error) {
                                                 if (completion) completion(universalObjects,error);
                                             }];
}

- (void)removeSearchableItemWithBranchUniversalObject:(BranchUniversalObject *)universalObject
                                             callback:(void (^_Nullable)(NSError * _Nullable error))completion {
    BNCSpotlightService *spotlight = [[BNCSpotlightService alloc] init];

    NSString *dynamicUrl = [universalObject getLongUrlWithChannel:nil
                                                          andTags:nil
                                                       andFeature:BNCSpotlightFeature
                                                         andStage:nil
                                                         andAlias:nil];
    [spotlight removeSearchableItemsWithIdentifier:dynamicUrl
                                          callback:^(NSError * _Nullable error) {
                                              if (completion) completion(error);
                                          }];
}


/* Only removes the indexing of BUOs indexed through CSSearchable item
 */
- (void)removeSearchableItemsWithBranchUniversalObjects:(NSArray<BranchUniversalObject*> *)universalObjects
                                               callback:(void (^)(NSError * error))completion {
    BNCSpotlightService *spotlight = [[BNCSpotlightService alloc] init];
    NSMutableArray<NSString *> *identifiers = [[NSMutableArray alloc] init];
    for (BranchUniversalObject* universalObject in universalObjects) {
        NSString *dynamicUrl = [universalObject getLongUrlWithChannel:nil
                                                              andTags:nil
                                                           andFeature:BNCSpotlightFeature
                                                             andStage:nil andAlias:nil];
        if (dynamicUrl) [identifiers addObject:dynamicUrl];
    }

    [spotlight removeSearchableItemsWithIdentifiers:identifiers
                                           callback:^(NSError * error) {
                                               if (completion)
                                                   completion(error);
                                           }];
}

/* Removes all content from spotlight indexed through CSSearchable item and has set the Domain identifier = "com.branch.io"
 */

- (void)removeAllPrivateContentFromSpotLightWithCallback:(void (^)(NSError * error))completion {
    BNCSpotlightService *spotlight = [[BNCSpotlightService alloc] init];
    [spotlight removeAllBranchSearchableItemsWithCallback:^(NSError * _Nullable error) {
        completion(error);
    }];
}
#endif

#if !TARGET_OS_TV
#pragma mark - UIPasteControl Support methods

- (void)passPasteItemProviders:(NSArray<NSItemProvider *> *)itemProviders {

   // 1. Extract URL from NSItemProvider arrary
    for (NSItemProvider* item in itemProviders){
        if ( [item hasItemConformingToTypeIdentifier: UTTypeURL.identifier] ) {
            // 2. Check if URL is branch URL and if yes -> store it.
            [item loadItemForTypeIdentifier:UTTypeURL.identifier options:NULL completionHandler:^(NSURL *url, NSError * _Null_unspecified error) {
                if (error) {
                    [[BranchLogger shared] logWarning:@"Failed to load URL from Pasteboard" error:error];
                }
                else if ([Branch isBranchLink:url.absoluteString]) {
                    [self.preferenceHelper setLocalUrl:[url absoluteString]];
                    // 3. Send Open Event
                    [[Branch sharedInstance] requestDeepLinkDataWithURL:url];
                }
            }];
        }
    }
}
#endif

#pragma mark - Private methods

+ (Branch *)getInstanceInternal:(NSString *)key {

    static Branch *branch = nil;
    @synchronized (self) {
        static dispatch_once_t onceToken = 0;
        dispatch_once(&onceToken, ^{
            BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

            // If there was stored key and it isn't the same as the currently used (or doesn't exist), we need to clean up
            // Note: Link Click Identifier is not cleared because of the potential for that to mess up a deep link
            if (preferenceHelper.lastRunBranchKey && ![key isEqualToString:preferenceHelper.lastRunBranchKey]) {
                [[BranchLogger shared] logWarning:@"The Branch Key has changed, clearing relevant items." error:nil];
                preferenceHelper.appVersion = nil;
                preferenceHelper.randomizedDeviceToken = nil;
                preferenceHelper.randomizedBundleToken = nil;
                preferenceHelper.userUrl = nil;
                preferenceHelper.installParams = nil;
                preferenceHelper.sessionParams = nil;

                [[BNCServerRequestQueue getInstance] clearQueue];
            }

            if(!preferenceHelper.firstAppLaunchTime){
                preferenceHelper.firstAppLaunchTime = [NSDate date];
            }

            preferenceHelper.lastRunBranchKey = key;
            branch =
                [[Branch alloc] initWithInterface:[[BNCServerInterface alloc] init]
                    queue:[BNCServerRequestQueue getInstance]
                    cache:[[BNCLinkCache alloc] init]
                    preferenceHelper:preferenceHelper
                    key:key];

            // Workaround for testbed not linking BranchPluginSupport, which prevents unit tests from finding it
            [BranchPluginSupport instance];
        });
        return branch;
    }
}

- (void)clearLinkIdentifiers {
    // Clear link identifiers so they don't get reused on the next open
    // This matches the cleanup done in BranchRequestOpen.processResponse (lines 181-184)
    self.preferenceHelper.linkClickIdentifier = nil;
    self.preferenceHelper.spotlightIdentifier = nil;
    self.preferenceHelper.universalLinkUrl = nil;
    self.preferenceHelper.externalIntentURI = nil;
    self.preferenceHelper.referringURL = nil;
    self.preferenceHelper.initialReferrer = nil;
    self.preferenceHelper.dropURLOpen = NO;
    self.preferenceHelper.uxType = nil;
    self.preferenceHelper.urlLoadMs = nil;
}

#pragma mark - URL Generation methods

- (void)generateShortUrl:(NSArray *)tags
                andAlias:(NSString *)alias
                 andType:(BranchLinkType)type
        andMatchDuration:(NSUInteger)duration
              andChannel:(NSString *)channel
              andFeature:(NSString *)feature
                andStage:(NSString *)stage
             andCampaign:campaign andParams:(NSDictionary *)params
             andCallback:(callbackWithUrl)callback {

    dispatch_async(self.isolationQueue, ^(){
        BNCLinkData *linkData = [self prepareLinkDataFor:tags
                                                andAlias:alias
                                                 andType:type
                                        andMatchDuration:duration
                                              andChannel:channel
                                              andFeature:feature
                                                andStage:stage
                                             andCampaign:campaign
                                               andParams:params
                                          ignoreUAString:nil];

        if ([self.linkCache objectForKey:linkData]) {
            if (callback) {
                // callback on main, this is generally what the client expects and maintains our previous behavior
                dispatch_async(dispatch_get_main_queue(), ^ {
                    callback([self.linkCache objectForKey:linkData], nil);
                });
            }
            return;
        }

        BranchShortUrlRequest *req = [[BranchShortUrlRequest alloc] initWithTags:tags
                                                                           alias:alias
                                                                            type:type
                                                                   matchDuration:duration
                                                                         channel:channel
                                                                         feature:feature
                                                                           stage:stage
                                                                        campaign:campaign
                                                                          params:params
                                                                        linkData:linkData
                                                                       linkCache:self.linkCache
                                                                        callback:callback];
        [self.requestQueue enqueue:req];
    });
}

- (NSString *)generateShortUrl:(NSArray *)tags
                      andAlias:(NSString *)alias
                       andType:(BranchLinkType)type
              andMatchDuration:(NSUInteger)duration
                    andChannel:(NSString *)channel
                    andFeature:(NSString *)feature
                      andStage:(NSString *)stage
                   andCampaign:(NSString *)campaign
                     andParams:(NSDictionary *)params
                ignoreUAString:(NSString *)ignoreUAString
             forceLinkCreation:(BOOL)forceLinkCreation {

    NSString *shortURL = nil;

    BNCLinkData *linkData =
    [self prepareLinkDataFor:tags
                    andAlias:alias
                     andType:type
            andMatchDuration:duration
                  andChannel:channel
                  andFeature:feature
                    andStage:stage
                 andCampaign:campaign
                   andParams:params
              ignoreUAString:ignoreUAString];

    // If an ignore UA string is present, we always get a new url.
    // Otherwise, if we've already seen this request, use the cached version.
    if (!ignoreUAString && [self.linkCache objectForKey:linkData]) {
        [[BranchLogger shared] logVerbose:@"Returning cached Branch Link" error:nil];

        shortURL = [self.linkCache objectForKey:linkData];
    } else {
        BranchShortUrlSyncRequest *req =
        [[BranchShortUrlSyncRequest alloc]
         initWithTags:tags
         alias:alias
         type:type
         matchDuration:duration
         channel:channel
         feature:feature
         stage:stage
         campaign:campaign
         params:params
         linkData:linkData
         linkCache:self.linkCache];

        [[BranchLogger shared] logVerbose:@"Requesting Branch Link synchronously" error:nil];
        BNCServerResponse *serverResponse = [req makeRequest:self.serverInterface key:self.class.branchKey];
        shortURL = [req processResponse:serverResponse];

        // cache the link
        if (shortURL) {
            [self.linkCache setObject:shortURL forKey:linkData];
        }
    }

    return shortURL;
}

- (NSString *)generateLongURLWithParams:(NSDictionary *)params
                             andChannel:(NSString *)channel
                                andTags:(NSArray *)tags
                             andFeature:(NSString *)feature
                               andStage:(NSString *)stage
                               andAlias:(NSString *)alias {

    NSString *baseLongUrl = [NSString stringWithFormat:@"%@/a/%@", BNC_LINK_URL, self.class.branchKey];

    return [self longUrlWithBaseUrl:baseLongUrl params:params tags:tags feature:feature
        channel:nil stage:stage alias:alias duration:0 type:BranchLinkTypeUnlimitedUse];
}

- (NSString *)generateLongAppLinkURLWithParams:(NSDictionary *)params
                                    andChannel:(NSString *)channel
                                       andTags:(NSArray *)tags
                                    andFeature:(NSString *)feature
                                      andStage:(NSString *)stage
                                      andAlias:(NSString *)alias {

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *baseUrl;

    if (preferenceHelper.userUrl) {
        NSString *fullUserUrl = [preferenceHelper sanitizedMutableBaseURL:preferenceHelper.userUrl];
        baseUrl = [fullUserUrl componentsSeparatedByString:@"?"].firstObject;
    } else {
        baseUrl = [[NSMutableString alloc] initWithFormat:@"%@/a/%@?", BNC_LINK_URL, self.class.branchKey];
    }

    return [self longUrlWithBaseUrl:baseUrl params:params tags:tags feature:feature
        channel:nil stage:stage alias:alias duration:0 type:BranchLinkTypeUnlimitedUse];
}

- (NSString *)longUrlWithBaseUrl:(NSString *)baseUrl
                          params:(NSDictionary *)params
                            tags:(NSArray *)tags
                         feature:(NSString *)feature
                         channel:(NSString *)channel
                           stage:(NSString *)stage
                           alias:(NSString *)alias
                        duration:(NSUInteger)duration
                            type:(BranchLinkType)type {

    NSMutableString *longUrl = [self.preferenceHelper sanitizedMutableBaseURL:baseUrl];
    for (NSString *tag in tags) {
        [longUrl appendFormat:@"tags=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:tag]];
    }

    if ([alias length]) {
        [longUrl appendFormat:@"alias=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:alias]];
    }

    if ([channel length]) {
        [longUrl appendFormat:@"channel=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:channel]];
    }

    if ([feature length]) {
        [longUrl appendFormat:@"feature=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:feature]];
    }

    if ([stage length]) {
        [longUrl appendFormat:@"stage=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:stage]];
    }
    if (type) {
        [longUrl appendFormat:@"type=%ld&", (long)type];
    }
    if (duration) {
        [longUrl appendFormat:@"matchDuration=%ld&", (long)duration];
    }

    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:params];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    [longUrl appendFormat:@"source=ios&data=%@", base64EncodedParams];

    return longUrl;
}

- (BNCLinkData *)prepareLinkDataFor:(NSArray *)tags
                           andAlias:(NSString *)alias
                            andType:(BranchLinkType)type
                   andMatchDuration:(NSUInteger)duration
                         andChannel:(NSString *)channel
                         andFeature:(NSString *)feature
                           andStage:(NSString *)stage
                        andCampaign:(NSString *)campaign
                          andParams:(NSDictionary *)params
                     ignoreUAString:(NSString *)ignoreUAString {

    BNCLinkData *post = [[BNCLinkData alloc] init];

    [post setupType:type];
    [post setupTags:tags];
    [post setupChannel:channel];
    [post setupFeature:feature];
    [post setupStage:stage];
    [post setupCampaign:campaign];
    [post setupAlias:alias];
    [post setupMatchDuration:duration];
    [post setupIgnoreUAString:ignoreUAString];
    [post setupParams:params];

    return post;
}

#pragma mark - BranchUniversalObject methods

- (void)registerViewWithParams:(NSDictionary *)params andCallback:(callbackWithParams)callback {
    dispatch_async(self.isolationQueue, ^(){
        BranchUniversalObject *buo = [[BranchUniversalObject alloc] init];
        buo.contentMetadata.customMetadata = (id) params;
        [[BranchEvent standardEvent:BranchStandardEventViewItem withContentItem:buo] logEvent];
        if (callback) {
            // callback on main, this is generally what the client expects and maintains our previous behavior
            dispatch_async(dispatch_get_main_queue(), ^ {
                callback(@{}, nil);
            });
        }
    });
}

#pragma mark - Application State Change methods

- (void)applicationDidBecomeActive {
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"applicationDidBecomeActive"] error:nil];

    @synchronized ([Branch class]) {
        if (bnc_disableAutomaticOpenTracking) {
            [[BranchLogger shared] logVerbose:@"applicationDidBecomeActive: automatic open tracking is disabled, skipping" error:nil];
            return;
        }
    }

    dispatch_async(self.isolationQueue, ^(){
        //  if necessary, creates a new organic open
        BOOL installOrOpenInQueue = [self.requestQueue containsInstallOrOpen];

        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"applicationDidBecomeActive installOrOpenInQueue %d", installOrOpenInQueue] error:nil];

        if (![Branch attributionLevelNone] && !installOrOpenInQueue) {
            [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"applicationDidBecomeActive attributionLevelNone %d installOrOpenInQueue %d", [Branch attributionLevelNone], installOrOpenInQueue] error:nil];

            [self sendOpen];
        }
    });
}

- (void)applicationWillResignActive {
    [[BranchLogger shared] logVerbose:@"applicationWillResignActive" error:nil];

    dispatch_async(self.isolationQueue, ^(){
        if (![Branch attributionLevelNone]) {
            [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"applicationWillResignActive"] error:nil];
            [BranchOpenRequest setWaitNeededForOpenResponseLock];
        }
    });
}

#pragma mark - Queue management

- (NSInteger) networkCount {
    @synchronized (self) {
        return _networkCount;
    }
}

- (void)setNetworkCount:(NSInteger)networkCount {
    @synchronized (self) {
        _networkCount = networkCount;
    }
}

static inline void BNCPerformBlockOnMainThreadSync(dispatch_block_t block) {
    if (block) {
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
}

- (void)clearNetworkQueue {
    dispatch_semaphore_wait(self.processing_sema, DISPATCH_TIME_FOREVER);
    self.networkCount = 0;
    [[BNCServerRequestQueue getInstance] clearQueue];
    dispatch_semaphore_signal(self.processing_sema);
}

#pragma mark - Session Initialization

// Defers block until notifyNativeToInit is called.
- (BOOL)deferInitBlock:(void (^)(void))block {
    BOOL deferred = NO;
    @synchronized (self) {
        if (self.deferInitForPluginRuntime) {
            [[BranchLogger shared] logDebug:@"Deferring SDK init until notifyNativeToInit is called" error:nil];
            self.cachedInitBlock = block;
            deferred = YES;
        }
    }

    // handle default non-deferred state
    if (!deferred && block) {
        block();
    }
    return deferred;
}

// Releases deferred init block
- (void)notifyNativeToInit {
    @synchronized (self) {
        [[BranchLogger shared] logDebug:@"Unlocking Deferred SDK init" error:nil];
        self.deferInitForPluginRuntime = NO;
    }

    if (self.cachedInitBlock) {
        self.cachedInitBlock();
    }
    self.cachedInitBlock = nil;
}

- (void)handleInitSuccess {
    NSDictionary *latestReferringParams = [self getLatestReferringParams];

    if ([latestReferringParams[@"_branch_validate"] isEqualToString:@"060514"]) {
        [self validateDeeplinkRouting:latestReferringParams];
    }
    else if (([latestReferringParams[@"bnc_validate"] isEqualToString:@"true"])) {
        NSString* referringLink = [self.class returnNonUniversalLink:latestReferringParams[@"~referring_link"] ];
        NSURLComponents *comp = [NSURLComponents componentsWithURL:[NSURL URLWithString:referringLink]
                                           resolvingAgainstBaseURL:NO];

        Class applicationClass = NSClassFromString(@"UIApplication");
        id<NSObject> sharedApplication = [applicationClass performSelector:@selector(sharedApplication)];
        if ([sharedApplication respondsToSelector:@selector(openURL:)])
            [sharedApplication performSelector:@selector(openURL:) withObject:comp.URL];
    } else if ([latestReferringParams[@"validate_integration"] isEqualToString:@"true"]) {
        [self validateSDKIntegration];
    }

    [self sendOpenNotificationWithLinkParameters:latestReferringParams error:nil];

    [self.urlFilter updatePatternListFromServerWithCompletion:nil];
}

- (void)sendOpenNotificationWithLinkParameters:(NSDictionary*)linkParameters
                                         error:(NSError*)error {

    NSURL *originalURL =
        (self.preferenceHelper.referringURL.length)
        ? [NSURL URLWithString:self.preferenceHelper.referringURL]
        : nil;
    BranchLinkProperties *linkProperties = nil;
    BranchUniversalObject *universalObject = nil;

    NSNumber *isBranchLink = linkParameters[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK];
    if ([isBranchLink boolValue]) {
        universalObject = [BranchUniversalObject objectWithDictionary:linkParameters];
        linkProperties = [BranchLinkProperties getBranchLinkPropertiesFromDictionary:linkParameters];
    }

    if (error) {

        if ([self.delegate respondsToSelector:@selector(branch:failedToStartSessionWithURL:error:)])
            [self.delegate branch:self failedToStartSessionWithURL:originalURL error:error];

    } else {

        BranchLink *branchLink = nil;
        if (universalObject) {
            branchLink = [BranchLink linkWithUniversalObject:universalObject properties:linkProperties];
        }
        if ([self.delegate respondsToSelector:@selector(branch:didStartSessionWithURL:branchLink:)])
            [self.delegate branch:self didStartSessionWithURL:originalURL branchLink:branchLink];

    }

    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[BranchErrorKey] = error;
    userInfo[BranchURLKey] = originalURL;
    userInfo[BranchUniversalObjectKey] = universalObject;
    userInfo[BranchLinkPropertiesKey] = linkProperties;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidStartSessionNotification
        object:self
        userInfo:userInfo];

    self.preferenceHelper.referringURL = nil;
}

- (void)removeViewControllerFromRootNavigationController:(UIViewController*)branchSharingController {

    NSMutableArray* viewControllers =
        [NSMutableArray arrayWithArray: [(UINavigationController*)self.deepLinkPresentingController viewControllers]];

    if ([viewControllers lastObject] == branchSharingController) {

        [(UINavigationController*)self.deepLinkPresentingController popViewControllerAnimated:YES];
    }else {
        [viewControllers removeObject:branchSharingController];
        ((UINavigationController*)self.deepLinkPresentingController).viewControllers = viewControllers;
    }
}

- (void)presentSharingViewController:(UIViewController <BranchDeepLinkingController> *)branchSharingController {
    if ([self.deepLinkPresentingController presentedViewController]) {
        [self.deepLinkPresentingController dismissViewControllerAnimated:NO completion:^{
            [self.deepLinkPresentingController presentViewController:branchSharingController animated:YES completion:NULL];
        }];
    }
    else {
        [self.deepLinkPresentingController presentViewController:branchSharingController animated:YES completion:NULL];
    }
}

- (void)handleInitFailure:(NSError *)error {
    [self sendOpenNotificationWithLinkParameters:@{} error:error];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerPluginName:(NSString *)name version:(NSString *)version {
    [[BNCDeviceInfo getInstance] registerPluginName:name version:version];
}

#pragma mark - BranchDeepLinkingControllerCompletionDelegate methods

- (void)deepLinkingControllerCompletedFrom:(UIViewController *)viewController {
    [self.deepLinkControllers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {

        if([obj isKindOfClass:[BNCDeepLinkViewControllerInstance class]]) {
            BNCDeepLinkViewControllerInstance* deepLinkInstance = (BNCDeepLinkViewControllerInstance*) obj;

            if (deepLinkInstance.viewController == viewController) {

                switch (deepLinkInstance.option) {
                    case BNCViewControllerOptionPresent:
                        [viewController dismissViewControllerAnimated:YES completion:nil];
                        break;

                    default:
                        [self removeViewControllerFromRootNavigationController:viewController];
                        break;
                }
            }

        } else {
            //Support for old API
            if ((UIViewController*)obj == viewController)
                [self.deepLinkPresentingController dismissViewControllerAnimated:YES completion:nil];
        }

    }];
}

#pragma mark - Crashlytics reporting enhancements

+ (void)logLowMemoryToCrashlytics {
    [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
        object:nil
        queue:NSOperationQueue.mainQueue
        usingBlock:^(NSNotification *notification) {
            BNCCrashlyticsWrapper *crashlytics = [BNCCrashlyticsWrapper wrapper];
            [crashlytics setCustomValue:@YES forKey:BRANCH_CRASHLYTICS_LOW_MEMORY_KEY];
        }
    ];
}

+ (void)addBranchSDKVersionToCrashlyticsReport {
    BNCCrashlyticsWrapper *crashlytics = [BNCCrashlyticsWrapper wrapper];
    [crashlytics setCustomValue:BNC_SDK_VERSION forKey:BRANCH_CRASHLYTICS_SDK_VERSION_KEY];
}

+ (void) clearAll {
    [[BNCServerRequestQueue getInstance] clearQueue];
    [BranchOpenRequest releaseOpenResponseLock];
    [BranchRequestDeepLink releaseDeepLinkResponseLock];
    [BranchRequestOpen releaseOpenResponseLock];
    [BNCPreferenceHelper clearAll];
}

#pragma mark - Branch Core Deep Linking Method

- (void) requestDeepLinkData:(NSString *)branchLink callback:(nullable callbackWithParams)callback {
    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData called with branchLink: %@", branchLink] error:nil];

    // Same question handleDeepLink: asks, asked before anything is cancelled or enqueued: a URL
    // the skiplist or the host app told us to ignore must not reach /v3/deeplink. It is also
    // asked before -cancelPendingDeepLinkRequests, so an ignored URL cannot discard a resolution
    // already in flight for a link we are allowed to resolve.
    NSString *ignoredPattern = nil;
    if (branchLink.length > 0) {
        NSURL *url = [NSURL URLWithString:branchLink];
        ignoredPattern = [self.urlFilter patternMatchingURL:url];
        if (!ignoredPattern) {
            ignoredPattern = [self.userURLFilter patternMatchingURL:url];
        }
    }
    if (ignoredPattern) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData will not resolve a URL matching ignored pattern %@", ignoredPattern] error:nil];

        // handleDeepLink: records the URL and completes the session unattributed rather than
        // dropping it silently. -sendOpen is how this line completes a session, so the SDK lands
        // in the same state whichever entry point the filtered URL arrived through.
        self.preferenceHelper.dropURLOpen = YES;
        self.preferenceHelper.externalIntentURI = branchLink;
        self.preferenceHelper.referringURL = branchLink;
        [self sendOpen];

        // The caller asked whether this URL carries link data and is owed an answer. It carries
        // none, and nothing failed, so the answer is the SDK's own not-a-link payload rather than
        // an error or -getLatestReferringParams, which still reports the last link that did
        // resolve.
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                callback(@{ BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK : @0 }, nil);
            });
        }
        return;
    }

    if (branchLink.length > 0) {
        [self.requestQueue cancelPendingDeepLinkRequests];
    }

    // Prepare callback block that will be called when the deeplink request completes
    callbackWithStatus deepLinkCallback = ^(BOOL success, NSError *error) {
        // callback on main, this is generally what the client expects and maintains our previous behavior
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (error) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData failed with error: %@", error] error:error];
                // Call the user's callback with error
                if (callback) {
                    callback(@{}, error);
                }
            } else {
                // Get the session params (which should have the deeplink data)
                NSDictionary *params = [self getLatestReferringParams];
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData completed with params: %@", params] error:nil];
                // Call the user's callback with the params
                if (callback) {
                    callback(params ?: @{}, nil);
                }
            }
        });
    };

    BranchRequestDeepLink *deepLinkReq = [[BranchRequestDeepLink alloc] initWithCallback:deepLinkCallback];
    deepLinkReq.callback = deepLinkCallback;
    deepLinkReq.urlString = branchLink;
    deepLinkReq.uri = branchLink;
    deepLinkReq.traceCallback = bnc_tracingCallback;

    [self.requestQueue enqueue:deepLinkReq withPriority:NSOperationQueuePriorityHigh];
}

#pragma mark - Branch AppDelegate Deep Linking Convenience Methods

// Called from application:didFinishLaunchingWithOptions:
- (void)requestDeepLinkDataWithLaunchOptions:(NSDictionary *)options
                                    callback:(nullable callbackWithParams)callback {
    [[BranchLogger shared] logDebug:@"requestDeepLinkDataWithLaunchOptions called" error:nil];

    NSString *pushURL = nil;
#if !TARGET_OS_TV
    id branchUrlFromPush = [options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey][BRANCH_PUSH_NOTIFICATION_PAYLOAD_KEY];
    if ([branchUrlFromPush isKindOfClass:[NSString class]]) {
        pushURL = (NSString *)branchUrlFromPush;
    }
#endif

    // When opening via URL scheme or Universal Link, the URL-bearing call arrives separately
    // via application:openURL: or continueUserActivity: — skip here to avoid double enqueue.
    BOOL hasURLScheme = [options.allKeys containsObject:UIApplicationLaunchOptionsURLKey];
    BOOL hasUniversalLink = [options.allKeys containsObject:UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if (!pushURL && (hasURLScheme || hasUniversalLink)) {
        return;
    }

    [self requestDeepLinkData:pushURL callback:callback];
}

// Called from application:openURL:options:
// Supports URI Schemes
- (void)requestDeepLinkDataWithURL:(NSURL *)url {

    NSString *urlStr = url.absoluteString;

    if (!urlStr.length) return;

    // Run the same preprocessing as the legacy handleDeepLink: path so referring-URL query params,
    // the URL skiplist / dropURLOpen check, allowed-scheme filtering and link_click_id extraction are
    // applied before the request is enqueued.
    BOOL filtered = NO;
    [self processDeepLinkURL:url sceneIdentifier:nil filtered:&filtered];

    // The URL matched the skiplist. Preferences are recorded, but the URL itself is never sent.
    if (filtered) return;

    [self requestDeepLinkData:urlStr callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Deep Link Params: %@", params] error:nil];
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData failed with error: %@", error] error:error];
        }
    }];
}

// Called from the older application:openURL:sourceApplication:annotation:
// Supports URI Schemes
- (void)requestDeepLinkDataWithURL:(NSURL *)url
                 sourceApplication:(NSString *)sourceApplication
                        annotation:(id)annotation {
    // sourceApplication and annotation are accepted for call-site parity with the AppDelegate method.
    // The legacy application:openURL:sourceApplication:annotation: did not use them either.
    [self requestDeepLinkDataWithURL:url];
}

// Called from application:continueUserActivity:restorationHandler:
// Supports Universal Links
- (void)requestDeepLinkDataWithUserActivity:(NSUserActivity *)userActivity {

    // Run the same preprocessing as the legacy continueUserActivity: path so the initial referrer,
    // universal link URL, referring-URL query params, skiplist and link_click_id checks are applied
    // before the request is enqueued. This runs before webpageURL is read because a Spotlight activity
    // carries its Branch link in userInfo, not in webpageURL.
    BOOL filtered = NO;
    [self processUserActivity:userActivity sceneIdentifier:nil filtered:&filtered];

    if (filtered) return;

    // nil for a Spotlight activity, which enqueues a deferred data lookup rather than resolving a link.
    NSString *urlStr = userActivity.webpageURL.absoluteString;

    [self requestDeepLinkData:urlStr callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Deep Link Params: %@", params] error:nil];
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData failed with error: %@", error] error:error];
        }
    }];
}

// Called from application:didReceiveRemoteNotification:fetchCompletionHandler:
// Supports Push Notifications
- (void)requestDeepLinkDataWithUserInfo:(NSDictionary *)userInfo {

    NSString *urlStr = [userInfo objectForKey:BRANCH_PUSH_NOTIFICATION_PAYLOAD_KEY];

    if (!urlStr.length) return;

    NSURL *url = [NSURL URLWithString:urlStr];
    if (url) {
        BOOL filtered = NO;
        [self processDeepLinkURL:url sceneIdentifier:nil filtered:&filtered];

        if (filtered) return;
    }

    [self requestDeepLinkData:urlStr callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Deep Link Params: %@", params] error:nil];
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData failed with error: %@", error] error:error];
        }
    }];
}

#pragma mark - Branch SceneDelegate Deep Linking Convenience Methods

#if !TARGET_OS_TV
// Called from scene:willConnectToSession:options:
- (void)requestDeepLinkDataWithSceneOptions:(nullable UISceneConnectionOptions *)connectionOptions
                                      scene:(UIScene *)scene
                                   callback:(nullable callbackWithParams)callback
    API_AVAILABLE(ios(13.0), macCatalyst(13.1)) {
    [[BranchLogger shared] logDebug:@"requestDeepLinkDataWithSceneOptions called" error:nil];

    // Build the synthetic launchOptions the removed BranchScene scene-init API used to build,
    // so requestDeepLinkDataWithLaunchOptions applies the same early-return logic.
    NSMutableDictionary *launchOptions = [[NSMutableDictionary alloc] init];
    if (connectionOptions.userActivities.count) {
        launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey] = connectionOptions.userActivities.allObjects;
    }
    if (connectionOptions.URLContexts.count) {
        launchOptions[UIApplicationLaunchOptionsURLKey] = connectionOptions.URLContexts.allObjects;
    }

    // Handles the no-link cold start (enqueues a nil-URL request).
    // Returns early without enqueueing when a URL scheme or Universal Link is present.
    [self requestDeepLinkDataWithLaunchOptions:launchOptions callback:callback];

    // Mirror BranchScene: explicitly resolve the URL from connectionOptions,
    // equivalent to the continueUserActivity: / openURLContexts: calls BranchScene makes
    // once the session is up — the work `+[Branch initialize:]` now covers.
    if (connectionOptions.userActivities.count) {
        NSUserActivity *activity = connectionOptions.userActivities.allObjects.firstObject;
        if ([activity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            // Run the same preprocessing as the legacy continueUserActivity: path before enqueueing.
            BOOL filtered = NO;
            [self processUserActivity:activity sceneIdentifier:scene.session.persistentIdentifier filtered:&filtered];
            if (!filtered) {
                [self requestDeepLinkData:activity.webpageURL.absoluteString callback:callback];
            }
        }
    } else if (connectionOptions.URLContexts.count) {
        UIOpenURLContext *context = connectionOptions.URLContexts.allObjects.firstObject;
        // Run the same preprocessing as the legacy handleDeepLink: path before enqueueing.
        BOOL filtered = NO;
        [self processDeepLinkURL:context.URL sceneIdentifier:scene.session.persistentIdentifier filtered:&filtered];
        if (!filtered) {
            [self requestDeepLinkData:context.URL.absoluteString callback:callback];
        }
    }
}

// Called from scene:openURLContexts:
- (void)requestDeepLinkDataWithScene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)urlContexts {

    UIOpenURLContext *context = urlContexts.allObjects.firstObject;

    if (!context) return;

    // Run the same preprocessing as the legacy handleDeepLink: path before enqueueing.
    BOOL filtered = NO;
    [self processDeepLinkURL:context.URL sceneIdentifier:scene.session.persistentIdentifier filtered:&filtered];

    if (filtered) return;

    [self requestDeepLinkData:context.URL.absoluteString callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Deep Link Params: %@", params] error:nil];
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData failed with error: %@", error] error:error];
        }
    }];
}

// Called from scene:continueUserActivity:
- (void)requestDeepLinkDataWithScene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {

    // Run the same preprocessing as the legacy continueUserActivity: path before enqueueing. This runs
    // before webpageURL is read because a Spotlight activity carries its Branch link in userInfo.
    BOOL filtered = NO;
    [self processUserActivity:userActivity sceneIdentifier:scene.session.persistentIdentifier filtered:&filtered];

    if (filtered) return;

    // nil for a Spotlight activity, which enqueues a deferred data lookup rather than resolving a link.
    NSString *urlStr = userActivity.webpageURL.absoluteString;

    [self requestDeepLinkData:urlStr callback:^(NSDictionary *params, NSError *error) {
        if (error == nil) {
            if (params != nil) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Deep Link Params: %@", params] error:nil];
            }
        } else {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"requestDeepLinkData failed with error: %@", error] error:error];
        }
    }];
}
#endif


#pragma mark - Branch Attribution Methods

- (void) sendOpen {
    NSURL *URL = (self.preferenceHelper.referringURL.length) ? [NSURL URLWithString:self.preferenceHelper.referringURL] : nil;
    if ([self.delegate respondsToSelector:@selector(branch:willStartSessionWithURL:)]) {
        [self.delegate branch:self willStartSessionWithURL:URL];
    }

    [[BranchLogger shared] logDebug:@"sendOpen called" error:nil];

    if ([_preferenceHelper.attributionLevel isEqualToString:BranchAttributionLevelNone]) {
        [[BranchLogger shared] logDebug: @"Branch Attribution Level set to NONE. Branch sendOpen network request prevented. Clearing link identifiers to prevent reuse." error:nil];

        [self clearLinkIdentifiers];
        return;
    }
    // Prepare callback block
    callbackWithStatus openCallback = ^(BOOL success, NSError *error) {
        // callback on main, this is generally what the client expects and maintains our previous behavior
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (error) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"sendOpen failed with error: %@", error] error:error];
                [self handleInitFailure:error];
            } else {
                [self handleInitSuccess];
                NSDictionary *params = [self getLatestReferringParams];
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"sendOpen completed with params: %@", params] error:nil];
            }
        });
    };
    // A launch with no randomized bundle token has never completed an open, so it is a first
    // launch. This is the same criterion -initializeSessionAndCallCallback: uses to choose
    // between BranchOpenRequest and BranchInstallRequest; without it no request on this path
    // is ever an install, and every install-gated behaviour in BranchRequestOpen is unreachable.
    BOOL isInstall = !self.preferenceHelper.randomizedBundleToken;
    BranchRequestOpen *openReq = [[BranchRequestOpen alloc] initWithCallback:openCallback isInstall:isInstall];
    openReq.urlString = nil;
    openReq.traceCallback = bnc_tracingCallback;

    [[BranchLogger shared] logDebug: @"Branch sendOpen network request queued." error:nil];
    [self.requestQueue enqueue:openReq withPriority:NSOperationQueuePriorityHigh];
}

- (void) sendOpen:(NSDictionary *)responseData skipCallback:(BOOL)skipCallback {
    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"sendOpen called with responseData: %@, skipCallback: %d", responseData, skipCallback] error:nil];

    if ([_preferenceHelper.attributionLevel isEqualToString:BranchAttributionLevelNone]) {
        [[BranchLogger shared] logDebug: @"Branch Attribution Level set to NONE. Branch sendOpen network request prevented. Clearing link identifiers to prevent reuse." error:nil];
        [self clearLinkIdentifiers];
        return;
    }

    // Prepare callback block
    callbackWithStatus openCallback = ^(BOOL success, NSError *error) {
        // callback on main, this is generally what the client expects and maintains our previous behavior
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (error) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"sendOpen failed with error: %@", error] error:error];
                [self handleInitFailure:error];
            } else {
                [self handleInitSuccess];
                NSDictionary *params = [self getLatestReferringParams];
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"sendOpen completed with params: %@", params] error:nil];
            }
        });
    };
    // Same first-launch criterion as -sendOpen. An install reaches this path too: a first
    // launch attributed to a clicked link resolves the deep link first and spawns its open here,
    // and that is exactly the open whose payload has to be kept as the install attribution.
    BOOL isInstall = !self.preferenceHelper.randomizedBundleToken;
    BranchRequestOpen *openReq = [[BranchRequestOpen alloc] initWithCallback:openCallback isInstall:isInstall];
    openReq.urlString = nil;
    openReq.traceCallback = bnc_tracingCallback;
    openReq.linkData = responseData;

    [[BranchLogger shared] logDebug: @"Branch sendOpen network request queued." error:nil];
    [self.requestQueue enqueue:openReq withPriority:NSOperationQueuePriorityHigh];
}

@end
