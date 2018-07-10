/**
 @file          Branch.h
 @package       Branch
 @brief         The Branch framework header.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Branch/BranchHeader.h>

/// The Branch SDK version number as a double.
FOUNDATION_EXPORT double BranchVersionNumber;

/// The Branch SDK version framework string.
FOUNDATION_EXPORT const unsigned char BranchVersionString[];

#import <Branch/BranchCommerce.h>
#import <Branch/BranchDelegate.h>
#import <Branch/BranchError.h>
#import <Branch/BranchEvent.h>
#import <Branch/BranchLinkProperties.h>
#import <Branch/BranchNetworkServiceProtocol.h>
#import <Branch/BranchMainClass.h>
#import <Branch/BranchMutableDictionary.h>
#import <Branch/BranchSession.h>
#import <Branch/BranchUniversalObject.h>

// Exposed private headers:
#import <Branch/BNCLog.h>
