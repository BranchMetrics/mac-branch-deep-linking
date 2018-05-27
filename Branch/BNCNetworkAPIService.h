/**
 @file          BNCNetworkAPIService.h
 @package       Branch-SDK
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BNCNetworkService.h"
@class BranchConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface BNCNetworkAPIService : NSObject
- (instancetype) initWithConfiguration:(BranchConfiguration*)configuration;
- (void) openURL:(NSURL*_Nullable)url;
- (void) sendClose;

/**
 @param  serviceName    The Branch end point name, like "v2/event" or "v1/open".
 @param  dictionary     The dictionary for the JSON post content.
 @param  completion     The completion block that receives the response data.
 */
- (void) postOperationForAPIServiceName:(NSString*)serviceName //!< Like "v2/event".
        dictionary:(NSDictionary*)dictionary
        completion:(void (^_Nullable)(BNCNetworkOperation*operation))completion;

@end

NS_ASSUME_NONNULL_END
