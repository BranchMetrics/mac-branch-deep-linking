/**
 @file          BNCWireFormat.m
 @package       Branch
 @brief         Functions and defines for converting to dictionaries and JSON.

 @author        Edward Smith
 @date          August 17, 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCWireFormat.h"

#pragma mark BNCWireFormat

NSDate* BNCDateFromWireFormat(id object) {
    NSDate *date = nil;
    if ([object respondsToSelector:@selector(doubleValue)]) {
        NSTimeInterval t = [object doubleValue];
        date = [NSDate dateWithTimeIntervalSince1970:t/1000.0];
    }
    return date;
}

NSNumber* BNCWireFormatFromDate(NSDate *date) {
    NSNumber *number = nil;
    NSTimeInterval t = [date timeIntervalSince1970];
    if (date && t != 0.0 ) {
        number = [NSNumber numberWithLongLong:(long long)(t*1000.0)];
    }
    return number;
}

NSNumber* BNCWireFormatFromBool(BOOL b) {
    return (b) ? (__bridge NSNumber*) kCFBooleanTrue : nil;
}

BOOL BNCBoolFromWireFormat(id object) {
    if (object && [object respondsToSelector:@selector(boolValue)])
        return [object boolValue];
    return NO;
}

NSNumber* BNCWireFormatFromInteger(NSInteger i) {
    return (i == 0) ? nil : [NSNumber numberWithInteger:i];
}

NSInteger BNCIntegerFromWireFormat(id object) {
    if ([object respondsToSelector:@selector(integerValue)])
        return [object integerValue];
    return 0;
}

NSString* BNCStringFromWireFormat(id object) {
    NSString *string = nil;
    if ([object isKindOfClass:NSString.class])
        string = object;
    else
    if ([object respondsToSelector:@selector(stringValue)])
        string = [object stringValue];
    else
    if ([object respondsToSelector:@selector(description)])
        string = [object description];
    else
        return nil;
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return string;
}

NSString* BNCWireFormatFromString(NSString *string) {
    if (string.length > 0) return string;
    return nil;
}

NSDecimalNumber* BNCDecimalFromWireFormat(id object) {
    NSString *string = BNCStringFromWireFormat(object);
    if (string) return [NSDecimalNumber decimalNumberWithString:string];
    return nil;
}

NSDecimalNumber* BNCWireFormatFromDecimal(NSDecimalNumber* decimal) {
    if (decimal && [decimal compare:[NSDecimalNumber zero]] != NSOrderedSame) return decimal;
    return nil;
}

double BNCDoubleFromWireFormat(id object) {
    if ([object respondsToSelector:@selector(doubleValue)]) return [object doubleValue];
    return 0.0;
}

NSNumber* BNCWireFormatFromDouble(double d) {
    if (d != 0.0) return [NSNumber numberWithDouble:d];
    return nil;
}

NSMutableArray<NSString*>* BNCStringArrayFromWireFormat(id object) {
    NSMutableArray*mutableArray = [[NSMutableArray alloc] init];
    if ([object isKindOfClass:NSArray.class]) {
        for (NSString*string in object) {
            NSString *safeString = BNCStringFromWireFormat(string);
            if (safeString) [mutableArray addObject:safeString];
        }
    }
    return mutableArray;
}

NSArray<NSString*>* BNCWireFormatFromStringArray(NSArray<NSString*>* array) {
    if (array.count > 0) return array;
    return nil;
}

NSDictionary* BNCWireFormatFromDictionary(NSDictionary*dictionary) {
    if (dictionary.count > 0) return dictionary;
    return nil;
}

NSMutableDictionary* BNCDictionaryFromWireFormat(id object) {
    if ([object isKindOfClass:NSDictionary.class])
        return [object mutableCopy];
    else
    if ([object isKindOfClass:NSString.class]) {
        NSData*data = [object dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) return nil;
        NSError*error = nil;
        NSMutableDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data
            options:NSJSONReadingMutableContainers error:&error];
        if (!error && [dictionary isKindOfClass:NSMutableDictionary.class]) return dictionary;
    }
    return nil;
}

NSString* BNCWireFormatFromURL(NSURL* url) {
    NSString*string = [url absoluteString];
    if (string.length) return string;
    return nil;
}

NSURL* BNCURLFromWireFormat(id object) {
    if ([object isKindOfClass:NSURL.class])
        return object;
    else
    if ([object isKindOfClass:NSString.class])
        return [NSURL URLWithString:object];
    return nil;
}

NSString*const BNCStringFromBool(BOOL b) {
    return (b) ? @"true" : @"false";
}
