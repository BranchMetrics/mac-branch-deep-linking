/**
 @file          Branch.h
 @package       Branch
 @brief         The Branch framework header.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

/// The Branch SDK version number as a double.
FOUNDATION_EXPORT double BranchVersionNumber;

/// The Branch SDK version framework string.
FOUNDATION_EXPORT const unsigned char BranchVersionString[];

#import "BranchCommerce.h"
#import "BranchDelegate.h"
#import "BranchError.h"
#import "BranchEvent.h"
#import "BranchLinkProperties.h"
#import "BranchNetworkServiceProtocol.h"
#import "BranchMainClass.h"
#import "BranchMutableDictionary.h"
#import "BranchSession.h"
#import "BranchUniversalObject.h"

// Exposed private headers:
#import "BNCLog.h"
