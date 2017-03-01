//
//  BNCConfig.c
//  Branch-TestBed
//
//  Created by edward on 12/12/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#include "BNCConfig.h"

#if defined(BNCTesting)
NSString * const BNC_API_BASE_URL    = @"https://auhong.api.beta.branch.io";
#else
NSString * const BNC_API_BASE_URL    = @"https://api.branch.io";
#endif

NSString * const BNC_API_VERSION     = @"v1";
NSString * const BNC_LINK_URL        = @"https://bnc.lt";
NSString * const BNC_SDK_VERSION     = @"0.13.5";
