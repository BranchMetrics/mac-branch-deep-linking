/**
 @file          BranchError.h
 @package       Branch
 @brief         Branch errors.

 @author        Qinwei Gong
 @date          November 2014
 @copyright     Copyright © 2014 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN


#ifndef BranchError_h
#define BranchError_h

/// The Branch error domain.
FOUNDATION_EXPORT NSString*const BNCErrorDomain;

/// Branch specific error codes.
typedef NS_ENUM(NSInteger, BNCErrorCode) {
    BNCInitError                    = 1000, //!< The main Branch instance wasn't initialized correctly.
    BNCDuplicateResourceError       = 1001, //!< A requested resource, such as a short link, already exists.
    BNCRedeemCreditsError           = 1002, //!< The credits could not be redeemed.
    BNCBadRequestError              = 1003,
    BNCServerProblemError           = 1004,
    BNCNilLogError                  = 1005, //!< Not used at the moment.
    BNCVersionError                 = 1006, //!< Not used at the moment.
    BNCNetworkServiceInterfaceError = 1007,
    BNCContentIdentifierError       = 1008,
    BNCSpotlightNotAvailableError   = 1009,
    BNCSpotlightTitleError          = 1010,
    BNCRedeemZeroCreditsError       = 1011,
    BNCSpotlightIdentifierError     = 1012,
    BNCSpotlightPublicIndexError    = 1013,
    BNCTrackingDisabledError        = 1014,
    BNCHighestError,
};

/**
 A convenience category for creating Branch errors.
*/
@interface NSError (Branch)
+ (NSError*) branchErrorWithCode:(BNCErrorCode)errorCode;
+ (NSError*) branchErrorWithCode:(BNCErrorCode)errorCode error:(NSError*_Nullable)error;
+ (NSError*) branchErrorWithCode:(BNCErrorCode)errorCode localizedMessage:(NSString*_Nullable)message;
@end

///
FOUNDATION_EXPORT void BNCForceNSErrorCategoryToLoad(void)
    __attribute__((constructor));

#endif

NS_ASSUME_NONNULL_END
