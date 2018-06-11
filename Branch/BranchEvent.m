/**
 @file          BranchEvent.m
 @package       Branch-SDK
 @brief         Event actions for logging user events, especially commerce events.

 @author        Edward Smith
 @date          July 24, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchEvent.h"
#import "BranchError.h"
#import "BranchMainClass.h"
#import "BNCLog.h"
#import "BNCNetworkAPIService.h"
#import "BNCDevice.h"
#import "BNCThreads.h"

#pragma mark BranchStandardEvents

// Commerce events

BranchStandardEvent BranchStandardEventAddToCart          = @"ADD_TO_CART";
BranchStandardEvent BranchStandardEventAddToWishlist      = @"ADD_TO_WISHLIST";
BranchStandardEvent BranchStandardEventViewCart           = @"VIEW_CART";
BranchStandardEvent BranchStandardEventInitiatePurchase   = @"INITIATE_PURCHASE";
BranchStandardEvent BranchStandardEventAddPaymentInfo     = @"ADD_PAYMENT_INFO";
BranchStandardEvent BranchStandardEventPurchase           = @"PURCHASE";
BranchStandardEvent BranchStandardEventSpendCredits       = @"SPEND_CREDITS";

// Content Events

BranchStandardEvent BranchStandardEventSearch             = @"SEARCH";
BranchStandardEvent BranchStandardEventViewItem           = @"VIEW_ITEM";
BranchStandardEvent BranchStandardEventViewItems          = @"VIEW_ITEMS";
BranchStandardEvent BranchStandardEventRate               = @"RATE";
BranchStandardEvent BranchStandardEventShare              = @"SHARE";

// User Lifecycle Events

BranchStandardEvent BranchStandardEventCompleteRegistration   = @"COMPLETE_REGISTRATION";
BranchStandardEvent BranchStandardEventCompleteTutorial       = @"COMPLETE_TUTORIAL";
BranchStandardEvent BranchStandardEventAchieveLevel           = @"ACHIEVE_LEVEL";
BranchStandardEvent BranchStandardEventUnlockAchievement      = @"UNLOCK_ACHIEVEMENT";

#pragma mark - BranchEvent

@interface BranchEvent () {
    NSMutableDictionary *_customData;
    NSMutableArray      *_contentItems;
}
@property (nonatomic, strong) NSString*  eventName;
@end

@implementation BranchEvent : NSObject

- (instancetype) initWithName:(NSString *)name {
    self = [super init];
    if (!self) return self;
    _eventName = name;
    return self;
}

+ (instancetype) standardEvent:(BranchStandardEvent)standardEvent {
    return [[BranchEvent alloc] initWithName:standardEvent];
}

+ (instancetype) standardEvent:(BranchStandardEvent)standardEvent
                   contentItem:(BranchUniversalObject*)contentItem {
    BranchEvent *e = [BranchEvent standardEvent:standardEvent];
    if (contentItem) {
        e.contentItems = (NSMutableArray*) @[ contentItem ];
    }
    return e;
}

+ (instancetype) customEventWithName:(NSString*)name {
    return [[BranchEvent alloc] initWithName:name];
}

+ (instancetype) customEventWithName:(NSString*)name
                         contentItem:(BranchUniversalObject*)contentItem {
    BranchEvent *e = [[BranchEvent alloc] initWithName:name];
    if (contentItem) e.contentItems = (NSMutableArray*) @[ contentItem ];
    return e;
}

- (NSMutableDictionary*) customData {
    if (!_customData) _customData = [NSMutableDictionary new];
    return _customData;
}

- (void) setCustomData:(NSMutableDictionary<NSString *,NSString *> *)userInfo {
    _customData = [userInfo mutableCopy];
}

- (NSMutableArray*) contentItems {
    if (!_contentItems) _contentItems = [NSMutableArray new];
    return _contentItems;
}

- (void) setContentItems:(NSMutableArray<BranchUniversalObject *> *)contentItems {
    if ([contentItems isKindOfClass:[BranchUniversalObject class]]) {
        _contentItems = [NSMutableArray arrayWithObject:contentItems];
    } else
    if ([contentItems isKindOfClass:[NSArray class]]) {
        _contentItems = [contentItems mutableCopy];
    }
}

- (NSDictionary*) dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"

    addString(transactionID,    transaction_id);
    addString(currency,         currency);
    addDecimal(revenue,         revenue);
    addDecimal(shipping,        shipping);
    addDecimal(tax,             tax);
    addString(coupon,           coupon);
    addString(affiliation,      affiliation);
    addString(eventDescription, description);
    addString(searchQuery,      search_query)
    addDictionary(customData,   custom_data);
    
    #include "BNCWireFormat.h"

    return dictionary;
}

+ (NSArray<BranchStandardEvent>*) standardEvents {
    return @[
        BranchStandardEventAddToCart,
        BranchStandardEventAddToWishlist,
        BranchStandardEventViewCart,
        BranchStandardEventInitiatePurchase,
        BranchStandardEventAddPaymentInfo,
        BranchStandardEventPurchase,
        BranchStandardEventSpendCredits,
        BranchStandardEventSearch,
        BranchStandardEventViewItem,
        BranchStandardEventViewItems,
        BranchStandardEventRate,
        BranchStandardEventShare,
        BranchStandardEventCompleteRegistration,
        BranchStandardEventCompleteTutorial,
        BranchStandardEventAchieveLevel,
        BranchStandardEventUnlockAchievement,
    ];
}

- (BOOL) isStandardEvent {
    return ([self.class.standardEvents containsObject:self.eventName]);
}

- (NSString*_Nonnull) description {
    return [NSString stringWithFormat:
        @"<%@ 0x%016llx %@ txID: %@ Amt: %@ %@ desc: %@ items: %ld customData: %@>",
        NSStringFromClass(self.class),
        (uint64_t) self,
        self.eventName,
        self.transactionID,
        self.currency,
        self.revenue,
        self.eventDescription,
        (long) self.contentItems.count,
        self.customData
    ];
}

@end

#pragma mark - Branch

@implementation Branch (BranchEvent)

- (void) logEvent:(BranchEvent*)event completion:(void (^_Nullable)(NSError*_Nullable error))completion {
    if (![event.eventName isKindOfClass:[NSString class]] || event.eventName.length == 0) {
        BNCLogError(@"Invalid event type '%@' or empty string.", NSStringFromClass(event.eventName.class));
        NSError*error = [NSError branchErrorWithCode:BNCBadRequestError];
        if (completion) completion(error);
        return;
    }

    if (!self.isStarted) {
        NSError*error = [NSError branchErrorWithCode:BNCInitError];
        if (completion) completion(error);
        return;
    }

    NSMutableDictionary *eventDictionary = [NSMutableDictionary new];
    eventDictionary[@"name"] = event.eventName;

    NSDictionary *propertyDictionary = [event dictionary];
    if (propertyDictionary.count) {
        eventDictionary[@"event_data"] = propertyDictionary;
    }
    eventDictionary[@"custom_data"] = eventDictionary[@"event_data"][@"custom_data"];
    eventDictionary[@"event_data"][@"custom_data"] = nil;

    NSMutableArray *contentItemDictionaries = [NSMutableArray new];
    for (BranchUniversalObject *contentItem in event.contentItems) {
        NSDictionary *dictionary = [contentItem dictionary];
        if (dictionary.count) {
            [contentItemDictionaries addObject:dictionary];
        }
    }

    if (contentItemDictionaries.count) {
        eventDictionary[@"content_items"] = contentItemDictionaries;
    }

    [self.networkAPIService appendV2APIParametersWithDictionary:eventDictionary];
    NSString*apiService = event.isStandardEvent ? @"v2/event/standard" : @"v2/event/custom";

    [self.networkAPIService
        postOperationForAPIServiceName:apiService
        dictionary:eventDictionary
        completion:^ (BNCNetworkAPIOperation*operation) {
            BNCPerformBlockOnMainThreadAsync(^{
                if (completion) completion(operation.error);
            });
        }];
}

@end
