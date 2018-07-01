/**
 @file          BNCApplication.m
 @package       Branch-SDK
 @brief         Current application and extension info.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCApplication.h"
#import "BNCKeyChain.h"
#import "BNCLog.h"

#pragma mark Dynamically loaded function declarations

typedef struct __SecTask * SecTaskRef;
extern CFDictionaryRef SecTaskCopyValuesForEntitlements(
        SecTaskRef task,
        CFArrayRef entitlements,
        CFErrorRef  _Nullable *error
    )
    __attribute__((weak_import));

extern SecTaskRef SecTaskCreateFromSelf(CFAllocatorRef allocator)
    __attribute__((weak_import));

#pragma mark - Key Names

static NSString*const kBranchKeychainService          = @"BranchKeychainService";
static NSString*const kBranchKeychainDevicesKey       = @"BranchKeychainDevices";
static NSString*const kBranchKeychainFirstBuildKey    = @"BranchKeychainFirstBuild";
static NSString*const kBranchKeychainFirstInstalldKey = @"BranchKeychainFirstInstall";

#pragma mark - BNCApplication

@implementation BNCApplication

+ (BNCApplication*) currentApplication {
    static BNCApplication *bnc_currentApplication = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        bnc_currentApplication = [BNCApplication createCurrentApplication];
    });
    return bnc_currentApplication;
}

+ (BNCApplication*) createCurrentApplication {
    BNCApplication *application = [[BNCApplication alloc] init];
    if (!application) return application;
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;

    application->_bundleID = [NSBundle mainBundle].bundleIdentifier;
    application->_displayName = info[@"CFBundleDisplayName"];
    application->_shortDisplayName = info[@"CFBundleName"];
    if (application->_shortDisplayName.length == 0)
        application->_shortDisplayName = application->_displayName;
    if (application->_displayName.length == 0) {
        application->_displayName = application->_shortDisplayName;
    }
    application->_displayVersionString = info[@"CFBundleShortVersionString"];
    application->_versionString = info[@"CFBundleVersion"];

    // Get the entitlements:
    NSDictionary *entitlements = [self entitlementsDictionary];
    application->_applicationID = entitlements[@"application-identifier"];
    application->_pushNotificationEnvironment = entitlements[@"aps-environment"];
    application->_keychainAccessGroups = entitlements[@"keychain-access-groups"];
    application->_associatedDomains = entitlements[@"com.apple.developer.associated-domains"];
    application->_teamID = entitlements[@"com.apple.developer.team-identifier"];
    if (application->_teamID.length == 0 && application->_applicationID) {
        // Some simulator apps aren't signed the same way?
        NSRange range = [application->_applicationID rangeOfString:@"."];
        if (range.location != NSNotFound) {
            application->_teamID = [application->_applicationID substringWithRange:NSMakeRange(0, range.location)];
        }
    }
    if (application->_applicationID.length == 0 &&
        application->_teamID.length > 0 &&
        application->_bundleID.length > 0) {
        application->_applicationID = [NSString stringWithFormat:@"%@.%@", application->_teamID, application->_bundleID];
    }

    if (application->_applicationID.length) {
        BNCKeyChain *keychain = [[BNCKeyChain alloc] initWithSecurityAccessGroup:application->_applicationID];
        if (keychain) {
            application->_firstInstallBuildDate = [BNCApplication firstInstallBuildDateWithKeychain:keychain];
            application->_firstInstallDate      = [BNCApplication firstInstallDateWithKeychain:keychain];
        }
    }
    application->_currentBuildDate      = [BNCApplication currentBuildDate];
    application->_currentInstallDate    = [BNCApplication currentInstallDate];
    application->_updateState           = [BNCApplication updateStateForApplication:application];

    application->_extensionType =
        [[NSBundle mainBundle].infoDictionary[@"NSExtension"][@"NSExtensionPointIdentifier"] copy];
    if ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"]) {
        application->_isApplicationExtension = YES;
    }
    NSString*package = info[@"CFBundlePackageType"];
    if ([package isEqualToString:@"APPL"] && !application->_extensionType.length) {
        application->_isApplication = YES;
    }
    if ([application->_extensionType isEqualToString:@"com.apple.identitylookup.message-filter"])
        application->_branchExtensionType = @"IMESSAGE_APP";
    else
    if ([application->_extensionType isEqualToString:@"com.apple.watchkit"])
        application->_branchExtensionType = @"WATCH_APP";
    else
        application->_branchExtensionType = @"FULL_APP";

    application->_defaultURLScheme = [self defaultURLScheme];

    return application;
}

+ (NSDate*) currentBuildDate {
    NSString*appPath = [[NSBundle mainBundle] executablePath];
    if (!appPath) {
        BNCLogError(@"Can't find bundle executable path.");
        return nil;
    }
    NSError*error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:appPath error:&error];
    if (error) {
        BNCLogError(@"Can't get build date: %@.", error);
        return nil;
    }
    NSDate * buildDate = [attributes fileCreationDate];
    if (buildDate == nil || [buildDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid build date: %@.", buildDate);
    }
    return buildDate;
}

+ (NSDate*) firstInstallBuildDateWithKeychain:(BNCKeyChain*)keychain {
    NSError *error = nil;
    NSDate *firstBuildDate =
        [keychain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstBuildKey
            error:&error];
    if (firstBuildDate)
        return firstBuildDate;

    firstBuildDate = [self currentBuildDate];
    error = [keychain storeValue:firstBuildDate
        forService:kBranchKeychainService
        key:kBranchKeychainFirstBuildKey];

    return firstBuildDate;
}

+ (NSDate*) currentInstallDate {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL =
        [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:libraryURL.path error:&error];
    if (error) {
        BNCLogError(@"Can't get library date: %@.", error);
        return nil;
    }
    NSDate *installDate = [attributes fileCreationDate];
    if (installDate == nil || [installDate timeIntervalSince1970] <= 0.0) {
        BNCLogError(@"Invalid install date.");
    }
    return installDate;
}

+ (NSDate*) firstInstallDateWithKeychain:(BNCKeyChain*)keychain {
    NSError *error = nil;
    NSDate* firstInstallDate =
        [keychain retrieveValueForService:kBranchKeychainService
            key:kBranchKeychainFirstInstalldKey
            error:&error];
    if (firstInstallDate)
        return firstInstallDate;

    firstInstallDate = [self currentInstallDate];
    error = [keychain storeValue:firstInstallDate
        forService:kBranchKeychainService
        key:kBranchKeychainFirstInstalldKey];

    return firstInstallDate;
}

#if 0
// TODO: Add this back at some point.
// Returns a dictionary of device / identity pairs.
// @property (atomic, readonly) NSDictionary<NSString*, NSString*>*_Nonnull deviceKeyIdentityValueDictionary;
- (NSDictionary*) deviceKeyIdentityValueDictionary:(BNCKeyChain*)keychain {
    @synchronized (self.class) {
        NSError *error = nil;
        NSDictionary *deviceDictionary =
            [keychain retrieveValueForService:kBranchKeychainService
                key:kBranchKeychainDevicesKey
                error:&error];
        if (error) BNCLogWarning(@"While retrieving deviceKeyIdentityValueDictionary: %@.", error);
        if (!deviceDictionary) deviceDictionary = @{};
        return deviceDictionary;
    }
}
#endif

+ (BNCApplicationUpdateState) updateStateForApplication:(BNCApplication*)application {

    NSTimeInterval first_install_time   = application.firstInstallDate.timeIntervalSince1970;
    NSTimeInterval latest_install_time  = application.currentInstallDate.timeIntervalSince1970;
    NSTimeInterval latest_update_time   = application.currentBuildDate.timeIntervalSince1970;
    NSTimeInterval previous_update_time = application.previousAppBuildDate.timeIntervalSince1970;
    NSTimeInterval const kOneDay        = 1.0 * 24.0 * 60.0 * 60.0;

    BNCApplicationUpdateState update_state = 0;
    if (first_install_time <= 0.0 ||
        latest_install_time <= 0.0 ||
        latest_update_time <= 0.0 ||
        previous_update_time > latest_update_time)
        update_state = BNCApplicationUpdateStateNonUpdate; // BNCApplicationUpdateStateError. Error: Send Non-update.
    else
    if ((latest_update_time - kOneDay) <= first_install_time && previous_update_time <= 0)
        update_state = BNCApplicationUpdateStateInstall;
    else
    if (first_install_time < latest_install_time && previous_update_time <= 0)
        update_state = BNCApplicationUpdateStateUpdate; // BNCApplicationUpdateStateReinstall. Re-install: Send Update.
    else
    if (latest_update_time > first_install_time && previous_update_time < latest_update_time)
        update_state = BNCApplicationUpdateStateUpdate;
    else
        update_state = BNCApplicationUpdateStateNonUpdate;

    return update_state;
}

+ (NSString*) defaultURLScheme {
    NSArray*ignoredURLSchemes = @[
        @"fb",          // Facebook
        @"db",          // DB?
        @"twitterkit-", // Twitter
        @"pdk",         // Pinterest
        @"pin",         // Pinterest
        @"com.googleusercontent.apps",  // Google
    ];
    NSDictionary*info = [NSBundle mainBundle].infoDictionary;
    NSArray *urlTypes = info[@"CFBundleURLTypes"];
    for (NSDictionary *urlType in urlTypes) {
        NSArray *urlSchemes = [urlType objectForKey:@"CFBundleURLSchemes"];
        for (NSString *uriScheme in urlSchemes) {
            for (NSString*ignoredScheme in ignoredURLSchemes) {
                if ([uriScheme hasPrefix:ignoredScheme])
                    continue;
                // Otherwise this must be it!
                return uriScheme;
            }
        }
    }
    return nil;
}

+ (NSDictionary*) entitlementsDictionary {
    if (SecTaskCreateFromSelf == NULL || SecTaskCopyValuesForEntitlements == NULL)
        return nil;

    NSArray *entitlementKeys = @[
        @"application-identifier",
        @"com.apple.developer.team-identifier",
        @"com.apple.developer.associated-domains",
        @"keychain-access-groups",
        @"aps-environment"
    ];

    SecTaskRef myself = SecTaskCreateFromSelf(NULL);
    if (!myself) return nil;

    CFErrorRef errorRef = NULL;
    NSDictionary *entitlements = (__bridge_transfer NSDictionary *)
        (SecTaskCopyValuesForEntitlements(myself, (__bridge CFArrayRef)entitlementKeys, &errorRef));
    if (errorRef) {
        BNCLogError(@"Can't retrieve entitlements: %@.", errorRef);
        CFRelease(errorRef);
    }
    CFRelease(myself);

    return entitlements;
}

@end
