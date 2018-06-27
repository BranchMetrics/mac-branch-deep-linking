/**
 @file          BNCTestNetworkService.h
 @package       BranchTests
 @brief         A class for mocking network service calls.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "BranchNetworkServiceProtocol.h"
#import "BNCNetworkAPIService.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark BNCTestNetworkOperation

@interface BNCTestNetworkOperation : NSObject <BNCNetworkOperationProtocol>
@property (strong) NSMutableURLRequest* request;
@property (assign) NSInteger HTTPStatusCode;
@property (strong) NSError*_Nullable error;
//@property (strong) NSDate*_Nullable startDate;
//@property (strong) NSDate*_Nullable timeoutDate;
@property (strong) NSData*_Nullable responseData;
//@property (strong) NSDictionary*userInfo;
- (void) start;
- (void) cancel;
@end

#pragma mark - BNCTestNetworkService

@interface BNCTestNetworkService : NSObject <BNCNetworkServiceProtocol>

- (id<BNCNetworkOperationProtocol>) networkOperationWithURLRequest:(NSMutableURLRequest*)request
                completion:(void (^)(id<BNCNetworkOperationProtocol>operation))completion;

- (NSError*_Nullable) pinSessionToPublicSecKeyRefs:(NSArray/**<SecKeyRef>*/*_Nullable)publicKeys;

//@property (atomic, strong) NSDictionary*_Nullable userInfo;

// Properties and methods for mocking tests:

@property (atomic, class, copy) id<BNCNetworkOperationProtocol>(^_Nullable requestHandler)(NSMutableURLRequest*request);

+ (NSMutableDictionary*_Nullable) mutableDictionaryFromRequest:(NSURLRequest*)request;

+ (id<BNCNetworkOperationProtocol>) operationWithRequest:(NSMutableURLRequest*)request
                                                response:(NSString*_Nullable)responseString;
@end

NS_ASSUME_NONNULL_END

