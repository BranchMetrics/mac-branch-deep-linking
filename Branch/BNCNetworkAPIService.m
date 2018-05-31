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
#import "BranchEvent.h"
#import "BranchError.h"
#import "BNCLocalization.h"

#pragma mark BNCNetworkAPIOperation

@implementation BNCNetworkAPIOperation
@end

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

- (void) appendV1APIParametersWithDictionary:(NSMutableDictionary*)dictionary {
    if (!dictionary) return;
    NSMutableDictionary* device = [BNCDevice currentDevice].v2dictionary;
    device[@"os"] = @"iOS";
    [dictionary addEntriesFromDictionary:device];

    dictionary[@"sdk"] = [NSString stringWithFormat:@"ios%@", Branch.kitDisplayVersion];
    dictionary[@"ios_extension"] =
        BNCWireFormatFromBool([BNCApplication currentApplication].isApplicationExtension);
    // dictionary[@"retryNumber"] = @(retryNumber);  // TODO: Move to request header.
    dictionary[@"branch_key"] = self.configuration.key;

    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata addEntriesFromDictionary:Branch.sharedInstance.requestMetadataDictionary];
    if (dictionary[@"metadata"])
        [metadata addEntriesFromDictionary:dictionary[@"metadata"]];
    if (metadata.count) {
        dictionary[@"metadata"] = metadata;
    }
    if (self.settings.instrumentationDictionary.count/* && addInstrumentation*/) {
        dictionary[@"instrumentation"] = self.settings.instrumentationDictionary;
    }
}

- (void) collectInstrumentationMetricsWithOperation:(BNCNetworkOperation*)operation {
    // multiplying by negative because startTime happened in the past
    NSTimeInterval elapsedTime = [operation.dateStart timeIntervalSinceNow] * -1000.0;
    NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
    NSString *path = [operation.request.URL path];
    NSString *brttKey = [NSString stringWithFormat:@"%@-brtt", path];
    self.settings.instrumentationDictionary[brttKey] = lastRoundTripTime;
}

- (void) postOperationForAPIServiceName:(NSString*)serviceName
        dictionary:(NSDictionary*)dictionary
        completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion {
    NSURL*apiURL = [self URLForAPIService:serviceName];
    [[self.networkService postOperationWithURL:apiURL
        JSONData:dictionary
        completion:^ (BNCNetworkOperation*operation) {
            BNCNetworkAPIOperation*apiOperation = [self apiOperationWithNetworkOperation:operation];
            if (completion) completion(apiOperation);
        }]
            start];
}

- (BNCNetworkAPIOperation*) apiOperationWithNetworkOperation:(BNCNetworkOperation*)operation {
    BNCNetworkAPIOperation*apiOperation = [[BNCNetworkAPIOperation alloc] init];
    apiOperation.operation = operation;
    [self collectInstrumentationMetricsWithOperation:operation];
    NSError*error = [self errorWithOperation:operation];
    if (error) {
        apiOperation.error = error;
        return apiOperation;
    }
    [operation deserializeJSONResponseData];
    if (operation.error) {
        apiOperation.error = error;
        return apiOperation;
    }
    if (![operation.responseData isKindOfClass:NSDictionary.class]) {
        apiOperation.error = [NSError branchErrorWithCode:BNCServerProblemError];
        return apiOperation;
    }
    NSDictionary*dictionary = (NSDictionary*)operation.responseData;
    BranchSession*session = [BranchSession sessionWithDictionary:dictionary];
    apiOperation.session = session;

    if (session.linkCreationURL.length) self.settings.linkCreationURL = session.linkCreationURL;
    if (session.deviceFingerprintID.length) self.settings.deviceFingerprintID = session.deviceFingerprintID;
    if (session.developerIdentityForUser.length) self.settings.developerIdentityForUser = session.developerIdentityForUser;
    if (session.sessionID.length) self.settings.sessionID = session.sessionID;
    if (session.identityID) self.settings.identityID = session.identityID;

    return apiOperation;
}

- (NSError*) errorWithOperation:(BNCNetworkOperation*)operation {
    NSError *underlyingError = operation.error;
    NSInteger status = operation.HTTPStatusCode;
/*
    TODO: Handle retries.

    // If the phone is in a poor network condition,
    // iOS will return statuses such as -1001, -1003, -1200, -9806
    // indicating various parts of the HTTP post failed.
    // We should retry in those conditions in addition to the case where the server returns a 500

    BOOL isRetryableStatusCode = status >= 500 || status < 0;

    // Retry the request if appropriate
    if (retryNumber < self.preferenceHelper.retryCount && isRetryableStatusCode) {
        dispatch_time_t dispatchTime =
            dispatch_time(DISPATCH_TIME_NOW, self.preferenceHelper.retryInterval * NSEC_PER_SEC);
        dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
            BNCLogDebug(@"Retrying request with url %@", request.URL.relativePath);
            // Create the next request
            NSURLRequest *retryRequest = retryHandler(retryNumber);
            [self genericHTTPRequest:retryRequest
                         retryNumber:(retryNumber + 1)
                            callback:callback retryHandler:retryHandler];
        });

        // Do not continue on if retrying, else the callback will be called incorrectly
        return;
    }
*/
    NSError *branchError = nil;

    // Wrap up bad statuses w/ specific error messages
    if (status >= 500) {
        branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
    }
    else if (status == 409) {
        branchError = [NSError branchErrorWithCode:BNCDuplicateResourceError error:underlyingError];
    }
    else if (status >= 400) {

        [operation deserializeJSONResponseData];
        NSDictionary*dictionary = nil;
        if ([operation.responseData isKindOfClass:NSDictionary.class])
            dictionary = (id) operation.responseData;

        NSString *errorString = dictionary[@"error"];
        if (![errorString isKindOfClass:[NSString class]])
            errorString = nil;
        if (!errorString)
            errorString = underlyingError.localizedDescription;
        if (!errorString)
            errorString = BNCLocalizedString(@"The request was invalid.");
        branchError = [NSError branchErrorWithCode:BNCBadRequestError localizedMessage:errorString];
    }
    else if (underlyingError) {
        branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
    }

    if (branchError) {
        BNCLogError(@"An error prevented request to %@ from completing: %@",
            operation.request.URL.absoluteString, branchError);
    }

    return branchError;
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
    [self appendV1APIParametersWithDictionary:dictionary];
    NSString*service = (self.settings.identityID.length > 0) ? @"v1/open" : @"v1/install";

    BNCPerformBlockOnMainThreadSync(^ {
        [self notifyWillStartSessionWithURL:url];
    });

    __weak __typeof(self) weakSelf = self;
    [self postOperationForAPIServiceName:service
        dictionary:dictionary
        completion:^(BNCNetworkAPIOperation *operation) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf openResponseWithOperation:operation url:url];
        }];
}

- (void) openResponseWithOperation:(BNCNetworkAPIOperation*)operation url:(NSURL*)URL {
    if (operation.error) {
        BNCPerformBlockOnMainThreadSync(^{
            [self notifyDidStartSession:nil withURL:URL error:operation.error];
        });
        return;
    }

    BranchSession*session = operation.session;
    BranchLinkProperties*linkProperties = [BranchLinkProperties linkPropertiesWithDictionary:session.data];
    session.linkProperties = linkProperties;
    BranchUniversalObject*object = [BranchUniversalObject objectWithDictionary:session.data];
    session.linkContent = object;

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

@end
