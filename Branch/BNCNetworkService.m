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

- (void) cancelAllOperations {
    @synchronized(self) {
        [self.session invalidateAndCancel];
        _session = nil;
    }
}

@end
