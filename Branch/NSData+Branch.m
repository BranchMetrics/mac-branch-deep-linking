/**
 @file          NSData+Branch.m
 @package       Branch
 @brief         NSData additions.

 @author        Edward Smith
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "NSData+Branch.h"

__attribute__((constructor)) void BNCForceNSDataCategoryToLoad() {
    //  Nothing here, but forces linker to load the category.
}

@implementation NSData (Branch)

static inline int16_t nibble(UniChar c) {
    if (c >= '0' && c <= '9')
        return c - '0';
    else
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    else
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    else
        return -1;
}

+ (NSData*) bnc_dataWithHexString:(NSString*)string {
    uint8_t*bytes = NULL;
    NSData*data = nil;
    {
        NSUInteger stringLength = string.length;
        CFStringInlineBuffer stringBuffer;
        CFStringInitInlineBuffer((CFStringRef)string, &stringBuffer, CFRangeMake(0, stringLength));

        UniChar c;
        int16_t n, lastNibble = -1;
        NSUInteger idx = 0;
        uint8_t*p = bytes = malloc(stringLength/2+1);
        while (idx < stringLength) {
            c = CFStringGetCharacterFromInlineBuffer(&stringBuffer, idx++);
            n = nibble(c);
            if (n < 0) continue;
            if (lastNibble < 0)
                lastNibble = n;
            else {
                *p++ = (uint8_t) (uint16_t) (lastNibble << 4 | n);
                lastNibble = -1;
            }
        }
        if (lastNibble >= 0)
            *p++ = (uint8_t) (uint16_t) (lastNibble << 4 | 0);
        data = [NSData dataWithBytesNoCopy:bytes length:p-bytes freeWhenDone:YES];
        bytes = NULL;
    }
exit:
    if (bytes) free(bytes);
    return data;
}

@end
