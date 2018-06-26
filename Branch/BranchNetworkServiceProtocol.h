/**
 @file          BranchNetworkServiceProtocol.h
 @package       Branch-SDK
 @brief         A networking protocol contract to an abstract underlying network class.

 @author        Edward Smith
 @date          May 30, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark BNCNetworkOperationProtocol

/**
 @name The `BNCNetworkServiceProtocol` and `BNCNetworkOperationProtocol` protocols.

 @discussion
 The protocols `BNCNetworkServiceProtocol` and `BNCNetworkOperationProtocol` describe the methods
 needed to create a drop in replacement for the standard Branch SDK networking.

 See `Branch-SDK/Network/BNCNetworkService.h` and `Branch-SDK/Network/BNCNetworkService.m` for a
 concrete example of how to implement the BNCNetworkServiceProtocol and BNCNetworkOperationProtocol
 protocols.

 Usage
 -----
 
 1. Create your own network service class that follows the `BNCNetworkServiceProtocol`.
    The `new` and `networkOperationWithURLRequest:completion:` methods are required. The
    others are optional.

 2. Create your own network operation class that follows the `BNCNetworkOperationProtocol`.
    The `start` method is required, as are all the getters for request, response, error, and date
    data items.

 3. In your app delegate, set your network class by calling `[Branch setNetworkServiceClass:]` with
    your network class as a parameter. This method must be called before initializing the Branch 
    shared object.

*/
@protocol BNCNetworkOperationProtocol <NSObject>

/// The initial NSMutableURLRequest.
@required
@property (readonly) NSURLRequest *request;

/// The response code from the server.
@required
@property (readonly) NSInteger HTTPStatusCode;

/// The data from the server.
@required
@property (readonly) NSData*_Nullable responseData;

/// Any errors that occurred during the request.
@required
@property (readonly) NSError*_Nullable error;

/// Starts the network operation.
@required
- (void) start;

/// Cancels a queued or in progress network operation.
@optional
- (void) cancel;

@end

#pragma mark - BNCNetworkServiceProtocol

/** 
    The `BNCNetworkServiceProtocol` defines a network service that handles a queue of network
    operations.
*/
@protocol BNCNetworkServiceProtocol <NSObject>

/// Creates and returns a new network service.
@required
+ (id<BNCNetworkServiceProtocol>) new;

/// Cancel all current and queued network operations.
@optional
- (void) cancelAllOperations;

/// Create and return a new network operation object. The network operation is not started until
/// `[operation start]` is called.
@required
- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

/// Pins the session to the array of public keys.
@optional
- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*_Nullable)publicKeys;

@end

NS_ASSUME_NONNULL_END
