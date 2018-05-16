/**
 @file          BranchFramework.h
 @package       Branch-SDK
 @brief         Branch framework header.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

FOUNDATION_EXPORT double BranchVersionNumber;
FOUNDATION_EXPORT const unsigned char BranchVersionString[];

#import <Branch/BranchMain.h>
#import <Branch/BNCDebug.h>
#import <Branch/BNCLog.h>
