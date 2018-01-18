/**
 @file          BNCApplication.h
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
 @bug           Add nullablity to the header file.
*/

#import <Foundation/Foundation.h>

@interface BNCApplication : NSObject

/// A reference to the current running application.
+ (BNCApplication*) currentApplication;

/// The bundle identifier of the current
@property (atomic, readonly) NSString* bundleID;

/// The development team ID of the application.
@property (atomic, readonly) NSString* teamID;

/// The unique application identifier.  Typically this is `teamID.bundleID`: XYZ123.com.company.app.
@property (atomic, readonly) NSString* applicationID;

/// The bundle display name from the info plist.
@property (atomic, readonly) NSString* displayName;

/// The bundle short display name from the info plist.
@property (atomic, readonly) NSString* shortDisplayName;

/// The short version ID as is typically shown to the user, like in iTunes or the app store.
@property (atomic, readonly) NSString* displayVersionString;

/// The version ID for developers use.
@property (atomic, readonly) NSString* versionString;

/// The creation date of the current executable.
@property (atomic, readonly) NSDate* currentBuildDate;

/// The creating date of the exectuble the first time it was recorded by Branch.
@property (atomic, readonly) NSDate* firstInstallBuildDate;

/// The date this app was installed on this device.
@property (atomic, readonly) NSDate* currentInstallDate;

/// The date this app was first installed on this device.
@property (atomic, readonly) NSDate* firstInstallDate;

/// The push notification environment. Usually `development` or `production` or `nil`.
@property (atomic, readonly) NSString* pushNotificationEnvironment;

/// The keychain access groups from the entitlements.
@property (atomic, readonly) NSArray<NSString*>* keychainAccessGroups;

/// The associated domains from the entitlements.
@property (atomic, readonly) NSArray<NSString*>* associatedDomains;

/// Returns a dictionary of device / identity pairs.
@property (atomic, readonly) NSDictionary<NSString*, NSString*>*deviceKeyIdentityValueDictionary;

/// Adds a deviceID and identityID pair to the dictionary.
- (void) addDeviceID:(NSString*)deviceID identityID:(NSString*)identityID;

@end
