/**
 @file          BNCNetworkAPIService.m
 @package       Branch-SDK
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCNetworkAPIService.h"
#import "BNCSettings.h"
#import "BNCApplication.h"
#import "BNCNetworkService.h"

#pragma mark BNCWireFormat

NSDate* BNCDateFromWireFormat(id object) {
    NSDate *date = nil;
    if ([object respondsToSelector:@selector(doubleValue)]) {
        NSTimeInterval t = [object doubleValue];
        date = [NSDate dateWithTimeIntervalSince1970:t/1000.0];
    }
    return date;
}

NSNumber* BNCWireFormatFromDate(NSDate *date) {
    NSNumber *number = nil;
    NSTimeInterval t = [date timeIntervalSince1970];
    if (date && t != 0.0 ) {
        number = [NSNumber numberWithLongLong:(long long)(t*1000.0)];
    }
    return number;
}

NSNumber* BNCWireFormatFromBool(BOOL b) {
    return (b) ? (__bridge NSNumber*) kCFBooleanTrue : nil;
}

NSNumber* BNCWireFormatFromInteger(NSInteger i) {
    return (i == 0) ? nil : [NSNumber numberWithInteger:i];
}

NSString* BNCStringFromWireFormat(id object) {
    if ([object isKindOfClass:NSString.class])
        return object;
    else
    if ([object respondsToSelector:@selector(stringValue)])
        return [object stringValue];
    else
    if ([object respondsToSelector:@selector(description)])
        return [object description];
    return nil;
}

NSString* BNCWireFormatFromString(NSString *string) {
    return string;
}

#pragma mark - BNCAPIService

@interface BNCNetworkAPIService ()
@property (atomic, strong) BNCNetworkService *networkService;
@end

@implementation BNCNetworkAPIService

/*
- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    if (preferenceHelper.deviceFingerprintID) {
        params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    }

    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_DEBUG] = @(preferenceHelper.isDebug);

    [self safeSetValue:[BNCSystemObserver getBundleID] forKey:BRANCH_REQUEST_KEY_BUNDLE_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getTeamIdentifier] forKey:BRANCH_REQUEST_KEY_TEAM_ID onDict:params];
    [self safeSetValue:[BNCSystemObserver getAppVersion] forKey:BRANCH_REQUEST_KEY_APP_VERSION onDict:params];
    [self safeSetValue:[BNCSystemObserver getDefaultUriScheme] forKey:BRANCH_REQUEST_KEY_URI_SCHEME onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:preferenceHelper.checkedFacebookAppLinks]
        forKey:BRANCH_REQUEST_KEY_CHECKED_FACEBOOK_APPLINKS onDict:params];
    [self safeSetValue:[NSNumber numberWithBool:preferenceHelper.checkedAppleSearchAdAttribution]
        forKey:BRANCH_REQUEST_KEY_CHECKED_APPLE_AD_ATTRIBUTION onDict:params];
    [self safeSetValue:preferenceHelper.linkClickIdentifier forKey:BRANCH_REQUEST_KEY_LINK_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    [self safeSetValue:preferenceHelper.universalLinkUrl forKey:BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL onDict:params];
    [self safeSetValue:preferenceHelper.externalIntentURI forKey:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI onDict:params];
    if (preferenceHelper.limitFacebookTracking)
        params[@"limit_facebook_tracking"] = CFBridgingRelease(kCFBooleanTrue);

    NSMutableDictionary *cdDict = [[NSMutableDictionary alloc] init];
    BranchContentDiscoveryManifest *contentDiscoveryManifest = [BranchContentDiscoveryManifest getInstance];
    [cdDict bnc_safeSetObject:[contentDiscoveryManifest getManifestVersion] forKey:BRANCH_MANIFEST_VERSION_KEY];
    [cdDict bnc_safeSetObject:[BNCSystemObserver getBundleID] forKey:BRANCH_BUNDLE_IDENTIFIER];
    [self safeSetValue:cdDict forKey:BRANCH_CONTENT_DISCOVER_KEY onDict:params];

    if (preferenceHelper.appleSearchAdNeedsSend) {
        NSString *encodedSearchData = nil;
        @try {
            NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:preferenceHelper.appleSearchAdDetails];
            encodedSearchData = [BNCEncodingUtils base64EncodeData:jsonData];
        } @catch (id) { }
        [self safeSetValue:encodedSearchData
                    forKey:BRANCH_REQUEST_KEY_SEARCH_AD
                    onDict:params];
    }

    BNCApplication *application = [BNCApplication currentApplication];
    params[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    params[@"previous_update_time"] = BNCWireFormatFromDate(preferenceHelper.previousAppBuildDate);
    params[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    params[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    params[@"update"] = [self.class appUpdateState];

    [serverInterface postRequest:params
        url:[preferenceHelper
        getAPIURL:BRANCH_REQUEST_ENDPOINT_OPEN]
        key:key
        callback:callback];
}
*/

- (NSURL*) URLForAPIService:(NSString*)serviceName {
    NSString *string = [NSString stringWithFormat:@"https://api.branch.io/v1/%@", serviceName];
    return [NSURL URLWithString:string];
}

- (void) appendDeviceNetworkParametersToDictionary:(NSMutableDictionary*)dictionary {

}

- (void) openWithURL:(NSURL*)url {
    BNCSettings*settings = [BNCSettings sharedInstance];
    BNCApplication*application = [BNCApplication currentApplication];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    dictionary[@"device_fingerprint_id"] = settings.deviceFingerprintID;
    dictionary[@"identity_id"] = settings.identityID;
    dictionary[@"ios_bundle_id"] = application.bundleID;
    dictionary[@"ios_team_id"] = application.teamID;
    dictionary[@"app_version"] = application.versionString;
    dictionary[@"uri_scheme"] = application.defaultURLScheme;
    dictionary[@"facebook_app_link_checked"] = BNCWireFormatFromBool(NO);
    dictionary[@"apple_ad_attribution_checked"] = BNCWireFormatFromBool(NO);

    NSString*scheme = url.scheme;
    if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) {
        dictionary[@"universal_link_url"] = url.absoluteString;
    } else
    if (scheme.length > 0) {
        dictionary[@"external_intent_uri"] = url.absoluteString;
        NSURLComponents*components = [NSURLComponents componentsWithString:url.absoluteString];
        for (NSURLQueryItem*item in components.queryItems) {
            if ([item.name isEqualToString:@"link_click_id"]) {
                dictionary[@"link_identifier"] = item.value;
                break;
            }
        }
    }

    //[self safeSetValue:preferenceHelper.spotlightIdentifier forKey:BRANCH_REQUEST_KEY_SPOTLIGHT_IDENTIFIER onDict:params];
    //dictionary[@"spotlight_identifier"] = ???

    dictionary[@"limit_facebook_tracking"] = BNCWireFormatFromBool(settings.limitFacebookTracking);
    dictionary[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    dictionary[@"previous_update_time"] = BNCWireFormatFromDate(application.previousAppBuildDate);
    dictionary[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    dictionary[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    dictionary[@"update"] = BNCWireFormatFromInteger(application.updateState);

    [self appendDeviceNetworkParametersToDictionary:dictionary];

    [[self.networkService postOperationWithURL:[self URLForAPIService:@"open"]
        JSONData:dictionary
        completion:^(BNCNetworkOperation *operation) {

        }]
    start];
}

@end
