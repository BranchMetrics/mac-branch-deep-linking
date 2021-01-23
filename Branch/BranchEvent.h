/**
 @file          BranchEvent.h
 @package       Branch
 @brief         Event actions for logging user events, especially commerce events.

 @author        Edward Smith
 @date          July 24, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchCommerce.h"
#import "BranchUniversalObject.h"
#import "BranchMainClass.h"

NS_ASSUME_NONNULL_BEGIN


#ifndef BranchEvent_h
#define BranchEvent_h

///@group Branch Event Logging

typedef NSString*const BranchStandardEvent NS_STRING_ENUM;

///@name Commerce Events

FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAddToCart;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAddToWishlist;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewCart;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventInitiatePurchase;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAddPaymentInfo;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventPurchase;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventSpendCredits;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventSubscribe;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventStartTrial;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventClickAd;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewAd;

///@name Content Events

FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventSearch;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewItem;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewItems;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventRate;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventShare;

///@name User Lifecycle Events

FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventCompleteRegistration;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventCompleteTutorial;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAchieveLevel;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventUnlockAchievement;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventInvite;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventLogin;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventReserve;

typedef NS_ENUM(NSInteger, BranchEventAdType) {
    BranchEventAdTypeNone,
    BranchEventAdTypeBanner,
    BranchEventAdTypeInterstitial,
    BranchEventAdTypeRewardedVideo,
    BranchEventAdTypeNative
};

#pragma mark - BranchEvent

/**
 User actions and app events can be tracked with BranchEvent. BranchEvents can be attributed back
 to Branch sessions and campaigns in the Branch dashboard, giving you greater insight into effective
 campaigns and app use.
 */
@interface BranchEvent : NSObject

- (instancetype _Nonnull) initWithName:(NSString*_Nonnull)name NS_DESIGNATED_INITIALIZER;

+ (instancetype _Nonnull) standardEvent:(BranchStandardEvent _Nonnull)standardEvent;
+ (instancetype _Nonnull) standardEvent:(BranchStandardEvent _Nonnull)standardEvent
                            contentItem:(BranchUniversalObject* _Nonnull)contentItem;

+ (instancetype _Nonnull) customEventWithName:(NSString*_Nonnull)name;
+ (instancetype _Nonnull) customEventWithName:(NSString*_Nonnull)name
                                  contentItem:(BranchUniversalObject*_Nonnull)contentItem;

- (instancetype _Nonnull) init __attribute((unavailable));
+ (instancetype _Nonnull) new __attribute((unavailable));

@property (nonatomic, strong, readonly) NSString*               eventName;
@property (nonatomic, strong) NSString*_Nullable                transactionID;
@property (nonatomic, strong) BNCCurrency _Nullable             currency;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         revenue;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         shipping;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         tax;
@property (nonatomic, strong) NSString*_Nullable                coupon;
@property (nonatomic, strong) NSString*_Nullable                affiliation;
@property (nonatomic, strong) NSString*_Nullable                eventDescription;
@property (nonatomic, strong) NSString*_Nullable                searchQuery;

@property (nonatomic, assign) BranchEventAdType                 adType;


@property (nonatomic, copy) NSMutableArray<BranchUniversalObject*>*_Nonnull       contentItems;
@property (nonatomic, copy) NSMutableDictionary<NSString*, NSString*> *_Nonnull   customData;

- (NSDictionary*_Nonnull) dictionary;   //!< Returns a dictionary representation of the event.
- (NSString* _Nonnull) description;     //!< Returns a string description of the event.
- (BOOL) isStandardEvent;
+ (NSArray<BranchStandardEvent>*) standardEvents;   //!< All standard events.
@end

#pragma mark - Branch

@interface Branch (BranchEvent)
/**
 Sends the `BranchEvent` to the Branch servers.

 @param event The `BranchEvent` to send.
*/
- (void) logEvent:(BranchEvent*)event;

/**
 Sends the `BranchEvent` to the Branch servers.

 @param event       The `BranchEvent` event to send.
 @param completion  A completion block that is called with success or failure.
*/
- (void) logEvent:(BranchEvent*)event completion:(void (^_Nullable)(NSError*_Nullable error))completion;
@end

#endif

NS_ASSUME_NONNULL_END
