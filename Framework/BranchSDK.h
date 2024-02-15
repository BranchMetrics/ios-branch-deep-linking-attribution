//
//  BranchSDK.h
//  BranchSDK
//
//  Created by Ernest Cho on 7/29/22.
//

#import <Foundation/Foundation.h>

//! Project version number for BranchSDK.
FOUNDATION_EXPORT double BranchSDKVersionNumber;

//! Project version string for BranchSDK.
FOUNDATION_EXPORT const unsigned char BranchSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BranchSDK/PublicHeader.h>
#import <BranchSDK/Branch.h>
#import <BranchSDK/BranchPluginSupport.h>

#import <BranchSDK/BranchScene.h>
#import <BranchSDK/BranchDelegate.h>

#import <BranchSDK/BranchEvent.h>
#import <BranchSDK/BranchLinkProperties.h>
#import <BranchSDK/BranchUniversalObject.h>
#import <BranchSDK/BranchQRCode.h>
#import <BranchSDK/BranchLogger.h>

#import <BranchSDK/BranchLastAttributedTouchData.h>

#import <BranchSDK/BranchDeepLinkingController.h>

#if !TARGET_OS_TV
// tvOS does not support these features
#import <BranchSDK/BranchShareLink.h>
#import <BranchSDK/BranchCSSearchableItemAttributeSet.h>
#import <BranchSDK/BranchActivityItemProvider.h>

#import <BranchSDK/BranchPasteControl.h>
#endif

// Used by Branch.h for debug and testing APIs. Need to move these.
#import <BranchSDK/BNCInitSessionResponse.h>
#import <BranchSDK/BNCCallbacks.h>
#import <BranchSDK/BNCLinkCache.h>
#import <BranchSDK/BNCPreferenceHelper.h>
#import <BranchSDK/BNCServerInterface.h>
#import <BranchSDK/BNCServerRequestQueue.h>

// Cascading public headers...

// BranchUniversalObject uses constants defined in BNCCurrency.h and BNCProductCategory.h
#import <BranchSDK/BNCCurrency.h>
#import <BranchSDK/BNCProductCategory.h>

#import <BranchSDK/BNCServerRequest.h>
// BNCServerRequest includes BNCServerInterface.h
//#import <BranchSDK/BNCServerInterface.h>
// BNCServerInterface.h includes BNCServerResponse.h and BNCPreferenceHelper.h
#import <BranchSDK/BNCServerResponse.h>
//#import <BranchSDK/BNCPreferenceHelper.h>

// BNCLinkCache.h uses BNCLinkData.h
#import <BranchSDK/BNCLinkData.h>
