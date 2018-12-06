/**
 @file          BranchUniversalObject.h
 @package       Branch
 @brief         A BranchUniversalObject describes the content to which a Branch link points.

 @author        Derrick Staten
 @date          October 2015
 @copyright     Copyright © 2015 Branch. All rights reserved.
*/

#import "BranchHeader.h"
#import "BranchCommerce.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - BranchContentSchema

typedef NSString * const BranchContentSchema NS_STRING_ENUM;

FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceAuction;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceBusiness;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceOther;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceProduct;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceRestaurant;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceService;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelFlight;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelHotel;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelOther;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaGameState;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaMediaImage;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaMediaMixed;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaMediaMusic;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaMediaOther;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaMediaVideo;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaOther;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextArticle;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextBlog;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextOther;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextRecipe;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextReview;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextSearchResults;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextStory;
FOUNDATION_EXPORT BranchContentSchema _Nonnull BranchContentSchemaTextTechnicalDoc;

#pragma mark - BranchCondition

typedef NSString * const BranchCondition NS_STRING_ENUM;

FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionOther;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionNew;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionExcellent;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionGood;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionFair;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionPoor;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionUsed;
FOUNDATION_EXPORT BranchCondition _Nonnull BranchConditionRefurbished;

#pragma mark - BranchContentMetadata

/**
 BranchContentMetadata describes properties in your Branch Universal Object.
 */
@interface BranchContentMetadata : NSObject

@property (nonatomic, strong, nullable) BranchContentSchema contentSchema;
@property (nonatomic, assign)           double          quantity;
@property (nonatomic, strong, nullable) NSDecimalNumber *price;
@property (nonatomic, strong, nullable) BNCCurrency     currency;
@property (nonatomic, strong, nullable) NSString        *sku;
@property (nonatomic, strong, nullable) NSString        *productName;
@property (nonatomic, strong, nullable) NSString        *productBrand;
@property (nonatomic, strong, nullable) BNCProductCategory productCategory;
@property (nonatomic, strong, nullable) NSString        *productVariant;
@property (nonatomic, strong, nullable) BranchCondition condition;
@property (nonatomic, assign)           double          ratingAverage;
@property (nonatomic, assign)           NSInteger       ratingCount;
@property (nonatomic, assign)           double          ratingMax;
@property (nonatomic, assign)           double          rating;
@property (nonatomic, strong, nullable) NSString        *addressStreet;
@property (nonatomic, strong, nullable) NSString        *addressCity;
@property (nonatomic, strong, nullable) NSString        *addressRegion;
@property (nonatomic, strong, nullable) NSString        *addressCountry;
@property (nonatomic, strong, nullable) NSString        *addressPostalCode;
@property (nonatomic, assign)           double          latitude;
@property (nonatomic, assign)           double          longitude;
@property (nonatomic, copy, nonnull)    NSMutableArray<NSString*> *imageCaptions;
@property (nonatomic, copy, nonnull)    NSMutableDictionary<NSString*, NSString*> *customMetadata;

- (NSDictionary*_Nonnull) dictionary;
+ (BranchContentMetadata*_Nonnull) contentMetadataWithDictionary:(NSDictionary*_Nullable)dictionary;

@end

#pragma mark - BranchUniversalObject

/**
 Use a BranchUniversalObject to describe content in your app for deep links, content analytics and indexing.

 The properties object describes your content in a standard way so that it can be deep linked, shared, or
 indexed on spotlight for instance. You can set all the properties associated with the object and then call
 action methods on it to create a link or index the content on Spotlight.
 */
@interface BranchUniversalObject : NSObject

- (nonnull instancetype)initWithCanonicalIdentifier:(nonnull NSString *)canonicalIdentifier;
- (nonnull instancetype)initWithTitle:(nonnull NSString *)title;

+ (BranchUniversalObject*_Nonnull) objectWithDictionary:(NSDictionary*_Nullable)dictionary;
- (NSMutableDictionary*_Nonnull) dictionary;

- (NSString*_Nonnull) description;

/** An identifier that canonically identifies this content item, like an ISBN number or SKU. */
@property (nonatomic, strong, nullable) NSString *canonicalIdentifier;

/** A web URL that canonically locates this content item */
@property (nonatomic, strong, nullable) NSString *canonicalUrl;

/** The title or name of this content item. */
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *contentDescription;

/** A URL to an image that should be associated with the item */
@property (nonatomic, strong, nullable) NSString *imageUrl;

/** An array of keywords that describe the item. */
@property (nonatomic, strong, nullable) NSArray<NSString*> *keywords;

@property (nonatomic, strong, nullable) NSDate   *creationDate;

/** The date that a link to this item is no longer relevant */
@property (nonatomic, strong, nullable) NSDate   *expirationDate;

/** Index the content on Spotlight. */
@property (nonatomic, assign)           BOOL      locallyIndex;

/** Index on Google, Branch, etc. */
@property (nonatomic, assign)           BOOL      publiclyIndex;

/** Properties that further describe your content. */
@property (nonatomic, strong, nonnull) BranchContentMetadata *contentMetadata;

@end

NS_ASSUME_NONNULL_END

