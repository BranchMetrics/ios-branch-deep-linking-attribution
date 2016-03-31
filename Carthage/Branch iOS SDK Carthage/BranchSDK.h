//
//  Branch iOS SDK Carthage.h
//  Branch iOS SDK Carthage
//
//  Created by Ahmed Nawar on 2/16/16.
//  Copyright © 2016 Ahmed Nawar. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Branch iOS SDK Carthage.
FOUNDATION_EXPORT double Branch_iOS_SDK_CarthageVersionNumber;

//! Project version string for Branch iOS SDK Carthage.
FOUNDATION_EXPORT const unsigned char Branch_iOS_SDK_CarthageVersionString[];

//Branch SDK Group

#import "BNCConfig.h"
#import "BNCContentDiscoveryManager.h"
#import "BNCEncodingUtils.h"
#import "BNCError.h"
#import "BNCLinkCache.h"
#import "BNCLinkData.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerInterface.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerResponse.h"
#import "BNCStrongMatchHelper.h"
#import "BNCSystemObserver.h"
#import "Branch.h"
#import "BranchActivityItemProvider.h"
#import "BranchConstants.h"
#import "BranchCSSearchableItemAttributeSet.h"
#import "BranchDeepLinkingController.h"
#import "BranchLinkProperties.h"
#import "BranchUniversalObject.h"

//Requests Group
#import "BNCServerRequest.h"
#import "BranchApplyPromoCodeRequest.h"
#import "BranchCloseRequest.h"
#import "BranchCreditHistoryRequest.h"
#import "BranchGetPromoCodeRequest.h"
#import "BranchInstallRequest.h"
#import "BranchLoadActionsRequest.h"
#import "BranchLoadRewardsRequest.h"
#import "BranchLogoutRequest.h"
#import "BranchOpenRequest.h"
#import "BranchRedeemRewardsRequest.h"
#import "BranchRegisterViewRequest.h"
#import "BranchSetIdentityRequest.h"
#import "BranchShortUrlRequest.h"
#import "BranchShortUrlSyncRequest.h"
#import "BranchSpotlightUrlRequest.h"
#import "BranchUserCompletedActionRequest.h"
#import "BranchValidatePromoCodeRequest.h"
