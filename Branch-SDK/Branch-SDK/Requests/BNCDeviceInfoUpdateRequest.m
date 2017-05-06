//
//  BNCDeviceInfoUpdateRequest.m
//  Branch-TestBed
//
//  Created by edward on 5/1/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCDeviceInfoUpdateRequest.h"
#import "BranchConstants.h"
#import "NSMutableDictionary+Branch.h"

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
    [params bnc_safeSetObject:preferenceHelper.deviceFingerprintID forKey:BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID];
    [params bnc_safeSetObject:preferenceHelper.identityID forKey:BRANCH_REQUEST_KEY_BRANCH_IDENTITY];
    [params bnc_safeSetObject:preferenceHelper.sessionID forKey:BRANCH_REQUEST_KEY_SESSION_ID];
    [params bnc_safeSetObject:self.deviceInfoDictionary forKey:@"device_info"];

	NSString *URL = [preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_DEVICE_UPDATE];
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
		: [NSDictionary dictionary];
		
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
