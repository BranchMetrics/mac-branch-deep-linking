/**
 @file          BNCWireFormat.h
 @package       Branch
 @brief         Functions and defines for converting to dictionaries and JSON.

 @author        Edward Smith
 @date          August 17, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark BNCWireFormat

FOUNDATION_EXPORT NSNumber*_Nullable BNCWireFormatFromDate(NSDate *date);
FOUNDATION_EXPORT NSNumber*_Nullable BNCWireFormatFromBool(BOOL b);
FOUNDATION_EXPORT NSString*_Nullable BNCWireFormatFromString(NSString*string);
FOUNDATION_EXPORT NSDecimalNumber*_Nullable BNCWireFormatFromDecimal(NSDecimalNumber*decimal);
FOUNDATION_EXPORT NSNumber*_Nullable BNCWireFormatFromDouble(double d);
FOUNDATION_EXPORT NSNumber*_Nullable BNCWireFormatFromInteger(NSInteger i);
FOUNDATION_EXPORT NSArray<NSString*>*_Nullable BNCWireFormatFromStringArray(NSArray<NSString*>* object);
FOUNDATION_EXPORT NSDictionary*_Nullable BNCWireFormatFromDictionary(NSDictionary* object);
FOUNDATION_EXPORT NSString*_Nullable BNCWireFormatFromURL(NSURL* url);

FOUNDATION_EXPORT NSDate*_Nullable   BNCDateFromWireFormat(id object);
FOUNDATION_EXPORT NSDate*_Nullable   BNCDateFromWireFormatSeconds(id object);
FOUNDATION_EXPORT BOOL               BNCBoolFromWireFormat(id object);
FOUNDATION_EXPORT NSString*_Nullable BNCStringFromWireFormat(id object);
FOUNDATION_EXPORT NSDecimalNumber*_Nullable BNCDecimalFromWireFormat(id object);
FOUNDATION_EXPORT double             BNCDoubleFromWireFormat(id object);
FOUNDATION_EXPORT NSInteger          BNCIntegerFromWireFormat(id object);
FOUNDATION_EXPORT NSMutableArray<NSString*>*_Nullable BNCStringArrayFromWireFormat(id object);
FOUNDATION_EXPORT NSMutableDictionary*_Nullable BNCDictionaryFromWireFormat(id object);
FOUNDATION_EXPORT NSURL*_Nullable    BNCURLFromWireFormat(id object);

FOUNDATION_EXPORT NSString*const     BNCStringFromBool(BOOL b);

#undef addString
#undef addDate
#undef addDouble
#undef addBoolean
#undef addDecimal
#undef addNumber
#undef addInteger
#undef addStringifiedDictionary
#undef addStringArray
#undef addDictionary
#undef addURL

/**
 @discussion
    TODO: Write discusssion.

    #define BNCWireFormatObjectFromDictionary
    #define BNCWireFormatDictionaryFromSelf
*/

#if defined(BNCWireFormatObjectFromDictionary) && defined(BNCWireFormatDictionaryFromSelf)

    #error Can't define both BNCWireFormatObjectFromDictionary and BNCWireFormatDictionaryFromSelf

#elif defined(BNCWireFormatObjectFromDictionary) // ----------------------------------------------

    #define addString(field, name) \
        { object.field = BNCStringFromWireFormat(dictionary[@#name]); }

    #define addDate(field, name) \
        { object.field = BNCDateFromWireFormat(dictionary[@#name]); }

    #define addDouble(field, name) \
        { object.field = BNCDoubleFromWireFormat(dictionary[@#name]); }

    #define addBoolean(field, name) \
        { object.field = BNCBoolFromWireFormat(dictionary[@#name]); }

    #define addDecimal(field, name) \
        { object.field = BNCDecimalFromWireFormat(dictionary[@#name]); }

    #define addNumber(field, name) \
        { object.field = BNCNumberFromWireFormat(dictionary[@#name]); }

    #define addInteger(field, name) \
        { object.field = BNCIntegerFromWireFormat(dictionary[@#name]); }

    #define addStringifiedDictionary(field, name) \
        { object.field = BNCDictionayFromStringifiedWireFormat(dictionary[@#name]); }

    #define addStringArray(field, name) \
        { object.field = BNCStringArrayFromWireFormat(dictionary[@#name]); }

    #define addDictionary(field, name) \
        { object.field = BNCDictionayFromWireFormat(dictionary[@#name]); }

    #define addURL(field, name) \
        { object.field = BNCURLFromWireFormat(dictionary[@#name]); }

    #undef BNCWireFormatObjectFromDictionary

#elif defined(BNCWireFormatDictionaryFromSelf) // ----------------------------------------------

    #define addString(field, name) \
        { dictionary[@#name] = BNCWireFormatFromString(self.field); }

    #define addDate(field, name) \
        { dictionary[@#name] = BNCWireFormatFromDate(self.field); }

    #define addDouble(field, name) \
        { dictionary[@#name] = BNCWireFormatFromDouble(self.field); }

    #define addBoolean(field, name) \
        { dictionary[@#name] = BNCWireFormatFromBool(self.field); }

    #define addDecimal(field, name) \
        { dictionary[@#name] = BNCWireFormatFromDecimal(self.field); }

    #define addNumber(field, name) \
        { dictionary[@#name] = BNCWireFormatFromNumber(self.field); }

    #define addInteger(field, name) \
        { dictionary[@#name] = BNCWireFormatFromInteger(self.field); }

    #define addStringifiedDictionary(field, name) \
        { dictionary[@#name] = BNCStringifiedWireFormatFromDictionary(self.field); }

    #define addStringArray(field, name) \
        { dictionary[@#name] = BNCWireFormatFromStringArray(self.field); }

    #define addDictionary(field, name) \
        { dictionary[@#name] = BNCWireFormatFromDictionary(self.field); }

    #define addURL(field, name) \
        { dictionary[@#name] = BNCWireFormatFromURL(self.field); }

    #undef BNCWireFormatDictionaryFromSelf
    
#endif

NS_ASSUME_NONNULL_END
