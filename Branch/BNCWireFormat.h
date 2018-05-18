/**
 @file          BNCWireFormat.h
 @package       Branch-SDK
 @brief         Functions and defines for converting to dictionaries and JSON.

 @author        Edward Smith
 @date          August 17, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BranchHeader.h"

#pragma mark BNCWireFormat

extern NSNumber* BNCWireFormatFromDate(NSDate *date);
extern NSNumber* BNCWireFormatFromBool(BOOL b);
extern NSString* BNCWireFormatFromString(NSString*string);
extern NSDecimalNumber* BNCWireFormatFromDecimal(NSDecimalNumber*decimal);
extern NSNumber* BNCWireFormatFromDouble(double d);
extern NSNumber* BNCWireFormatFromInteger(NSInteger i);
extern NSArray<NSString*>* BNCWireFormatFromStringArray(NSArray<NSString*>* object);
extern NSDictionary* BNCWireFormatFromDictionary(NSDictionary* object);
extern NSString* BNCWireFormatFromURL(NSURL* url);

extern NSDate*   BNCDateFromWireFormat(id object);
extern BOOL      BNCBoolFromWireFormat(id object);
extern NSString* BNCStringFromWireFormat(id object);
extern NSDecimalNumber* BNCDecimalFromWireFormat(id object);
extern double    BNCDoubleFromWireFormat(id object);
extern NSInteger BNCIntegerFromWireFormat(id object);
extern NSMutableArray<NSString*>* BNCStringArrayFromWireFormat(id object);
extern NSMutableDictionary* BNCDictionaryFromWireFormat(id object);
extern NSURL* BNCURLFromWireFormat(id object);

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

/*
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
