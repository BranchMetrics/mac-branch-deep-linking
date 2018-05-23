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
#import "BNCDevice.h"
#import "BNCWireFormat.h"
#import "BNCThreads.h"
#import "BranchSession.h"
#import "BranchMainClass.h"
#import "BNCLog.h"
#import "BranchDelegate.h"

#pragma mark - BNCAPIService

@interface BNCNetworkAPIService ()
@property (atomic, strong) BNCNetworkService *networkService;
@property (atomic, strong) BranchConfiguration *configuration;
@property (atomic, strong) BNCSettings* settings;
@end

@implementation BNCNetworkAPIService

- (instancetype) initWithConfiguration:(BranchConfiguration *)configuration {
    self = [super init];
    if (!self) return self;
    self.configuration = configuration;
    self.networkService = [[BNCNetworkService alloc] init];
    self.networkService.maxConcurrentOperationCount = 1;
    self.settings = [BNCSettings sharedInstance];
    return self;
}

#pragma mark - Utilities

- (NSURL*) URLForAPIService:(NSString*)serviceName {
    serviceName = [serviceName stringByTrimmingCharactersInSet:
        [NSCharacterSet characterSetWithCharactersInString:@" \t\n\\/"]];
    NSString *string = [NSString stringWithFormat:@"https://api.branch.io/%@", serviceName];
    return [NSURL URLWithString:string];
}

- (void) appendV1APIParametersWithDictionary:(NSMutableDictionary*)dictionary
        addInstrumentation:(BOOL)addInstrumentation {
    if (!dictionary) return;
    NSMutableDictionary* device = [BNCDevice currentDevice].v2dictionary;
    device[@"os"] = @"iOS";
    [dictionary addEntriesFromDictionary:device];

    dictionary[@"sdk"] = [NSString stringWithFormat:@"ios%@", Branch.kitDisplayVersion];
    dictionary[@"ios_extension"] = BNCWireFormatFromBool([BNCApplication currentApplication].isApplicationExtension);
    // dictionary[@"retryNumber"] = @(retryNumber);  // TODO: Move to request header.
    dictionary[@"branch_key"] = self.configuration.key;

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata addEntriesFromDictionary:Branch.sharedInstance.requestMetadataDictionary];
    if (dictionary[@"metadata"])
        [metadata addEntriesFromDictionary:dictionary[@"metadata"]];
    if (metadata.count) {
        dictionary[@"metadata"] = metadata;
    }
    if (self.settings.instrumentationDictionary.count && addInstrumentation) {
        dictionary[@"instrumentation"] = self.settings.instrumentationDictionary;
    }
}

#pragma mark - openURL

- (void) openURL:(NSURL*)url {
    BNCApplication*application = [BNCApplication currentApplication];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    dictionary[@"device_fingerprint_id"] = BNCWireFormatFromString(self.settings.deviceFingerprintID);
    dictionary[@"identity_id"] = BNCWireFormatFromString(self.settings.identityID);
    dictionary[@"ios_bundle_id"] = BNCWireFormatFromString(application.bundleID);
    dictionary[@"ios_team_id"] = BNCWireFormatFromString(application.teamID);
    dictionary[@"app_version"] = BNCWireFormatFromString(application.displayVersionString);
    dictionary[@"uri_scheme"] = BNCWireFormatFromString(application.defaultURLScheme);
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

    dictionary[@"limit_facebook_tracking"] = BNCWireFormatFromBool(self.settings.limitFacebookTracking);
    dictionary[@"lastest_update_time"] = BNCWireFormatFromDate(application.currentBuildDate);
    dictionary[@"previous_update_time"] = BNCWireFormatFromDate(application.previousAppBuildDate);
    dictionary[@"latest_install_time"] = BNCWireFormatFromDate(application.currentInstallDate);
    dictionary[@"first_install_time"] = BNCWireFormatFromDate(application.firstInstallDate);
    dictionary[@"update"] = BNCWireFormatFromInteger(application.updateState);
    [self appendV1APIParametersWithDictionary:dictionary addInstrumentation:YES];
    NSString*service = (self.settings.identityID.length > 0) ? @"v1/open" : @"v1/install";

    BNCPerformBlockOnMainThreadSync(^ {
        [self notifyWillStartSessionWithURL:url];
    });

    __weak __typeof(self) weakSelf = self;
    [[self.networkService postOperationWithURL:[self URLForAPIService:service]
        JSONData:dictionary
        completion:^(BNCNetworkOperation *operation) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf openResponseWithOperation:operation url:url];
        }]
            start];
}

- (void) openResponseWithOperation:(BNCNetworkOperation*)operation url:(NSURL*)URL {
    if (!operation.error)
        [operation deserializeJSONResponseData];
    if (operation.error) {
        BNCPerformBlockOnMainThreadSync(^{
            [self notifyDidStartSession:nil withURL:URL error:operation.error];
        });
        return;
    }

    NSDictionary*response = (NSDictionary*) operation.responseData;
    BranchSession*session = [BranchSession sessionWithDictionary:response];
    BranchLinkProperties*linkProperties = [BranchLinkProperties linkPropertiesWithDictionary:session.data];
    session.linkProperties = linkProperties;
    BranchUniversalObject*object = [BranchUniversalObject objectWithDictionary:session.data];
    session.linkContent = object;

    NSString*linkCreationURL = BNCStringFromWireFormat(response[@"link"]);
    if (linkCreationURL.length) self.settings.linkCreationURL = linkCreationURL;
    self.settings.deviceFingerprintID = session.deviceFingerprintID;
    self.settings.developerIdentityForUser = session.developerIdentityForUser;
    self.settings.sessionID = session.sessionID;
    if (session.identityID) self.settings.identityID = session.identityID;

//  TODO: Send intrumentation.
//  preferenceHelper.previousAppBuildDate = [BNCApplication currentApplication].currentBuildDate;

    BNCPerformBlockOnMainThreadSync(^ {
        [self notifyDidStartSession:session withURL:URL error:nil];
    });
    if (session.referringURL) {
        BNCPerformBlockOnMainThreadSync(^ {
            [self notifyDidOpenURLWithSession:session];
        });
    }
}

- (void) notifyWillStartSessionWithURL:(NSURL*)URL {
    BNCLogAssert([NSThread isMainThread]);
    Branch*branch = [Branch sharedInstance];
    if ([branch.delegate respondsToSelector:@selector(branch:willStartSessionWithURL:)]) {
        [branch.delegate branch:branch willStartSessionWithURL:URL];
    }
    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchURLKey] = URL;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchWillStartSessionNotification
        object:branch
        userInfo:userInfo];
}

- (void) notifyDidStartSession:(BranchSession*)session withURL:(NSURL*)URL error:(NSError*)error {
    BNCLogAssert([NSThread isMainThread] && (session || error));
    Branch*branch = [Branch sharedInstance];

    if (session == nil && error == nil) {
        BNCLogError(@"Both session and error are nil!");
        return;
    }

    if (error) {
        if ([branch.delegate respondsToSelector:@selector(branch:failedToStartSessionWithURL:error:)])
            [branch.delegate branch:branch failedToStartSessionWithURL:URL error:error];
    } else {
        if ([branch.delegate respondsToSelector:@selector(branch:didStartSession:)])
            [branch.delegate branch:branch didStartSession:session];
    }

    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchURLKey] = URL;
    userInfo[BranchSessionKey] = session;
    userInfo[BranchErrorKey] = error;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidStartSessionNotification
        object:branch
        userInfo:userInfo];
}

- (void) notifyDidOpenURLWithSession:(BranchSession*)session {
    BNCLogAssert([NSThread isMainThread]);
    Branch*branch = [Branch sharedInstance];

    if ([branch.delegate respondsToSelector:@selector(branch:didOpenURLWithSession:)])
        [branch.delegate branch:branch didOpenURLWithSession:session];

    NSMutableDictionary*userInfo = [[NSMutableDictionary alloc] init];
    userInfo[BranchSessionKey] = session;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:BranchDidOpenURLWithSessionNotification
        object:branch
        userInfo:userInfo];
}

#pragma mark - Close

- (void) sendClose {
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc] init];
    dictionary[@"identity_id"] = self.settings.identityID;
    dictionary[@"session_id"] = self.settings.sessionID;
    dictionary[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
    [self appendV1APIParametersWithDictionary:dictionary addInstrumentation:YES];
    [[self.networkService postOperationWithURL:[self URLForAPIService:@"v1/close"]
        JSONData:dictionary
        completion:nil]
            start];
}

@end
