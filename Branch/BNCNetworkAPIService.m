/**
 @file          BNCNetworkAPIService.m
 @package       Branch
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCNetworkAPIService.h"
#import "BNCApplication.h"
#import "BNCDevice.h"
#import "BNCLocalization.h"
#import "BNCLog.h"
#import "BNCPersistence.h"
#import "BNCSettings.h"
#import "BNCThreads.h"
#import "BNCWireFormat.h"
#import "BranchDelegate.h"
#import "BranchError.h"
#import "BranchEvent.h"
#import "BranchMainClass.h"
#import "BranchMainClass+Private.h"
#import "BranchSession.h"
#import "NSData+Branch.h"

static NSString*_Nonnull BNCNetworkQueueFilename =  @"io.branch.sdk.network_queue";

#pragma mark BNCNetworkAPIOperation

@interface BNCNetworkAPIOperation () <NSSecureCoding>
- (instancetype) initWithNetworkService:(id<BNCNetworkServiceProtocol>)networkService
                               settings:(BNCSettings*)settings
                                    URL:(NSURL*)URL
                             dictionary:(NSDictionary*)dictionary
                             completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion;
- (void) main;
- (BOOL) isAsynchronous;

@property (strong) id<BNCNetworkServiceProtocol>networkService;
@property (strong) BNCSettings*settings;
@property (strong) NSURL*URL;
@property (strong) NSMutableDictionary*dictionary;
@property (strong) NSString*identifier;
@property (copy)   void (^_Nullable completion)(BNCNetworkAPIOperation*operation);
@end

#pragma mark - BNCAPIService

@interface BNCNetworkAPIService ()
@property (atomic, strong) id<BNCNetworkServiceProtocol> networkService;
@property (atomic, strong) BranchConfiguration *configuration;
@property (atomic, strong) BNCSettings *settings;
@property (atomic, strong) NSOperationQueue *operationQueue;
@property (atomic, strong) NSMutableDictionary<NSString*, NSData*> *archivedOperations;
@property (atomic, strong) BNCPersistence*persistence;
- (void) saveOperation:(BNCNetworkAPIOperation*)operation;
- (void) deleteOperation:(BNCNetworkAPIOperation*)operation;
- (void) loadOperations;
@end

#pragma mark - BNCNetworkAPIService

@implementation BNCNetworkAPIService

- (instancetype) initWithConfiguration:(BranchConfiguration *)configuration {
    self = [super init];
    if (!self) return self;
    self.configuration = configuration;
    self.settings = self.configuration.settings;
    self.networkService = [configuration.networkServiceClass new];
    self.persistence = [[BNCPersistence alloc] initWithAppGroup:BNCApplication.currentApplication.bundleID];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.operationQueue.name = @"io.branch.sdk.BNCNetworkAPIService";
    self.operationQueue.maxConcurrentOperationCount = 1;
    [self loadOperations];
    return self;
}

- (void) dealloc {
    if ([self.networkService respondsToSelector:@selector(cancelAllOperations)]) {
        [self.networkService cancelAllOperations];
    }
}

- (void) setQueuePaused:(BOOL)paused_ {
    @synchronized(self) {
        self.operationQueue.suspended = paused_;
    }
}

- (BOOL) queueIsPaused {
    @synchronized(self) {
        return self.operationQueue.isSuspended;
    }
}

- (NSInteger) queueDepth {
    @synchronized(self) {
        return self.operationQueue.operationCount;
    }
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p Queued: %ld %@>",
        NSStringFromClass(self.class),
        (void*) self,
        (long) self.queueDepth,
        self.operationQueue.operations];
}

#pragma mark - Utilities

- (void) appendV1APIParametersWithDictionary:(NSMutableDictionary*)dictionary {
    @synchronized(self) {
        if (!dictionary) return;
        NSMutableDictionary* device = [BNCDevice currentDevice].v1dictionary;
        [dictionary addEntriesFromDictionary:device];

        dictionary[@"sdk"] = [NSString stringWithFormat:@"mac%@", Branch.kitDisplayVersion];
        dictionary[@"ios_extension"] =
            BNCWireFormatFromBool([BNCApplication currentApplication].isApplicationExtension);

        // Add metadata:
        NSMutableDictionary *metadata = [dictionary[@"metadata"] mutableCopy];
        if (![metadata isKindOfClass:NSMutableDictionary.class]) metadata = [NSMutableDictionary new];
        [metadata addEntriesFromDictionary:self.configuration.settings.requestMetadataDictionary];
        if (metadata.count) dictionary[@"metadata"] = metadata;
        dictionary[@"branch_key"] = self.configuration.key;
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
        userData[@"sdk"] = @"mac";
        userData[@"sdk_version"] = Branch.kitDisplayVersion;
        dictionary[@"user_data"] = userData;

        // Add metadata:
        NSMutableDictionary *metadata = [dictionary[@"metadata"] mutableCopy];
        if (![metadata isKindOfClass:NSMutableDictionary.class]) metadata = [NSMutableDictionary new];
        [metadata addEntriesFromDictionary:self.settings.requestMetadataDictionary];
        if (metadata.count) dictionary[@"metadata"] = metadata;
        dictionary[@"branch_key"] = self.configuration.key;
    }
}

- (void) postOperationForAPIServiceName:(NSString*)serviceName
        dictionary:(NSMutableDictionary*)dictionary
        completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion {

    serviceName = [serviceName stringByTrimmingCharactersInSet:
        [NSCharacterSet characterSetWithCharactersInString:@" \t\n\\/"]];
    NSString *string = [NSString stringWithFormat:@"%@/%@", self.configuration.branchAPIServiceURL, serviceName];
    NSURL*url = [NSURL URLWithString:string];

    if (self.settings.userTrackingDisabled) {
        NSString *endpoint = url.path;
        if ((([endpoint isEqualToString:@"/v1/install"] ||
              [endpoint isEqualToString:@"/v1/open"]) &&
             (dictionary[@"external_intent_uri"] != nil ||
              dictionary[@"universal_link_url"] != nil  ||
              dictionary[@"spotlight_identitifer"] != nil ||
              dictionary[@"link_identifier"] != nil)) ||
            ([endpoint isEqualToString:@"/v1/url"])) {

              // Clear any sensitive data:
              dictionary[@"tracking_disabled"] = BNCWireFormatFromBool(YES);
              dictionary[@"local_ip"] = nil;
              dictionary[@"lastest_update_time"] = nil;
              dictionary[@"previous_update_time"] = nil;
              dictionary[@"latest_install_time"] = nil;
              dictionary[@"first_install_time"] = nil;
              dictionary[@"ios_vendor_id"] = nil;
              dictionary[@"hardware_id"] = nil;
              dictionary[@"hardware_id_type"] = nil;
              dictionary[@"is_hardware_id_real"] = nil;
              dictionary[@"device_fingerprint_id"] = nil;
              dictionary[@"identity_id"] = nil;
              dictionary[@"identity"] = nil;
              dictionary[@"update"] = nil;

        } else {

            [self.settings clearUserIdentifyingInformation];
            BNCNetworkAPIOperation* operation = [[BNCNetworkAPIOperation alloc] init];
            operation.error = [NSError branchErrorWithCode:BNCTrackingDisabledError];
            BNCLogError(@"Network service error: %@.", operation.error);
            if (completion) completion(operation);
            return;
        }
    }

    __weak __typeof(self) weakSelf = self;
    BNCNetworkAPIOperation* networkAPIOperation =
        [[BNCNetworkAPIOperation alloc]
            initWithNetworkService:self.networkService
            settings:self.settings
            URL:url
            dictionary:dictionary
            completion:^ (BNCNetworkAPIOperation*operation) {
                __typeof(self) strongSelf = weakSelf;
                [strongSelf deleteOperation:operation];
                if (completion) completion(operation);
            }];
    [self saveOperation:networkAPIOperation];
    [self.operationQueue addOperation:networkAPIOperation];
}

#pragma mark - Persistence

- (void) saveOperation:(BNCNetworkAPIOperation *)operation {
    @synchronized(self) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSData*data = [NSKeyedArchiver archivedDataWithRootObject:operation];
        self.archivedOperations[operation.identifier] = data;
        [self saveArchivedOperations];
        #pragma clang diagnostic pop
    }
}

- (void) deleteOperation:(BNCNetworkAPIOperation *)operation {
    @synchronized(self) {
        self.archivedOperations[operation.identifier] = nil;
        [self saveArchivedOperations];
    }
}
- (void) saveArchivedOperations {
    @synchronized(self) {
        [self.persistence archiveObject:self.archivedOperations named:BNCNetworkQueueFilename];
    }
}

- (void) loadOperations {
    @synchronized(self) {
        self.archivedOperations = [NSMutableDictionary new];
        NSDictionary*d = [self.persistence unarchiveObjectNamed:BNCNetworkQueueFilename];
        if (![d isKindOfClass:NSDictionary.class]) return;
        // Start the operations:
        __weak __typeof(self) weakSelf = self;
        for (NSString*key in d.keyEnumerator) {
            if (![key isKindOfClass:NSString.class])
                continue;
            NSData*data = d[key];
            if (![data isKindOfClass:NSData.class])
                continue;
            BNCNetworkAPIOperation*op = nil;
            @try {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                op = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                #pragma clang diagnostic pop
            }
            @catch (id e) {
                BNCLogError(@"Can't unarchive network operation: %@.", e);
                op = nil;
            }
            if (![op isKindOfClass:BNCNetworkAPIOperation.class])
                continue;
            if (!self.archivedOperations[op.identifier]) {
                self.archivedOperations[op.identifier] = data;
                op.networkService = self.networkService;
                op.settings = self.configuration.settings;
                op.completion = ^ (BNCNetworkAPIOperation*operation) {
                    __typeof(self) strongSelf = weakSelf;
                    [strongSelf deleteOperation:operation];
                };
                [self.operationQueue addOperation:op];
            }
        }
    }
}

- (void) clearNetworkQueue {
    @synchronized(self) {
        self.archivedOperations = [NSMutableDictionary new];
        [self.persistence removeDataNamed:BNCNetworkQueueFilename];
        if ([self.networkService respondsToSelector:@selector(cancelAllOperations)])
            [self.networkService cancelAllOperations];
        [self.operationQueue cancelAllOperations];
    }
}

@end

#pragma mark - BNCNetworkAPIOperation

@implementation BNCNetworkAPIOperation

- (instancetype) initWithNetworkService:(id<BNCNetworkServiceProtocol>)networkService
                               settings:(BNCSettings*)settings
                                    URL:(NSURL*)URL
                             dictionary:(NSDictionary*)dictionary
                             completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion {
    self = [super init];
    if (!self) return self;
    self.networkService = networkService;
    self.settings = settings;
    self.URL = URL;
    self.dictionary = [dictionary mutableCopy];
    self.completion = completion;
    self.qualityOfService = NSQualityOfServiceUserInitiated;
    self.name = [URL path];
    self.identifier = [[NSUUID UUID] UUIDString];
    return self;
}

- (BOOL) isAsynchronous {
    return YES;
}

- (void) main {
    NSInteger retry = 0;
    NSTimeInterval retryWaitTime = 1.0;
    NSError*error = nil;
    self.startDate = [NSDate date];
    self.timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60.0];
    {
        if (([self.timeoutDate timeIntervalSinceNow] < 0) || self.isCancelled)
            goto exit;

        do  {
            if (retry > 0) {
                // Wait before retrying to avoid flooding the network.
                BNCSleepForTimeInterval(retryWaitTime);
                retryWaitTime *= 1.5f;
            }
            NSData *data = nil;
            if (self.dictionary) {
                NSError *error = nil;
                // TODO: ???
                //self.dictionary[@"retry_number"] = BNCWireFormatFromInteger(retry);
                self.dictionary[@"retryNumber"] = BNCWireFormatFromInteger(retry);
                NSDictionary*instrumentation = [self.settings.instrumentationDictionary copy];
                if (instrumentation.count) self.dictionary[@"instrumentation"] = instrumentation;
                data = [NSJSONSerialization dataWithJSONObject:self.dictionary options:0 error:&error];
                if (error) {
                    BNCLogError(@"Can't convert to JSON: %@.", error);
                    goto exit;
                }
            }

            NSTimeInterval timeout = MIN(20.0, [self.timeoutDate timeIntervalSinceNow]);
            if (timeout < 0.0) {
                error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                goto exit;
            }
            if (self.isCancelled) {
                error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
                goto exit;
            }

            NSMutableURLRequest*request =
                [[NSMutableURLRequest alloc]
                    initWithURL:self.URL
                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                    timeoutInterval:timeout];
            request.HTTPMethod = @"POST";
            request.HTTPBody = data;
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

            dispatch_semaphore_t network_semaphore = dispatch_semaphore_create(0);
            self.operation =
                [self.networkService networkOperationWithURLRequest:request
                    completion:^ (id<BNCNetworkOperationProtocol>operation) {
                        dispatch_semaphore_signal(network_semaphore);
                    }
                ];
            error = [self verifyNetworkOperation:self.operation];
            if (error) {
                BNCLogError(@"Bad network interface: %@.", error);
                goto exit;
            }
            [self.operation start];
            dispatch_semaphore_wait(network_semaphore, DISPATCH_TIME_FOREVER);
            if (self.operation.error) {
                BNCLogError(@"Network service error: %@.", error);
            }

            retry++;

        } while (!self.isCancelled && [self.class canRetryOperation:self.operation] && retry <= 5);

    error = [self.class errorWithOperation:self.operation];
    if (error) goto exit;

    NSDictionary*dictionary = [self.class dictionaryWithJSONData:self.operation.responseData error:&error];
    if (error) goto exit;

    if (![dictionary isKindOfClass:NSDictionary.class]) {
        error = [NSError branchErrorWithCode:BNCBadRequestError];
        goto exit;
    }

    [self collectInstrumentationMetrics];
    self.session = [BranchSession sessionWithDictionary:dictionary];

    if (self.session.linkCreationURL.length)
        self.settings.linkCreationURL = self.session.linkCreationURL;
    if (self.session.deviceFingerprintID.length)
        self.settings.deviceFingerprintID = self.session.deviceFingerprintID;
    if (self.session.userIdentityForDeveloper.length)
        self.settings.userIdentityForDeveloper = self.session.userIdentityForDeveloper;
    if (self.session.sessionID.length)
        self.settings.sessionID = self.session.sessionID;
    if (self.session.identityID.length)
        self.settings.identityID = self.session.identityID;
    }

exit:
    self.error = error;
    if (self.completion)
        self.completion(self);
}

- (NSError*) verifyNetworkOperation:(id<BNCNetworkOperationProtocol>)operation {
    if (!operation) {
        NSString *message = BNCLocalizedString(
            @"A network operation instance is expected to be returned by the"
             " networkOperationWithURLRequest:completion: method."
        );
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (![operation conformsToProtocol:@protocol(BNCNetworkOperationProtocol)]) {
        NSString *message =
            BNCLocalizedFormattedString(
                @"Network operation of class '%@' does not conform to the BNCNetworkOperationProtocol.",
                NSStringFromClass([operation class]));
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (!operation.request) {
        NSString *message = BNCLocalizedString(
            @"The network operation request is not set. The Branch SDK expects the network operation"
             " request to be set by the network provider."
        );
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    return nil;
}

- (void) collectInstrumentationMetrics {
    if ([self.operation.request.HTTPMethod isEqualToString:@"POST"]) {
        NSTimeInterval elapsedTime = [self.startDate timeIntervalSinceNow] * -1000.0;
        NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
        NSString *path = [self.operation.request.URL path];
        NSString *brttKey = [NSString stringWithFormat:@"%@-brtt", path];
        self.settings.instrumentationDictionary = nil;
        self.settings.instrumentationDictionary[brttKey] = lastRoundTripTime;
    }
}

+ (BOOL) canRetryOperation:(id<BNCNetworkOperationProtocol>)operation {
    if (operation.error == nil && operation.HTTPStatusCode >= 200 && operation.HTTPStatusCode < 300)
        return NO;
    if (operation.HTTPStatusCode >= 500 || operation.HTTPStatusCode == 408)
        return YES;
    switch (operation.error.code) {
    // Possible poor network condition codes. From NSURLError.h:
    case NSURLErrorTimedOut:                // Timeout.
    case NSURLErrorCannotFindHost:          // DNS error.
    case NSURLErrorNetworkConnectionLost:   // Network dropped.
    case NSURLErrorSecureConnectionFailed:  // SSL may have timed out.
    case errSSLClosedAbort:                 // SSL may have timed out.
        return YES;
    default:
        return NO;
    }
}

+ (NSDictionary*) dictionaryWithJSONData:(NSData*)data
        error:(NSError*_Nullable __autoreleasing *_Nullable)error_ {
    NSError*error = nil;
    NSDictionary*dictionary = nil;
    @try {
        if ([data isKindOfClass:[NSData class]]) {
            dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        } else {
            error =
                [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                    userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode JSON data."}];
        }
    }
    @catch (id object) {
        dictionary = nil;
        if ([object isKindOfClass:[NSError class]]) {
            error = object;
        } else {
            error =
                [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                    userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode JSON data."}];
        }
    }
exit:
    if (error_) *error_ = error;
    return dictionary;
}

+ (NSError*) errorWithOperation:(id<BNCNetworkOperationProtocol>)operation {
    NSError *underlyingError = operation.error;
    NSInteger status = operation.HTTPStatusCode;
    NSError *branchError = nil;

    // Wrap up bad statuses w/ specific error messages
    if (status >= 500 || status == 408) {
        branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
    }
    else if (status == 409) {
        branchError = [NSError branchErrorWithCode:BNCDuplicateResourceError error:underlyingError];
    }
    else if (status >= 400) {

        NSDictionary*dictionary = [self dictionaryWithJSONData:operation.responseData error:nil];
        if (![dictionary isKindOfClass:NSDictionary.class])
            dictionary = nil;

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

#pragma mark - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    self.URL = [aDecoder decodeObjectOfClass:NSURL.class forKey:@"URL"];
    self.dictionary = [aDecoder decodeObjectOfClass:NSDictionary.class forKey:@"dictionary"];
    self.identifier = [aDecoder decodeObjectOfClass:NSString.class forKey:@"identifier"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.URL forKey:@"URL"];
    [aCoder encodeObject:self.dictionary forKey:@"dictionary"];
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
}

@end
