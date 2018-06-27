/**
 @file          BNCTestNetworkService.m
 @package       BranchTests
 @brief         A class for mocking network service calls.

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestNetworkService.h"
#import "BNCThreads.h"

@interface BNCTestNetworkService ()
- (void) startOperation:(BNCTestNetworkOperation*)operation;
@end

#pragma mark BNCTestNetworkOperation

@interface BNCTestNetworkOperation ()
@property (strong) BNCTestNetworkService*networkService;
@property (copy, nullable) void (^completionBlock)(BNCTestNetworkOperation*);
@end

@implementation BNCTestNetworkOperation

- (void) start {
    [self.networkService startOperation:self];
}

- (void) cancel {
}

@end

#pragma mark - BNCTestNetworkService

@implementation BNCTestNetworkService

static id<BNCNetworkOperationProtocol>(^_requestHandler)(NSMutableURLRequest*request);

+ (void) setRequestHandler:(id<BNCNetworkOperationProtocol>_Nonnull(^)(NSMutableURLRequest*_Nonnull))requestHandler {
    @synchronized(self) {
        _requestHandler = [requestHandler copy];
    }
}

+ (id<BNCNetworkOperationProtocol>  _Nonnull (^)(NSMutableURLRequest * _Nonnull))requestHandler {
    @synchronized(self) {
        return [_requestHandler copy];
    }
}

+ (NSMutableDictionary*) mutableDictionaryFromRequest:(NSURLRequest*)request {
    NSData*data = request.HTTPBody;
    if (!data) return nil;
    NSMutableDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
        options:NSJSONReadingMutableContainers error:nil];
    return dictionary;
}

+ (id<BNCNetworkOperationProtocol>) operationWithRequest:(NSMutableURLRequest*)request
                                                response:(NSString*)responseString {
    BNCTestNetworkOperation*operation = [[BNCTestNetworkOperation alloc] init];
    operation.request = request;
    operation.HTTPStatusCode = 200;
    operation.responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    return operation;
}

#pragma mark - Protocol Methods

- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion {
    id<BNCNetworkOperationProtocol>operation = nil;
    if (self.class.requestHandler == nil) {
//        [NSException raise:NSInternalInconsistencyException
//            format:@"%@ requestHandler not set!", NSStringFromClass(self.class)];
        operation = [self.class operationWithRequest:request response:@"{}"];
    } else {
        operation = self.class.requestHandler(request);
    }
    ((BNCTestNetworkOperation*)operation).networkService = self;
    ((BNCTestNetworkOperation*)operation).completionBlock = completion;
    return operation;
}

- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*_Nullable)publicKeys {
    return nil;
}

- (void) startOperation:(BNCTestNetworkOperation*)operation {
    operation.networkService = self;
//    operation.startDate = [NSDate date];
//    operation.timeoutDate = [operation.startDate dateByAddingTimeInterval:operation.request.timeoutInterval];
    BNCAfterSecondsPerformBlockOnMainThread(0.010, ^{
        if (operation.completionBlock)
            operation.completionBlock(operation);
    });
}

@end
