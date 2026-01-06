//
//  BNCReferringURLUtility.m
//  Branch
//
//  Created by Nipun Singh on 3/9/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCReferringURLUtility.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCUrlQueryParameter.h"
#import "BranchLogger.h"
#import <UIKit/UIKit.h>

@interface BNCReferringURLUtility()
@property (strong, readwrite, nonatomic) NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *urlQueryParameters;
@property (strong, readwrite, nonatomic) BNCPreferenceHelper *preferenceHelper;
@end

@implementation BNCReferringURLUtility

- (instancetype)init {
    self = [super init];
    if (self) {
        self.preferenceHelper = [BNCPreferenceHelper sharedInstance];
        self.urlQueryParameters = [self deserializeFromJson:self.preferenceHelper.referringURLQueryParameters];
        [self checkForAndMigrateOldGbraid];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(clearSccid)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(clearSccid)
                                   name:UIApplicationWillTerminateNotification
                                 object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)parseReferringURL:(NSURL *)url {
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Parsing URL %@", url] error:nil];
    
    if (!url) {
        [[BranchLogger shared] logVerbose:@"URL is nil" error:nil];
        return;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for  (NSURLQueryItem *item in components.queryItems) {
        if ([self isSupportedQueryParameter:item.name]) {
            [self processQueryParameter:item];
        }
        
        /*
         * Meta places their AEM value in an url encoded json.
         * `al_applink_data` is the query parameter
         * `campaign_ids` is the json field
         * we map this value to `meta_campaign_ids`
         */
        if ([self isMetaQueryParameter:item.name]) {
            [self processMetaQueryParameter:item];
        }
    }

    self.preferenceHelper.referringURLQueryParameters = [self serializeToJson:self.urlQueryParameters];
}

- (void)processQueryParameter:(NSURLQueryItem *)item {
    NSString *name = [item.name lowercaseString];
    
    BNCUrlQueryParameter *param = [self findUrlQueryParam:name];
    param.value = item.value;
    param.timestamp = [NSDate date];
    param.isDeepLink = YES;

    // If there is no validity window, set to default.
    if (param.validityWindow == 0) {
        param.validityWindow = [self defaultValidityWindowForParam:name];
    }
    
    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Parsed Referring URL: %@", param] error:nil];
    [self.urlQueryParameters setValue:param forKey:name];
}

- (void)processMetaQueryParameter:(NSURLQueryItem *)item {
    NSString *campaignIDs = [self metaCampaignIDsFromDictionary:[self dictionaryFromEncodedJsonString:item.value]];
    if (campaignIDs) {
        BNCUrlQueryParameter *param = [self findUrlQueryParam:BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS];
        param.value = campaignIDs;
        param.timestamp = [NSDate date];
        param.isDeepLink = YES;
        param.validityWindow = [self defaultValidityWindowForParam:BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS];
        
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Parsed Referring URL: %@", param] error:nil];
        [self.urlQueryParameters setValue:param forKey:BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS];
    }
}

- (NSString *)metaCampaignIDsFromDictionary:(NSDictionary *)json {
    NSString *campaignIDs = nil;
    id value = [json objectForKey:@"campaign_ids"];
    if ([value isKindOfClass:NSString.class]) {
        campaignIDs = (NSString *)value;
    }
    return campaignIDs;
}

- (NSDictionary *)dictionaryFromEncodedJsonString:(NSString *)encodedJsonString {
    NSString *jsonString = [encodedJsonString stringByRemovingPercentEncoding];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (jsonData) {
        NSError *error;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (![json isKindOfClass:[NSDictionary class]]) {
            [[BranchLogger shared] logVerbose:@"Encoded json string did not decode to a dictionary; skipping" error:nil];
            json = nil;
        }

        if (!error) {
            return json;
        } else {
            [[BranchLogger shared] logError:@"Failed to parse Meta AEM JSON" error:error];
        }
    }
    return nil;
}

- (NSDictionary *)referringURLQueryParamsForEndpoint:(NSString *)endpoint {
    NSMutableDictionary *params = [NSMutableDictionary new];
        
    params[BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS] = [self metaCampaignIDsForEndpoint:endpoint];
    params[BRANCH_REQUEST_KEY_GCLID] = [self gclidValueForEndpoint:endpoint];
    [params addEntriesFromDictionary:[self gbraidValuesForEndpoint:endpoint]];
    params[BRANCH_REQUEST_KEY_SCCID] = [self sccidValueForEndpoint:endpoint];
    
    return params;
}

- (NSString *)metaCampaignIDsForEndpoint:(NSString *)endpoint {
    if (([endpoint containsString:@"/v2/event"]) || ([endpoint containsString:@"/v1/open"])) {
        BNCUrlQueryParameter *metaCampaignIDs = self.urlQueryParameters[BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS];
        if (metaCampaignIDs.value != nil && [metaCampaignIDs isWithinValidityWindow]) {
            return self.urlQueryParameters[BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS].value;
        }
    }
    return nil;
}

- (NSString *)gclidValueForEndpoint:(NSString *)endpoint {
    if (([endpoint containsString:@"/v2/event"]) || ([endpoint containsString:@"/v1/open"])) {
        return self.urlQueryParameters[BRANCH_REQUEST_KEY_GCLID].value;
    }
    return nil;
}

- (NSDictionary *)gbraidValuesForEndpoint:(NSString *)endpoint {
    NSMutableDictionary *returnedParams = [NSMutableDictionary new];

    if (([endpoint containsString:@"/v2/event"]) || ([endpoint containsString:@"/v1/open"])) {

        BNCUrlQueryParameter *gbraid = self.urlQueryParameters[BRANCH_REQUEST_KEY_REFERRER_GBRAID];
        if (gbraid.value != nil && [gbraid isWithinValidityWindow]) {
            
            returnedParams[BRANCH_REQUEST_KEY_REFERRER_GBRAID] = gbraid.value;
            
            NSNumber *timestampInMilliSec = @([gbraid.timestamp timeIntervalSince1970] * 1000.0);
            returnedParams[BRANCH_REQUEST_KEY_REFERRER_GBRAID_TIMESTAMP] = timestampInMilliSec.stringValue;
            
            if ([endpoint containsString:@"/v1/open"]) {
                returnedParams[BRANCH_REQUEST_KEY_IS_DEEPLINK_GBRAID] = @(gbraid.isDeepLink);
                gbraid.isDeepLink = NO;

                self.preferenceHelper.referringURLQueryParameters = [self serializeToJson:self.urlQueryParameters];
            }
        }
    }
    
    return returnedParams;
}

- (NSString *)sccidValueForEndpoint:(NSString *)endpoint {
    if (([endpoint containsString:@"/v2/event"]) || ([endpoint containsString:@"/v1/open"]) || ([endpoint containsString:@"/v1/install"]) ) {
        return self.urlQueryParameters[BRANCH_REQUEST_KEY_SCCID].value;
    }
    return nil;
}

- (BOOL)isSupportedQueryParameter:(NSString *)param {
    NSArray *validURLQueryParameters = @[BRANCH_REQUEST_KEY_REFERRER_GBRAID, BRANCH_REQUEST_KEY_GCLID, BRANCH_REQUEST_KEY_SCCID];
    return [self isSupportedQueryParameter:param validParams:validURLQueryParameters];
}

- (BOOL)isMetaQueryParameter:(NSString *)param {
    NSArray *validURLQueryParameters = @[@"al_applink_data"];
    return [self isSupportedQueryParameter:param validParams:validURLQueryParameters];
}

- (BOOL)isSupportedQueryParameter:(NSString *)param validParams:(NSArray *)validParams {
    NSString *lowercased = [param lowercaseString];
    if ([validParams containsObject:lowercased]) {
        return YES;
    } else {
        return NO;
    }
}

- (BNCUrlQueryParameter *)findUrlQueryParam:(NSString *)paramName {
    if ([self.urlQueryParameters.allKeys containsObject:paramName]) {
        return self.urlQueryParameters[paramName];
    } else {
        BNCUrlQueryParameter *param = [BNCUrlQueryParameter new];
        param.name = paramName;
        return param;
    }
}

- (NSTimeInterval)defaultValidityWindowForParam:(NSString *)param {
    if ([param isEqualToString:BRANCH_REQUEST_KEY_REFERRER_GBRAID]) {
        return 30 * 24 * 60 * 60; // 30 days
    } else if ([param isEqualToString:BRANCH_REQUEST_KEY_META_CAMPAIGN_IDS]) {
        return 7 * 24 * 60 * 60; // 7 days
    } else {
        return 0; // default, means indefinite.
    }
}

- (NSMutableDictionary *)serializeToJson:(NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)urlQueryParameters {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    for (BNCUrlQueryParameter *param in urlQueryParameters.allValues) {
        NSMutableDictionary *paramDict = [NSMutableDictionary new];
        paramDict[BRANCH_URL_QUERY_PARAMETERS_NAME_KEY] = param.name;
        paramDict[BRANCH_URL_QUERY_PARAMETERS_VALUE_KEY] = param.value ?: [NSNull null];
        paramDict[BRANCH_URL_QUERY_PARAMETERS_TIMESTAMP_KEY] = param.timestamp;
        paramDict[BRANCH_URL_QUERY_PARAMETERS_IS_DEEPLINK_KEY] = @(param.isDeepLink);
        paramDict[BRANCH_URL_QUERY_PARAMETERS_VALIDITY_WINDOW_KEY] = @(param.validityWindow);
        
        json[param.name] = paramDict;
    }
    
    return json;
}

- (NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)deserializeFromJson:(NSDictionary *)json {
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    for (id temp in json.allValues) {
        if ([temp isKindOfClass:NSDictionary.class] || [temp isKindOfClass:NSMutableDictionary.class]) {
            NSDictionary *paramDict = (NSDictionary *)temp;
            BNCUrlQueryParameter *param = [BNCUrlQueryParameter new];
            param.name = paramDict[BRANCH_URL_QUERY_PARAMETERS_NAME_KEY];

            if (paramDict[BRANCH_URL_QUERY_PARAMETERS_VALUE_KEY] != nil) {
                param.value = paramDict[BRANCH_URL_QUERY_PARAMETERS_VALUE_KEY];
            }

            param.timestamp = paramDict[BRANCH_URL_QUERY_PARAMETERS_TIMESTAMP_KEY];
            param.validityWindow = [paramDict[BRANCH_URL_QUERY_PARAMETERS_VALIDITY_WINDOW_KEY] doubleValue];

            if (paramDict[BRANCH_URL_QUERY_PARAMETERS_IS_DEEPLINK_KEY] != nil) {
                param.isDeepLink = ((NSNumber *)paramDict[BRANCH_URL_QUERY_PARAMETERS_IS_DEEPLINK_KEY]).boolValue;
            } else {
                param.isDeepLink = NO;
            }
            
            result[param.name] = param;
        }
    }
    
    return result;
}

- (void)checkForAndMigrateOldGbraid {
    if (self.preferenceHelper.referrerGBRAID != nil &&
        self.urlQueryParameters[BRANCH_REQUEST_KEY_REFERRER_GBRAID].value == nil) {
        
        NSString *existingGbraidValue = self.preferenceHelper.referrerGBRAID;
        NSTimeInterval existingGbraidValidityWindow = self.preferenceHelper.referrerGBRAIDValidityWindow;
        NSDate *existingGbraidInitDate = self.preferenceHelper.referrerGBRAIDInitDate;
        
        BNCUrlQueryParameter *gbraid = [BNCUrlQueryParameter new];
        gbraid.name = BRANCH_REQUEST_KEY_REFERRER_GBRAID;
        gbraid.value = existingGbraidValue;
        gbraid.timestamp = existingGbraidInitDate;
        gbraid.validityWindow = existingGbraidValidityWindow;
        gbraid.isDeepLink = NO;
        
        [self.urlQueryParameters setValue:gbraid forKey:BRANCH_REQUEST_KEY_REFERRER_GBRAID];
        self.preferenceHelper.referringURLQueryParameters = [self serializeToJson:self.urlQueryParameters];

        // delete old gbraid entry
        self.preferenceHelper.referrerGBRAID = nil;
        self.preferenceHelper.referrerGBRAIDValidityWindow = 0;
        self.preferenceHelper.referrerGBRAIDInitDate = nil;
        
        [[BranchLogger shared] logVerbose:@"Migrated old Gbraid to a BNCUrlQueryParameter" error:nil];
    }
}

- (void)clearSccid {
    [self.urlQueryParameters removeObjectForKey:BRANCH_REQUEST_KEY_SCCID];
    self.preferenceHelper.referringURLQueryParameters = [self serializeToJson:self.urlQueryParameters];
}


@end
