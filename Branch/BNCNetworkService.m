/**
 @file          BNCNetworkService.m
 @package       Branch
 @brief         Basic Networking Services

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCNetworkService.h"
#import "BNCLog.h"

#pragma mark  BNCNetworkOperation

@interface BNCNetworkOperation ()
@property NSURLSessionTaskState sessionState;
@property BNCNetworkService     *networkService;
@property NSMutableURLRequest   *request;
@property NSHTTPURLResponse     *response;
@property NSData                *responseData;
@property NSURLSessionTask      *sessionTask;
@property NSError               *error;
@property (copy, nullable) void (^completionBlock)(BNCNetworkOperation*);
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService () <NSURLSessionDelegate> {
    NSMutableArray*_pinnedPublicKeys;
    NSMutableSet<NSString*>*_anySSLCertHosts;
    NSOperationQueue*_serviceQueue;
    NSURLSession*_session;
}

- (void) startOperation:(BNCNetworkOperation*)operation;

@property (atomic, readonly) NSOperationQueue *serviceQueue;
@property (atomic, readonly) NSURLSession *session;
@end

#pragma mark - BNCNetworkOperation

@implementation BNCNetworkOperation

- (NSInteger) HTTPStatusCode {
    return self.response.statusCode;
}

- (void) cancel {
    [self.sessionTask cancel];
}

- (void) start {
    [self.networkService startOperation:self];
}

@end

#pragma mark - BNCNetworkService

@implementation BNCNetworkService

- (instancetype) init {
    self = [super init];
    return self;
}

- (NSOperationQueue*) serviceQueue {
    @synchronized(self) {
        if (_serviceQueue) return _serviceQueue;
        _serviceQueue = [NSOperationQueue new];
        _serviceQueue.name = @"io.branch.network.queue";
        _serviceQueue.maxConcurrentOperationCount = 3;
        _serviceQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        return _serviceQueue;
    }
}

- (NSURLSession*) session {
    @synchronized(self) {
        if (_session) return _session;

        NSError *error = nil;
        NSURL *cacheURL =
            [[NSFileManager defaultManager]
                URLForDirectory:NSCachesDirectory
                inDomain:NSUserDomainMask | NSLocalDomainMask
                appropriateForURL:nil
                create:YES
                error:&error];
        if (error) {
            BNCLogError(@"Error locating cache directory. Will use local directory instead. %@.", error);
            cacheURL = [NSURL fileURLWithPath:@"."];
        }
        cacheURL = [cacheURL URLByAppendingPathComponent:@"io.branch.network.cache"];

        NSURLSessionConfiguration *configuration =
            [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 60.0;
        configuration.timeoutIntervalForResource = 60.0;
        configuration.URLCache =
            [[NSURLCache alloc]
                initWithMemoryCapacity:20*1024*1024
                diskCapacity:200*1024*1024
                diskPath:[cacheURL path]];

        _session =
            [NSURLSession sessionWithConfiguration:configuration
                delegate:self
                delegateQueue:self.serviceQueue];
        _session.sessionDescription = @"io.branch.network.session";
        return _session;
    }
}

- (void) setMaxConcurrentOperationCount:(NSInteger)count {
    self.serviceQueue.maxConcurrentOperationCount = count;
}

- (NSInteger) maxConcurrentOperationCount {
    return self.serviceQueue.maxConcurrentOperationCount;
}

- (NSMutableSet<NSString*>*) anySSLCertHosts {
    @synchronized(self) {
        if (!_anySSLCertHosts) _anySSLCertHosts = [NSMutableSet new];
        return _anySSLCertHosts;
    }
}

- (void) setAnySSLCertHosts:(NSMutableSet<NSString*>*)anySSLCertHosts_ {
    @synchronized(self) {
        _anySSLCertHosts = [anySSLCertHosts_ copy];
    }
}

- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion {
    BNCNetworkOperation *operation = [BNCNetworkOperation new];
    operation.request = request;
    operation.networkService = self;
    operation.completionBlock = completion;
    return operation;
}

+ (NSString*) formattedStringWithData:(NSData*)data {
    if (!data) return nil;
    NSString*responseString = nil;
    @try {
        NSDictionary*dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dictionary) {
            // (NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys) = 3
            NSData*formattedData = [NSJSONSerialization dataWithJSONObject:dictionary options:3 error:nil];
            if (formattedData)
                responseString = [[NSString alloc] initWithData:formattedData encoding:NSUTF8StringEncoding];
        }
        if (!responseString)
            responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!responseString)
            responseString = data.description;
    }
    @catch(id error) {
    }
    return responseString;
}

- (void) startOperation:(BNCNetworkOperation*)operation {
    NSDate*startDate = [NSDate date];
    operation.networkService = self;
    operation.sessionTask =
        [self.session dataTaskWithRequest:operation.request
            completionHandler:
            ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                operation.responseData = data;
                operation.response = (NSHTTPURLResponse*) response;
                operation.error = error;
                NSString*responseString = [self.class formattedStringWithData:data];
                BNCLogDebug(@"Network finish operation %@ %1.3fs. Status %ld error %@.\n%@.",
                    operation.request.URL.absoluteString,
                    - [startDate timeIntervalSinceNow],
                    (long)operation.HTTPStatusCode,
                    operation.error,
                    responseString);
                if (operation.completionBlock)
                    operation.completionBlock(operation);
            }
        ];
    NSString*requestString = [self.class formattedStringWithData:operation.request.HTTPBody];
    BNCLogDebug(@"Network start %@ %@\n%@.",
        operation.request.HTTPMethod, operation.request.URL, requestString);
    [operation.sessionTask resume];
}

#pragma mark - Transport Security

- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*)publicKeys {
    @synchronized (self) {
        NSError*error = nil;
        _pinnedPublicKeys = [NSMutableArray array];
        for (id secKey in publicKeys) {
            if (CFGetTypeID((SecKeyRef)secKey) == SecKeyGetTypeID())
                [_pinnedPublicKeys addObject:secKey];
            else {
                error = [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSNetServicesBadArgumentError userInfo:nil];
            }
        }
        return error;
    }
}

- (NSArray*) pinnedPublicKeys {
    @synchronized (self) {
        return _pinnedPublicKeys;
    }
}

- (void) URLSession:(NSURLSession *)session
               task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
        NSURLCredential *credential))completionHandler {

    BOOL trusted = NO;
    SecTrustResultType trustResult = 0;
    OSStatus err = 0;

    // Keep a local copy in case they mutate.
    NSArray *localPinnedKeys = [self.pinnedPublicKeys copy];
    NSSet<NSString*>*localAllowedHosts = [self.anySSLCertHosts copy];
    
    // Release these:
    SecKeyRef key = nil;
    SecPolicyRef hostPolicy = nil;

    // Get remote certificate
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    @synchronized ((__bridge id<NSObject, OS_dispatch_semaphore>)serverTrust) {

        // Set SSL policies for domain name check
        hostPolicy = SecPolicyCreateSSL(true, (__bridge CFStringRef)challenge.protectionSpace.host);
        if (!hostPolicy) goto exit;
        SecTrustSetPolicies(serverTrust, (__bridge CFTypeRef _Nonnull)(@[ (__bridge id)hostPolicy ]));

        // Evaluate server certificate
        SecTrustEvaluate(serverTrust, &trustResult);
        switch (trustResult) {
        case kSecTrustResultRecoverableTrustFailure:
            if ([localAllowedHosts containsObject:challenge.protectionSpace.host])
                break;
            else
                goto exit;
        case kSecTrustResultUnspecified:
        case kSecTrustResultProceed:
            break;
        default:
            goto exit;
        }

        if (localPinnedKeys == nil) {
            trusted = YES;
            goto exit;
        }

        key = SecTrustCopyPublicKey(serverTrust);
        if (!key) goto exit;
    }

    for (id<NSObject> pinnedKey in localPinnedKeys) {
        if ([pinnedKey isEqual:(__bridge id<NSObject>)key]) {
            trusted = YES;
            goto exit;
        }
    }

exit:
    if (err) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        BNCLogError(@"Error while validating cert: %@.", error);
    }
    if (key) CFRelease(key);
    if (hostPolicy) CFRelease(hostPolicy);

    if (trusted) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
    }
}

- (void) cancelAllOperations {
    @synchronized(self) {
        [self.session invalidateAndCancel];
        _session = nil;
    }
}

@end
