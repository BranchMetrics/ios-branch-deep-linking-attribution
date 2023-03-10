//
//  BNCReferringURLUtility.h
//  Branch
//
//  Created by Nipun Singh on 3/9/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface BNCReferringURLUtility : NSObject

//Parses the referring URL query parameters from a URL
- (void)parseReferringURL:(NSURL *)url;

//Convert the URL parameters to dictionary
- (NSDictionary *)referringURLDictionary;

- (NSDictionary *)getQueryParams(NSString *)event;

@end

NS_ASSUME_NONNULL_END
