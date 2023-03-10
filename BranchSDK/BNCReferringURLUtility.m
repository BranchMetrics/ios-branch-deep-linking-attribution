//
//  BNCReferringURLUtility.m
//  Branch
//
//  Created by Nipun Singh on 3/9/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCReferringURLUtility.h"
#import "BNCPreferenceHelper.h"

//@interface BNCReferringURLQueryParameter: NSObject
//
//@property (copy, nonatomic) NSString *name;
//@property (copy, nonatomic) NSString *value;
//@property (assign, nonatomic) NSTimeInterval validityWindow;
//@property (strong, nonatomic) NSDate *startDate;
//
//@end

@interface BNCReferringURLUtility()

@property (strong, readwrite, nonatomic) NSMutableDictionary<NSString *, NSMutableDictionary *> *urlQueryParameters;

@end

@implementation BNCReferringURLUtility

- (instancetype)init {
    self = [super init];
    if (self) {
        self.urlQueryParameters = [BNCPreferenceHelper sharedInstance].referringURLQueryParameters;
        [self initializeURLQueryParameters];
    }
    
    return self;
}

- (void)initializeURLQueryParameters {
    self.urlQueryParameters = [NSMutableDictionary<NSString *, NSMutableDictionary *> new];
   
    //Don't init if it was loaded from disc
    NSMutableDictionary *gbraid = [NSMutableDictionary new];
    gbraid[@"name"] = @"gbraid";
    gbraid[@"is_deeplink"] = [NSNumber numberWithBool:YES];
    [self.urlQueryParameters setValue: gbraid forKey:@"gbraid"];
    
    NSMutableDictionary *gclid = [NSMutableDictionary new];
    gbraid[@"name"] = @"gclid";
    [self.urlQueryParameters setValue: gclid forKey:@"gclid"];
    
    //Consider how to load the existing gbraid
}

- (void)parseReferringURL:(NSURL *)url {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    for(NSURLQueryItem *item in components.queryItems){

        NSMutableDictionary *param = self.urlQueryParameters[item.name];
        if (param != nil) {
            param[@"value"] = item.value;
            param[@"initDate"] = [NSDate date];
        }
    }
    
    [BNCPreferenceHelper sharedInstance].referringURLQueryParameters = self.urlQueryParameters;
}

- (NSDictionary *)referringURLDictionary {
    return [NSDictionary new];
}

- (NSDictionary *)getQueryParams {
    //Get
    return nil;
}

@end
