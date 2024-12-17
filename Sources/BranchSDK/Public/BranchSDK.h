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
#import "Branch.h"
#import "BranchPluginSupport.h"

#import "BranchScene.h"
#import "BranchDelegate.h"

#import "BranchEvent.h"
#import "BranchLinkProperties.h"
#import "BranchUniversalObject.h"
#import "BranchQRCode.h"

#import "BranchLastAttributedTouchData.h"

#import "BranchDeepLinkingController.h"
#import "BranchLogger.h"

#import "BranchShareLink.h"
#import "BranchCSSearchableItemAttributeSet.h"
#import "BranchActivityItemProvider.h"
#import "BranchPasteControl.h"

// Used by Branch.h for debug and testing APIs. Need to move these.
#import "BNCInitSessionResponse.h"
#import "BNCCallbacks.h"
#import "BNCLinkCache.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCServerRequestQueue.h"

// Cascading public headers...

// BranchUniversalObject uses constants defined in BNCCurrency.h and BNCProductCategory.h
#import "BNCCurrency.h"
#import "BNCProductCategory.h"

#import "BNCServerRequest.h"
// BNCServerRequest includes BNCServerInterface.h
//#import "BNCServerInterface.h"
// BNCServerInterface.h includes BNCServerResponse.h and BNCPreferenceHelper.h
#import "BNCServerResponse.h"
//#import "BNCPreferenceHelper.h"

// BNCLinkCache.h uses BNCLinkData.h
#import "BNCLinkData.h"
