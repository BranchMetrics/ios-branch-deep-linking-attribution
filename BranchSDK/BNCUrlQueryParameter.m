//
//  BNCUrlQueryParameter.m
//  Branch
//
//  Created by Nipun Singh on 3/15/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCUrlQueryParameter.h"

@implementation BNCUrlQueryParameter

- (BOOL)isWithinValidityWindow {
    if (self.validityWindow == 0) {
        return YES;
    }
    
    NSDate *expirationDate = [self.timestamp dateByAddingTimeInterval:self.validityWindow];
    NSDate *now = [NSDate date];
    if ([now compare:expirationDate] == NSOrderedAscending) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<BNCUrlQueryParameter name=%@, value=%@, timestamp=%@, isDeepLink=%d, validityWindow=%f>",
            self.name, self.value, self.timestamp, self.isDeepLink, self.validityWindow];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    BNCUrlQueryParameter *other = (BNCUrlQueryParameter *)object;

    return [self.name isEqualToString:other.name] &&
    [self.value isEqualToString:other.value] &&
    [self.timestamp isEqualToDate:other.timestamp] &&
    self.isDeepLink == other.isDeepLink &&
    self.validityWindow == other.validityWindow;
}

@end
