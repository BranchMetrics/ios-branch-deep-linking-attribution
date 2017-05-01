//
//  BNCDeviceInfoUpdateRequest.m
//  Branch-TestBed
//
//  Created by edward on 5/1/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCDeviceInfoUpdateRequest.h"
#import "BranchConstants.h"

#pragma mark BNCDeviceInfoUpdateRequest

@interface BNCDeviceInfoUpdateRequest ()
@property (strong) NSDictionary *deviceInfoDictionary;
@property (copy)   void (^completion)(NSDictionary* response, NSError* error);
@end

#pragma mark - BNCDeviceInfoUpdateRequest

@implementation BNCDeviceInfoUpdateRequest

- (instancetype) initWithDeviceInfo:(BNCDeviceInfo*)deviceInfo
                         completion:(void (^) (NSDictionary*response, NSError*error))completion {
	self = [super init];
	if (!self) return self;

	self.deviceInfoDictionary = [deviceInfo dictionary];
	self.completion = completion;
	return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface
			    key:(NSString *)key
           callback:(BNCServerCallback)callback {

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[BRANCH_REQUEST_KEY_ACTION] = @"device_info_update";
    params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;

	if (self.deviceInfoDictionary)
		params[@"device_info"] = self.deviceInfoDictionary;

	NSString *URL = [preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION];
    [serverInterface postRequest:params
							 url:URL
							 key:key
						callback:callback];
}

- (void)processResponse:(BNCServerResponse*)response
				  error:(NSError*)error {

	NSDictionary *dictionary =
		([response.data isKindOfClass:[NSDictionary class]])
		? (NSDictionary*) response.data
		: nil;
		
	if (self.completion)
		self.completion(dictionary, error);
}

#pragma mark BNCDeviceInfoUpdateRequest<NSCoding>

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (!self) return self;

	self.deviceInfoDictionary = [decoder decodeObjectForKey:@"deviceInfoDictionary"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.deviceInfoDictionary forKey:@"deviceInfoDictionary"];
}

@end
