/**
 @file          BranchDelegate.m
 @package       Branch
 @brief         Branch delegate protocol and notifications.

 @author        Edward Smith
 @date          June 30, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchDelegate.h"

NSString* const BranchWillStartSessionNotification      = @"BranchWillStartSessionNotification";
NSString* const BranchDidStartSessionNotification       = @"BranchDidStartSessionNotification";
NSString* const BranchDidOpenURLWithSessionNotification = @"BranchDidOpenURLWithSessionNotification";

NSString* const BranchErrorKey   = @"BranchErrorKey";
NSString* const BranchURLKey     = @"BranchURLKey";
NSString* const BranchSessionKey = @"BranchSessionKey";
