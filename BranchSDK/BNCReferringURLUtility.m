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

@interface BNCReferringURLUtility()

@property (strong, readwrite, nonatomic) NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *urlQueryParameters;

@end

@implementation BNCReferringURLUtility

- (instancetype)init {
    self = [super init];

    if (self) {
        self.urlQueryParameters = [self deserializeFromJson:[BNCPreferenceHelper sharedInstance].referringURLQueryParameters];
    }
    
    return self;
}

- (void)parseReferringURL:(NSURL *)url {
    NSLog(@"Testing: Parsing referring URL %@", url);
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for(NSURLQueryItem *item in components.queryItems){
        
        if ([self isSupportedQueryParameter:item.name]) {
            BNCUrlQueryParameter *param = [self findUrlQueryParam:item.name];
            param.value = item.value;
            param.timestamp = [NSDate date];
            param.isDeepLink = YES;
            
            //If there is no validity window, set to default.
            if (param.validityWindow == 0) {
                param.validityWindow = [self defaultValidityWindowForParam:item.name];
            }
            
            [self.urlQueryParameters setValue:param forKey:item.name];
        }
    }
    
    [BNCPreferenceHelper sharedInstance].referringURLQueryParameters = [self serializeToJson:self.urlQueryParameters];
    NSLog(@"Testing: Saved new parsed params: %@", self.urlQueryParameters);
}


- (NSDictionary *)getURLQueryParamsForRequest:(NSString *)endpoint {
    NSMutableDictionary *returnedParams = [NSMutableDictionary new];

    NSString *gclid = [self addGclidValueFor:endpoint];
    if (gclid) {
        returnedParams[BRANCH_REQUEST_KEY_GCLID] = gclid;
    }
    
    NSDictionary *gbraid = [self addGbraidValuesFor:endpoint];
    if (gbraid) {
        [returnedParams addEntriesFromDictionary:gbraid];
    }
//
    //For future parameters, their functions can be added here
    
    NSLog(@"Added following params to %@: %@", endpoint, returnedParams);
    return returnedParams;
}

- (NSString *)addGclidValueFor:(NSString *)endpoint {
    if (([endpoint containsString:@"/v2/event"]) || ([endpoint containsString:@"/v1/open"])) {
        return self.urlQueryParameters[BRANCH_REQUEST_KEY_GCLID].value;
    }
    return nil;
}

- (NSDictionary *)addGbraidValuesFor:(NSString *)endpoint {
    NSMutableDictionary *returnedParams = [NSMutableDictionary new];

    if (([endpoint containsString:@"/v2/event"]) || ([endpoint containsString:@"/v1/open"])) {

        BNCUrlQueryParameter *gbraid = self.urlQueryParameters[BRANCH_REQUEST_KEY_REFERRER_GBRAID];

        if (gbraid.value != nil) {
            // Check if its valid or expired
            NSDate *expirationDate = [gbraid.timestamp dateByAddingTimeInterval:gbraid.validityWindow];
            NSDate *now = [NSDate date];
            if ([now compare:expirationDate] == NSOrderedAscending) {
                returnedParams[BRANCH_REQUEST_KEY_REFERRER_GBRAID] = gbraid.value;

                //TODO: Check what our server expects gbraid_timestamp as
                NSNumber *timestampInMilliSec = @([gbraid.timestamp timeIntervalSince1970] * 1000.0);
                returnedParams[BRANCH_REQUEST_KEY_REFERRER_GBRAID_TIMESTAMP] = timestampInMilliSec.stringValue;
                
                if ([endpoint containsString:@"/v1/open"]) {
                    returnedParams[BRANCH_REQUEST_KEY_IS_DEEPLINK_GBRAID] = @(gbraid.isDeepLink);
                    gbraid.isDeepLink = NO;
                    
                    //Forcing write to disk
                    [BNCPreferenceHelper sharedInstance].referringURLQueryParameters = [self serializeToJson:self.urlQueryParameters];
                }
            }
        }
    }
    
    return returnedParams;
}

// Helper Methods
- (BOOL)isSupportedQueryParameter:(NSString *)param {
    NSArray *validURLQueryParameters = @[@"gbraid", @"gclid", @"sccid"];
    if ([validURLQueryParameters containsObject:param]) {
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

- (NSTimeInterval)defaultValidityWindowForParam:(NSString *)paramName {
    if ([paramName isEqualToString:BRANCH_REQUEST_KEY_REFERRER_GBRAID]) {
        return 2592000; //30 Days
    } else {
        return 0; //Default, means indefinite.
    }
}

- (NSMutableDictionary *)serializeToJson:(NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)urlQueryParameters {
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    for (BNCUrlQueryParameter *param in urlQueryParameters.allValues) {
        NSMutableDictionary *paramDict = [NSMutableDictionary new];
        paramDict[@"name"] = param.name;
        paramDict[@"value"] = param.value;
        paramDict[@"timestamp"] = param.timestamp;
        paramDict[@"isDeepLink"] = @(param.isDeepLink);
        paramDict[@"validityWindow"] = @(param.validityWindow);
        
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
            param.name = paramDict[@"name"];
            param.value = paramDict[@"value"];
            param.timestamp = paramDict[@"timestamp"];
            param.isDeepLink = paramDict[@"isDeepLink"];
            param.validityWindow = [paramDict[@"validityWindow"] doubleValue];
            
            result[param.name] = param;
        }
    }
    
    return result;
}

@end
