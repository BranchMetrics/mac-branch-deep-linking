/**
 @file          BranchSession.m
 @package       Branch
 @brief         Attributes of the current Branch session.

 @author        Edward
 @date          2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchSession.h"
#import "BNCLog.h"

@interface BranchSession ()
@property (nonatomic, assign) BOOL matchGuaranteed;
@property (nonatomic, strong) NSDate* clickTimestamp;
@end

@implementation BranchSession

+ (instancetype) sessionWithDictionary:(NSDictionary *)dictionary {
    BranchSession*object = [[BranchSession alloc] init];

    #define BNCWireFormatObjectFromDictionary
    #include "BNCWireFormat.h"

    addString(sessionID,            session_id);
    addString(userIdentityForDeveloper, identity);
    addString(deviceFingerprintID,  device_fingerprint_id);
    addString(identityID,           identity_id);
    addString(linkCreationURL,      link);
    
    NSString*dataString = dictionary[@"data"];
    if (!dataString) dataString = dictionary[@"referring_data"];

    if (dataString) {
        NSData*dataData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        if (dataData) {
            NSError*error = nil;
            object.data = [NSJSONSerialization JSONObjectWithData:dataData options:0 error:&error];
            if (error) BNCLogError(@"Can't decode data: %@", error);
            NSDictionary*dictionary = object.data;
            addBoolean(isFirstSession,      +is_first_session);
            addBoolean(isBranchURL,         +clicked_branch_link);
            addBoolean(matchGuaranteed,     +match_guaranteed);
            addURL(referringURL,            ~referring_link);
            object.clickTimestamp = BNCDateFromWireFormatSeconds(dictionary[@"+click_timestamp"]);
        }
    } else {
        object.data = dictionary;
    }
    return object;
}

#include "BNCWireFormat.h"

- (NSString*) description {
    return [NSString stringWithFormat:
        @"<%@ 0x%p isFirst: %@ isBranchURL: %@ sessionID: %@ referring: %@ identity: %@"
         " buo: %@ link: %@ items data: %@>",
            NSStringFromClass(self.class),
            (void*) self,
            BNCStringFromBool(self.isFirstSession),
            BNCStringFromBool(self.isBranchURL),
            self.sessionID,
            self.referringURL,
            self.identityID,
            self.linkContent,
            self.linkProperties,
            self.data];
}

@end
