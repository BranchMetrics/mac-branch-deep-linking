/**
 @file          BNCApplication.h
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BNCApplicationUpdateState) {
    BNCApplicationUpdateStateInstall       = 0,    // Application was recently installed.
    BNCApplicationUpdateStateNonUpdate     = 1,    // Application was neither newly installed nor updated.
    BNCApplicationUpdateStateUpdate        = 2,    // Application was recently updated.

    BNCApplicationUpdateStateError         = 3,    // Error determining update state.
    BNCApplicationUpdateStateReinstall     = 4,    // App was re-installed.
};

@interface BNCApplication : NSObject

/// A reference to the current running application.
+ (BNCApplication*_Nonnull) currentApplication;

/// The bundle identifier of the current
@property (atomic, readonly) NSString*_Nullable bundleID;

/// The team that was for code signing.
@property (atomic, readonly) NSString*_Nullable teamID;

/// The bundle display name from the info plist.
@property (atomic, readonly) NSString*_Nullable displayName;

/// The bundle short display name from the info plist.
@property (atomic, readonly) NSString*_Nullable shortDisplayName;

/// The short version ID as is typically shown to the user, like in iTunes (CFBundleShortVersionString).
@property (atomic, readonly) NSString*_Nullable displayVersionString;

/// The version ID that developers use (CFBundleVersion).
@property (atomic, readonly) NSString*_Nullable versionString;

/// The creation date of the current executable.
@property (atomic, readonly) NSDate*_Nullable currentBuildDate;

/// Previous value of the creation date of the current executable, if available.
@property (atomic, readonly) NSDate*_Nullable previousAppBuildDate;

/// The creating date of the exectuble the first time it was recorded by Branch.
@property (atomic, readonly) NSDate*_Nullable firstInstallBuildDate;

/// The date this app was installed on this device.
@property (atomic, readonly) NSDate*_Nullable currentInstallDate;

/// The date this app was first installed on this device.
@property (atomic, readonly) NSDate*_Nullable firstInstallDate;

/// The update state off the application.
@property (atomic, readonly) BNCApplicationUpdateState updateState;

/// YES if running as an application.
@property (atomic, readonly) BOOL isApplication;

/// YES if running as an application extension.
@property (atomic, readonly) BOOL isApplicationExtension;

/// The app extension type or 'application'.
@property (atomic, readonly) NSString*_Nullable extensionType;

/// The default URL scheme for the app as found in the app's Info.plist.
@property (atomic, readonly) NSString*_Nullable defaultURLScheme;

/// The unique application identifier. Typically this is `teamID.bundleID`: XYZ123.com.company.app.
@property (atomic, readonly) NSString*_Nullable applicationID;

/// The push notification environment. Usually `development` or `production` or `nil`.
@property (atomic, readonly) NSString*_Nullable pushNotificationEnvironment;

/// The keychain access groups from the entitlements.
@property (atomic, readonly) NSArray<NSString*>*_Nullable keychainAccessGroups;

/// The associated domains from the entitlements.
@property (atomic, readonly) NSArray<NSString*>*_Nullable associatedDomains;
@end

NS_ASSUME_NONNULL_END
