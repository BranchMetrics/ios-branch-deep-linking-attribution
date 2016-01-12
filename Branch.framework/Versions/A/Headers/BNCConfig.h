//
//  BNCConfig.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#ifndef Branch_SDK_Config_h
#define Branch_SDK_Config_h

#define SDK_VERSION             @"0.11.13"

#define BNC_PROD_ENV
//#define BNC_STAGE_ENV
//#define BNC_DEV_ENV

#ifdef BNC_PROD_ENV
#define BNC_API_BASE_URL        @"https://api.branch.io"
#endif

#ifdef BNC_STAGE_ENV
#define BNC_API_BASE_URL        @"http://api.dev.branchmetrics.io"
#endif

#define BNC_LINK_URL             @"https://bnc.lt"

#ifdef BNC_DEV_ENV
#define BNC_API_BASE_URL        @"http://localhost:3001"
#endif

#define BNC_API_VERSION         @"v1"

#endif
