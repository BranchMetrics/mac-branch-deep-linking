/**
 @file          BNCNetworkAPIService.h
 @package       Branch-SDK
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchSession.h"
#import "BranchNetworkServiceProtocol.h"
@class BranchConfiguration;

NS_ASSUME_NONNULL_BEGIN

#pragma mark BNCNetworkAPIOperation

@interface BNCNetworkAPIOperation : NSOperation
@property (atomic, strong) id<BNCNetworkOperationProtocol> operation;
@property (atomic, strong) NSDate*_Nullable startDate;
@property (atomic, strong) NSDate*_Nullable timeoutDate;
@property (atomic, strong) NSError*_Nullable error;
@property (atomic, strong) BranchSession*_Nullable session;
@end

#pragma mark - BNCNetworkAPIService

@interface BNCNetworkAPIService : NSObject
- (instancetype) initWithConfiguration:(BranchConfiguration*)configuration;

- (void) appendV1APIParametersWithDictionary:(NSMutableDictionary*)dictionary;
- (void) appendV2APIParametersWithDictionary:(NSMutableDictionary*)dictionary;

/**
 @param  serviceName    The Branch end point name, like "v2/event" or "v1/open".
 @param  dictionary     The dictionary for the JSON post content.
 @param  completion     The completion block that receives the response data.
 */
- (void) postOperationForAPIServiceName:(NSString*)serviceName
        dictionary:(NSDictionary*)dictionary
        completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion;

- (void) clearNetworkQueue;
@end

NS_ASSUME_NONNULL_END
