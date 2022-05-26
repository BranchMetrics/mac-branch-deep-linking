/**
 @file          BranchUniversalObject.m
 @package       Branch
 @brief         A BranchUniversalObject describes the content to which a Branch link points.

 @author        Derrick Staten
 @date          October 2015
 @copyright     Copyright © 2015 Branch. All rights reserved.
*/

#import "BranchUniversalObject.h"
#import "BranchError.h"

#pragma mark BranchContentSchema

BranchContentSchema _Nonnull BranchContentSchemaCommerceAuction     = @"COMMERCE_AUCTION";
BranchContentSchema _Nonnull BranchContentSchemaCommerceBusiness    = @"COMMERCE_BUSINESS";
BranchContentSchema _Nonnull BranchContentSchemaCommerceOther       = @"COMMERCE_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaCommerceProduct     = @"COMMERCE_PRODUCT";
BranchContentSchema _Nonnull BranchContentSchemaCommerceRestaurant  = @"COMMERCE_RESTAURANT";
BranchContentSchema _Nonnull BranchContentSchemaCommerceService     = @"COMMERCE_SERVICE";
BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelFlight= @"COMMERCE_TRAVEL_FLIGHT";
BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelHotel = @"COMMERCE_TRAVEL_HOTEL";
BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelOther = @"COMMERCE_TRAVEL_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaGameState           = @"GAME_STATE";
BranchContentSchema _Nonnull BranchContentSchemaMediaImage          = @"MEDIA_IMAGE";
BranchContentSchema _Nonnull BranchContentSchemaMediaMixed          = @"MEDIA_MIXED";
BranchContentSchema _Nonnull BranchContentSchemaMediaMusic          = @"MEDIA_MUSIC";
BranchContentSchema _Nonnull BranchContentSchemaMediaOther          = @"MEDIA_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaMediaVideo          = @"MEDIA_VIDEO";
BranchContentSchema _Nonnull BranchContentSchemaOther               = @"OTHER";
BranchContentSchema _Nonnull BranchContentSchemaTextArticle         = @"TEXT_ARTICLE";
BranchContentSchema _Nonnull BranchContentSchemaTextBlog            = @"TEXT_BLOG";
BranchContentSchema _Nonnull BranchContentSchemaTextOther           = @"TEXT_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaTextRecipe          = @"TEXT_RECIPE";
BranchContentSchema _Nonnull BranchContentSchemaTextReview          = @"TEXT_REVIEW";
BranchContentSchema _Nonnull BranchContentSchemaTextSearchResults   = @"TEXT_SEARCH_RESULTS";
BranchContentSchema _Nonnull BranchContentSchemaTextStory           = @"TEXT_STORY";
BranchContentSchema _Nonnull BranchContentSchemaTextTechnicalDoc    = @"TEXT_TECHNICAL_DOC";

#pragma mark - BranchCondition

BranchCondition _Nonnull BranchConditionOther         = @"OTHER";
BranchCondition _Nonnull BranchConditionExcellent     = @"EXCELLENT";
BranchCondition _Nonnull BranchConditionNew           = @"NEW";
BranchCondition _Nonnull BranchConditionGood          = @"GOOD";
BranchCondition _Nonnull BranchConditionFair          = @"FAIR";
BranchCondition _Nonnull BranchConditionPoor          = @"POOR";
BranchCondition _Nonnull BranchConditionUsed          = @"USED";
BranchCondition _Nonnull BranchConditionRefurbished   = @"REFURBISHED";

#pragma mark - BranchContentMetadata

@interface BranchContentMetadata () {
    NSMutableArray      *_imageCaptions;
    NSMutableDictionary *_customMetadata;
}
@end

@implementation BranchContentMetadata

- (NSDictionary*_Nonnull) dictionary {
    NSMutableDictionary*dictionary = [NSMutableDictionary new];

    for (NSString *key in self.customMetadata.keyEnumerator) {
        NSString *value = self.customMetadata[key];
        dictionary[key] = value;
    }

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"

    addString(contentSchema,    $content_schema);
    addDouble(quantity,         $quantity);
    addDecimal(price,           $price);
    addString(currency,         $currency);
    addString(sku,              $sku);
    addString(productName,      $product_name);
    addString(productBrand,     $product_brand);
    addString(productCategory,  $product_category);
    addString(productVariant,   $product_variant);
    addString(condition,        $condition);
    addDouble(ratingAverage,    $rating_average);
    addInteger(ratingCount,     $rating_count);
    addDouble(ratingMax,        $rating_max);
    addDouble(rating,           $rating);
    addString(addressStreet,    $address_street);
    addString(addressCity,      $address_city);
    addString(addressRegion,    $address_region);
    addString(addressCountry,   $address_country);
    addString(addressPostalCode,$address_postal_code);
    addDouble(latitude,         $latitude);
    addDouble(longitude,        $longitude);
    addStringArray(imageCaptions,$image_captions);

    #include "BNCWireFormat.h"

    return dictionary;
}

+ (BranchContentMetadata*_Nonnull) contentMetadataWithDictionary:(NSDictionary*_Nullable)dictionary {
    BranchContentMetadata*object = [BranchContentMetadata new];
    if (!dictionary) return object;

    #define BNCWireFormatObjectFromDictionary
    #include "BNCWireFormat.h"

    addString(contentSchema,    $content_schema);
    addDouble(quantity,         $quantity);
    addDecimal(price,           $price);
    addString(currency,         $currency);
    addString(sku,              $sku);
    addString(productName,      $product_name);
    addString(productBrand,     $product_brand);
    addString(productCategory,  $product_category);
    addString(productVariant,   $product_variant);
    addString(condition,        $condition);
    addDouble(ratingAverage,    $rating_average);
    addInteger(ratingCount,     $rating_count);
    addDouble(ratingMax,        $rating_max);
    addDouble(rating,           $rating);
    addString(addressStreet,    $address_street);
    addString(addressCity,      $address_city);
    addString(addressRegion,    $address_region);
    addString(addressCountry,   $address_country);
    addString(addressPostalCode,$address_postal_code);
    addDouble(latitude,         $latitude);
    addDouble(longitude,        $longitude);
    addStringArray(imageCaptions,$image_captions);

    #include "BNCWireFormat.h"

    return object;
}

- (NSMutableDictionary*) customMetadata {
    if (!_customMetadata) _customMetadata = [NSMutableDictionary new];
    return _customMetadata;
}

- (void) setCustomMetadata:(NSMutableDictionary*)dictionary {
    _customMetadata = [dictionary mutableCopy];
}

- (void) setImageCaptions:(NSMutableArray<NSString *> *)imageCaptions {
    _imageCaptions = [imageCaptions mutableCopy];
}

- (NSMutableArray<NSString *> *) imageCaptions {
    if (!_imageCaptions) _imageCaptions = [NSMutableArray new];
    return _imageCaptions;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ 0x%016llx schema: %@ userData: %ld items>",
        NSStringFromClass(self.class),
        (uint64_t) self,
        _contentSchema,
        (long) _customMetadata.count
    ];
}

@end

#pragma mark - BranchUniversalObject

@implementation BranchUniversalObject

- (instancetype)initWithCanonicalIdentifier:(NSString *)canonicalIdentifier {
    if ((self = [super init])) {
        self.canonicalIdentifier = canonicalIdentifier;
        self.creationDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    if ((self = [super init])) {
        self.title = title;
        self.creationDate = [NSDate date];
    }
    return self;
}

#pragma mark - Setters / Getters / Standard Methods

- (BranchContentMetadata*) contentMetadata {
    if (!_contentMetadata) _contentMetadata = [BranchContentMetadata new];
    return _contentMetadata;
}

- (NSString *)description {
    return [NSString stringWithFormat:
        @"<%@ 0x%016llx"
         "\n canonicalIdentifier: %@"
         "\n title: %@"
         "\n contentDescription: %@"
         "\n imageUrl: %@"
         "\n metadata: %@"
         "\n type: %@"
         "\n locallyIndex: %d"
         "\n publiclyIndex: %d"
         "\n keywords: %@"
         "\n expirationDate: %@"
         "\n>",
         NSStringFromClass(self.class), (uint64_t) self,
        self.canonicalIdentifier,
        self.title,
        self.contentDescription,
        self.imageUrl,
        self.contentMetadata.customMetadata,
        self.contentMetadata.contentSchema,
        self.locallyIndex,
        self.publiclyIndex,
        self.keywords,
        self.expirationDate];
}

#pragma mark - Dictionary Methods

+ (BranchUniversalObject*_Nonnull) objectWithDictionary:(NSDictionary*_Nullable)dictionary {
    BranchUniversalObject *object = [BranchUniversalObject new];

    #define BNCWireFormatObjectFromDictionary
    #include "BNCWireFormat.h"

    addString(canonicalIdentifier,          $canonical_identifier);
    addString(canonicalUrl,                 $canonical_url);
    addDate(creationDate,                   $creation_timestamp);
    addDate(expirationDate,                 $exp_date);
    addStringArray(keywords,                $keywords);
    addBoolean(locallyIndex,                $locally_indexable);
    addString(contentDescription,           $og_description);
    addString(imageUrl,                     $og_image_url);
    addString(title,                        $og_title);
    addBoolean(publiclyIndex,               $publicly_indexable);

    #include "BNCWireFormat.h"

    BranchContentMetadata *data = [BranchContentMetadata contentMetadataWithDictionary:dictionary];
    object.contentMetadata = data;

    NSSet *fieldsAdded = [NSSet setWithArray:@[
        @"$canonical_identifier",
        @"$canonical_url",
        @"$creation_timestamp",
        @"$exp_date",
        @"$keywords",
        @"$locally_indexable",
        @"$og_description",
        @"$og_image_url",
        @"$og_title",
        @"$publicly_indexable",
        @"$content_schema",
        @"$quantity",
        @"$price",
        @"$currency",
        @"$sku",
        @"$product_name",
        @"$product_brand",
        @"$product_category",
        @"$product_variant",
        @"$condition",
        @"$rating_average",
        @"$rating_count",
        @"$rating_max",
        @"$rating",
        @"$address_street",
        @"$address_city",
        @"$address_region",
        @"$address_country",
        @"$address_postal_code",
        @"$latitude",
        @"$longitude",
        @"$image_captions",
        @"$custom_fields",
    ]];

    // Add any extra fields to the content object.contentMetadata.customMetadata

    for (NSString* key in dictionary.keyEnumerator) {
        if (![fieldsAdded containsObject:key]) {
            object.contentMetadata.customMetadata[key] = dictionary[key];
        }
    }

    return object;
}

- (NSDictionary*_Nonnull) dictionary {

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    NSDictionary *contentDictionary = [self.contentMetadata dictionary];
    if (contentDictionary.count) [dictionary addEntriesFromDictionary:contentDictionary];

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"

    addString(canonicalIdentifier,          $canonical_identifier);
    addString(canonicalUrl,                 $canonical_url);
    addDate(creationDate,                   $creation_timestamp);
    addDate(expirationDate,                 $exp_date);
    addStringArray(keywords,                $keywords);
    addBoolean(locallyIndex,                $locally_indexable);
    addString(contentDescription,           $og_description);
    addString(imageUrl,                     $og_image_url);
    addString(title,                        $og_title);
    addBoolean(publiclyIndex,               $publicly_indexable);

    #include "BNCWireFormat.h"

    return dictionary;
}

@end
