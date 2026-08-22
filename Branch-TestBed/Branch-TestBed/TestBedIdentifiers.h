//
//  TestBedIdentifiers.h
//  Branch-TestBed
//
//  Single source of truth for accessibilityIdentifier values used across
//  the TestBed UI. Referenced from Main.storyboard and from the
//  TestBed-GPTDriverTests hybrid test target.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Buttons (Main ViewController)

extern NSString * const kTestBedBtnCreateBranchLink;
extern NSString * const kTestBedBtnShareLink;
extern NSString * const kTestBedBtnShareLinkWithMetadata;
extern NSString * const kTestBedBtnOpenBranchLink;
extern NSString * const kTestBedBtnCreateQRCode;
extern NSString * const kTestBedBtnViewFirstReferringParams;
extern NSString * const kTestBedBtnViewLatestReferringParams;
extern NSString * const kTestBedBtnTogglePartnerParams;
extern NSString * const kTestBedBtnSimulateContentAccess;
extern NSString * const kTestBedBtnSimulateContentAccessAlt;
extern NSString * const kTestBedBtnSetUserId;
extern NSString * const kTestBedBtnSendCommerceEvent;
extern NSString * const kTestBedBtnSendContentEvent;
extern NSString * const kTestBedBtnSendLifecycleEvent;
extern NSString * const kTestBedBtnInAppPurchaseEvent;
extern NSString * const kTestBedBtnInAppSubscriptionEvent;
extern NSString * const kTestBedBtnRegisterWithSpotlight;
extern NSString * const kTestBedBtnLoadLogs;
extern NSString * const kTestBedBtnDisableTracking;
extern NSString * const kTestBedBtnLogout;
extern NSString * const kTestBedBtnGoToPasteControl;
extern NSString * const kTestBedBtnConsumerProtectionLevel;
extern NSString * const kTestBedBtnNotificationSend;
extern NSString * const kTestBedBtnPluginNotifyInit;

#pragma mark - Buttons (Paste Control scene)

extern NSString * const kTestBedBtnShowLogs;

#pragma mark - Text Fields

extern NSString * const kTestBedTxtBranchLink;

NS_ASSUME_NONNULL_END
