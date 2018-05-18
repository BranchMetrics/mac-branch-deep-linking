/**
 @file          BranchSession.m
 @package       Branch
 @brief         < A brief description of the file function. >

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchSession.h"

@implementation BranchSession

+ (instancetype) sessionWithDictionary:(NSDictionary *)dictionary {
    BranchSession*object = [[BranchSession alloc] init];

    #define BNCWireFormatObjectFromDictionary
    #include "BNCWireFormat.h"

    addString(sessionID,            session_id);
    addBoolean(isFirstSession,      +is_first_session);
    addBoolean(isBranchURL,         +clicked_branch_link);
    addString(developerIdentityForUser, identity);
    addString(deviceFingerprintID,  device_fingerprint_id);
    addURL(url,                     link);
    addString(identityID,           identity_id)

    return object;
}

- (NSDictionary*) dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"

    addString(sessionID,            session_id);
    addBoolean(isFirstSession,      +is_first_session);
    addBoolean(isBranchURL,         +clicked_branch_link);
    addString(developerIdentityForUser, identity);
    addString(deviceFingerprintID,  device_fingerprint_id);
    addURL(url,                     link);
    addString(identityID,           identity_id)

    return dictionary;
}

@end
