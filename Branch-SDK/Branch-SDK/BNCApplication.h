/**
 @file          BNCApplication.h
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

@interface BNCApplication : NSObject

/// A reference to the current running application.
+ (BNCApplication*_Nonnull) currentApplication;

/// The bundle identifier of the current
@property (atomic, readonly) NSString*_Nullable bundleID;

/// The development team ID of the application.
@property (atomic, readonly) NSString*_Nullable teamID;

/// The unique application identifier. Typically this is `teamID.bundleID`: XYZ123.com.company.app.
@property (atomic, readonly) NSString*_Nullable applicationID;

/// The bundle display name from the info plist.
@property (atomic, readonly) NSString*_Nullable displayName;

/// The bundle short display name from the info plist.
@property (atomic, readonly) NSString*_Nullable shortDisplayName;

/// The short version ID as is typically shown to the user, like in iTunes or the app store.
@property (atomic, readonly) NSString*_Nullable displayVersionString;

/// The version ID for developers use.
@property (atomic, readonly) NSString*_Nullable versionString;

/// The creation date of the current executable.
@property (atomic, readonly) NSDate*_Nullable currentBuildDate;

/// The creating date of the exectuble the first time it was recorded by Branch.
@property (atomic, readonly) NSDate*_Nullable firstInstallBuildDate;

/// The date this app was installed on this device.
@property (atomic, readonly) NSDate*_Nullable currentInstallDate;

/// The date this app was first installed on this device.
@property (atomic, readonly) NSDate*_Nullable firstInstallDate;

/// The push notification environment. Usually `development` or `production` or `nil`.
@property (atomic, readonly) NSString*_Nullable pushNotificationEnvironment;

/// The keychain access groups from the entitlements.
@property (atomic, readonly) NSArray<NSString*>*_Nullable keychainAccessGroups;

/// The associated domains from the entitlements.
@property (atomic, readonly) NSArray<NSString*>*_Nullable associatedDomains;

/// Returns a dictionary of device / identity pairs.
@property (atomic, readonly) NSDictionary<NSString*, NSString*>*_Nonnull deviceKeyIdentityValueDictionary;

/// Adds a deviceID and identityID pair to the dictionary.
- (void) addDeviceID:(NSString*_Nullable)deviceID identityID:(NSString*_Nullable)identityID;

@end
