//
//  Config.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#ifndef Branch_SDK_Config_h
#define Branch_SDK_Config_h

//#define DEV_ENV
//#define STAGE_ENV
#define PROD_ENV

#ifdef DEV_ENV
#define API_BASE_URL            @"http://localhost:3001";
#define DEBUG_MODE
#endif

#ifdef STAGE_ENV
#define API_BASE_URL            @"http://api.dev.branchmetrics.io";
#define DEBUG_MODE
#endif

#ifdef PROD_ENV
#define API_BASE_URL            @"https://api.branch.io";
#endif

#define API_VERSION             @"v1"

#ifdef DEBUG_MODE
#define Debug( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define Debug( s, ... )
#endif

#define Error( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )



#endif
