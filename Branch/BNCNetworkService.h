/**
 @file          BNCNetworkService.h
 @package       Branch-SDK
 @brief         Basic Networking Services

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BNCNetworkServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark BNCNetworkOperation

@interface BNCNetworkOperation : NSObject <BNCNetworkOperationProtocol>

@property (readonly) NSMutableURLRequest* request;
@property (readonly) NSError*_Nullable error;
@property (readonly) NSInteger        HTTPStatusCode;
@property (readonly) NSData*_Nullable responseData;

- (void) start;
- (void) cancel;
@end

#pragma mark - BNCNetworkService

@interface BNCNetworkService : NSObject <BNCNetworkServiceProtocol>

- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*_Nullable)publicKeys;

/// An array of host domains that we will allow with a self-signed SSL cert.
@property (atomic, strong, null_resettable) NSMutableSet<NSString*>* anySSLCertHosts;
@property (atomic, assign) NSInteger maxConcurrentOperationCount;
@end

NS_ASSUME_NONNULL_END

