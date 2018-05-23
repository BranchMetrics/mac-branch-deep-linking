/**
 @file          BNCNetworkService.m
 @package       Branch-SDK
 @brief         Basic Networking Services

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCNetworkService.h"
#import "BNCLog.h"

#pragma mark  BNCNetworkOperation

@interface BNCNetworkOperation ()
@property BNCNetworkService     *networkService;
@property NSMutableURLRequest   *request;
@property NSHTTPURLResponse     *response;
@property NSURLSessionTask      *sessionTask;
@property NSError               *error;
@property id<NSObject>          responseData;
@property NSDate                *dateStart;
@property NSDate                *dateFinish;
@property (copy, nullable) void (^completionBlock)(BNCNetworkOperation*);
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService () <NSURLSessionDelegate> {
    NSMutableArray*_pinnedPublicKeys;
    NSMutableSet<NSString*>*_anySSLCertHosts;
}

- (void) startOperation:(BNCNetworkOperation*)operation;

@property NSOperationQueue *serviceQueue;
@property NSURLSession *session;
@end

#pragma mark - BNCNetworkOperation

@implementation BNCNetworkOperation

- (NSURLSessionTaskState) sessionState {
    return self.sessionTask.state;
}

- (NSInteger) HTTPStatusCode {
    return self.response.statusCode;
}

- (void) cancel {
    [self.sessionTask cancel];
}

- (void) deserializeJSONResponseData {
    if (![self.responseData isKindOfClass:[NSData class]]) {
        self.error =
            [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode JSON data."}];
        return;
    }
    NSError *error = nil;
    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:(NSData*)self.responseData
            options:0 error:&error];
    if (error) {
        self.error = error;
        return;
    }
    self.responseData = dictionary;
}

- (NSString*) stringFromResponseData {
    NSString *string = nil;
    if ([self.responseData isKindOfClass:[NSData class]]) {
        string = [[NSString alloc] initWithData:(NSData*)self.responseData encoding:NSUTF8StringEncoding];
    }
    if (!string && [self.responseData isKindOfClass:[NSData class]]) {
        string = [NSString stringWithFormat:@"<NSData of length %ld.>",
            (long)[(NSData*)self.responseData length]];
    }
    if (!string) {
        string = self.responseData.description;
    }
    return string;
}

- (void) start {
    [self.networkService startOperation:self];
}

@end

#pragma mark - BNCNetworkService

@implementation BNCNetworkService

+ (BNCNetworkService*) shared {
    static BNCNetworkService* sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init {
    self = [super init];
    if (!self) return self;

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

    self.serviceQueue = [NSOperationQueue new];
    self.serviceQueue.name = @"io.branch.network.queue";
    self.serviceQueue.maxConcurrentOperationCount = 3;
    self.serviceQueue.qualityOfService = NSQualityOfServiceUserInteractive;

    self.session =
        [NSURLSession sessionWithConfiguration:configuration
            delegate:self
            delegateQueue:self.serviceQueue];
    self.session.sessionDescription = @"io.branch.network.session";

    return self;
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

- (BNCNetworkOperation*) networkOperationWithURL:(NSURL*)URL {

    BNCNetworkOperation *operation = [BNCNetworkOperation new];
    operation.request =
    [[NSMutableURLRequest alloc]
        initWithURL:URL
        cachePolicy:NSURLRequestReloadIgnoringCacheData
        timeoutInterval:60.0];
    operation.networkService = self;
    return operation;
}

- (BNCNetworkOperation*) getOperationWithURL:(NSURL *)URL
                        completion:(void (^)(BNCNetworkOperation*))completion {
    BNCNetworkOperation *operation = [self networkOperationWithURL:URL];
    operation.completionBlock = completion;
    return operation;
}

- (BNCNetworkOperation*) postOperationWithURL:(NSURL *)URL
                        contentType:(NSString*)contentType
                               data:(NSData *)data
                         completion:(void (^)(BNCNetworkOperation *))completion {
                         
    BNCNetworkOperation *operation = [self networkOperationWithURL:URL];
    operation.request.HTTPMethod = @"POST";
    operation.completionBlock = completion;
    if (contentType.length)
        [operation.request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    operation.request.HTTPBody = data;
    return operation;
}

- (BNCNetworkOperation*) postOperationWithURL:(NSURL *)URL
                                     JSONData:(id)dictionaryOrArray
                                   completion:(void (^)(BNCNetworkOperation*operation))completion {
    NSData *data = nil;
    if (dictionaryOrArray) {
        NSError *error = nil;
        data = [NSJSONSerialization dataWithJSONObject:dictionaryOrArray options:0 error:&error];
        if (error) BNCLogError(@"Can't convert to JSON: %@.", error);
        BNCLogDebug(@"POST\n URL: %@\nBody: %@.", URL, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    BNCNetworkOperation *operation =
        [[BNCNetworkService shared]
            postOperationWithURL:URL
            contentType:@"application/json"
            data:data
            completion:completion];
    return operation;
}

- (void) startOperation:(BNCNetworkOperation*)operation {
    operation.networkService = self;
    operation.dateStart = [NSDate date];
    operation.sessionTask =
        [self.session dataTaskWithRequest:operation.request
            completionHandler:
            ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                operation.responseData = data;
                operation.response = (NSHTTPURLResponse*) response;
                operation.error = error;
                operation.dateFinish = [NSDate date];
                BNCLogDebug(@"Network finish operation %@ %1.3fs. Status %ld error %@.\n%@.",
                    operation.request.URL.absoluteString,
                    [operation.dateFinish timeIntervalSinceDate:operation.dateStart],
                    (long)operation.HTTPStatusCode,
                    operation.error,
                    operation.stringFromResponseData);
                if (operation.completionBlock)
                    operation.completionBlock(operation);
            }];
    BNCLogDebug(@"Network start operation %@.", operation.request.URL);
    [operation.sessionTask resume];
}

#pragma mark - The gorey details

- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*)publicKeys {
    @synchronized (self) {
        _pinnedPublicKeys = [NSMutableArray array];
        for (id secKey in publicKeys) {
            if (CFGetTypeID((SecKeyRef)secKey) == SecKeyGetTypeID())
                [_pinnedPublicKeys addObject:secKey];
            else {
                return [NSError errorWithDomain:NSNetServicesErrorDomain
                    code:NSNetServicesBadArgumentError userInfo:nil];
            }
        }
        return nil;
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
  completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

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

        if (localPinnedKeys.count == 0) {
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

@end
