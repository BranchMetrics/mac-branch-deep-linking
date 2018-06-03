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
    @synchronized(self) {
        serviceName = [serviceName stringByTrimmingCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@" \t\n\\/"]];
        NSString *string = [NSString stringWithFormat:@"https://api.branch.io/%@", serviceName];
        return [NSURL URLWithString:string];
    }
}

- (void) appendV1APIParametersWithDictionary:(NSMutableDictionary*)dictionary {
    @synchronized(self) {
        if (!dictionary) return;
        NSMutableDictionary* device = [BNCDevice currentDevice].v1dictionary;
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
}

- (void) appendV2APIParametersWithDictionary:(NSMutableDictionary*)dictionary {
    @synchronized(self) {
        BNCApplication*application = [BNCApplication currentApplication];

        // Add user_data:
        NSMutableDictionary*userData = [NSMutableDictionary new];
        [userData addEntriesFromDictionary:[BNCDevice currentDevice].v2dictionary];
        userData[@"app_version"] = application.displayVersionString;
        userData[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
        userData[@"environment"] = application.branchExtensionType;
        userData[@"limit_facebook_tracking"] = BNCWireFormatFromBool(self.settings.limitFacebookTracking);
        userData[@"sdk"] = @"ios";
        userData[@"sdk_version"] = Branch.kitDisplayVersion;
        //userData[@"environment"] = @"WHAT"; // TODO: remove.  Cause error on purpose.
        dictionary[@"user_data"] = userData;

        // Add instrumentation:
        if (self.settings.instrumentationDictionary.count/* && addInstrumentation*/) {
            dictionary[@"instrumentation"] = self.settings.instrumentationDictionary;
        }

        dictionary[@"branch_key"] = self.configuration.key;
    }
}

- (void) collectInstrumentationMetricsWithOperation:(BNCNetworkOperation*)operation {
    @synchronized(self) {
        // Multiplying by negative because startTime happened in the past
        NSTimeInterval elapsedTime = [operation.dateStart timeIntervalSinceNow] * -1000.0;
        NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
        NSString *path = [operation.request.URL path];
        NSString *brttKey = [NSString stringWithFormat:@"%@-brtt", path];
        self.settings.instrumentationDictionary = nil;
        self.settings.instrumentationDictionary[brttKey] = lastRoundTripTime;
    }
}

- (void) postOperationForAPIServiceName:(NSString*)serviceName
        dictionary:(NSDictionary*)dictionary
        completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion {
    @synchronized(self) {
        NSURL*apiURL = [self URLForAPIService:serviceName];
        [[self.networkService postOperationWithURL:apiURL
            JSONData:dictionary
            completion:^ (BNCNetworkOperation*operation) {
                BNCNetworkAPIOperation*apiOperation = [self apiOperationWithNetworkOperation:operation];
                if (completion) completion(apiOperation);
            }]
                start];
    }
}

- (BNCNetworkAPIOperation*) apiOperationWithNetworkOperation:(BNCNetworkOperation*)operation {
    @synchronized(self) {
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
            apiOperation.error = [NSError branchErrorWithCode:BNCBadRequestError];
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

        NSDictionary*dictionary = nil;
        [operation deserializeJSONResponseData];
        if ([operation.responseData isKindOfClass:NSDictionary.class])
            dictionary = (id) operation.responseData;

        NSString *errorString = nil;
        NSString *s = dictionary[@"error"];
        if ([s isKindOfClass:[NSString class]]) {
            errorString = s;
        }
        if (!errorString) {
            s = dictionary[@"error"][@"message"];
            if ([s isKindOfClass:[NSString class]])
                errorString = s;
        }
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

@end
