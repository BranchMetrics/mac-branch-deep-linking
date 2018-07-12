/**
 @file          BranchDelegate.h
 @package       Branch
 @brief         Branch delegate protocol and notifications.

 @author        Edward Smith
 @date          June 30, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"
@class Branch, BranchSession;

NS_ASSUME_NONNULL_BEGIN

/**
 @name Branch Notifications and delegate methods.

 The Branch SDK can signal your app in three different ways when an deep link is available for your app to
 handle: You can set a callback block, you can set a delegate, or you can add an observer for NSNotifications.
 You can choose the that best suits your app archetcture.
 */

#pragma mark BranchDelegate Protocol

/**
 These delegate methods are called when while Branch is starting a new URL session and possibly opening a
 deep link. All the methods are optional.

 ```objc
 [Branch sharedInstance].delegate = delegateInstance;
 ```

*/
@protocol BranchDelegate <NSObject>

@optional
- (void) branch:(Branch*)branch willStartSessionWithURL:(NSURL*_Nullable)url;
- (void) branch:(Branch*)branch didStartSession:(BranchSession*)session;
- (void) branch:(Branch*)branch failedToStartSessionWithURL:(NSURL*_Nullable)url
                                                      error:(NSError*_Nullable)error;
- (void) branch:(Branch*)branch didOpenURLWithSession:(BranchSession*)session;
@end

#pragma mark - Branch Notifications and Keys

/**
 @name Branch Notifications

 The advantage of observing Branch NSNotifications is that it allows for more modularized code with greater
 separation of responsibility. Only those classes that care about Branch notifications need to know about
 them. This is particularly useful as your project grows larger and dependency management becomes an issue.

 #### **`BranchWillStartSessionNotification`**

 This notification is sent just before the Branch SDK is about to determine if there is a deep link for your
 app to handle. This usually involves a server call so it may take some time for the SDK to make the
 determination.

 ##### Notification Keys

 The notification `userInfo` dictionary may have these keys:

  Key | Value Type | Content
 :---:|:----------:|:-------
 `BranchURLKey` <br>(Optional) | NSURL | This is the URL if the Branch session was started with a URL.

 #### **`BranchDidStartSessionNotification`**

 This notification is sent when the Branch SDK has started a new URL session. There may or may not be a deep
 link for your app to handle. If there is, the `BranchSessionKey` value will have a BranchSession that
 contains the deep link content.

 If an error has occurred the `BranchErrorKey` value will contain an `NSError` that describes the error.

 ##### Notification Keys

 The notification `userInfo` dictionary may have these keys:

  Key | Value Type | Content
 :---:|:----------:|:-------
 `BranchURLKey`<br>(Optional) | NSURL | This is the URL that started the Branch session.
 `BranchSessionKey`<br>(Optional) | BranchSession | If the Branch session has a Branch deep link for your app to handle, this is the deep link content decoded into a BranchSession.
 `BranchErrorKey`<br>(Optional) | NSError | If an error occurred while starting the Branch session, this the NSError that describes the error.
*/

FOUNDATION_EXPORT NSString*const BranchWillStartSessionNotification;
FOUNDATION_EXPORT NSString*const BranchDidStartSessionNotification;
FOUNDATION_EXPORT NSString*const BranchDidOpenURLWithSessionNotification;

FOUNDATION_EXPORT NSString*const BranchURLKey;
FOUNDATION_EXPORT NSString*const BranchSessionKey;
FOUNDATION_EXPORT NSString*const BranchErrorKey;

NS_ASSUME_NONNULL_END
