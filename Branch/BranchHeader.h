/**
 @file          BranchHeader.h
 @package       Branch
 @brief         Imports the system header dependencies for the Branch SDK.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#ifndef BranchHeader_h
#define BranchHeader_h

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if __has_feature(modules)
@import AppKit;
#else
#import <AppKit/Appkit.h>
#endif

#endif // BranchHeader_h
