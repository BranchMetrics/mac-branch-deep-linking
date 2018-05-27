/**
 @file          BranchLinkProperties.h
 @package       Branch-SDK
 @brief         Branch link properties: non-content properties that are associated with a link.

 @author        Derrick Staten
 @date          October 2015
 @copyright     Copyright © 2015 Branch. All rights reserved.
*/

#import "BranchLinkProperties.h"

@implementation BranchLinkProperties

- (NSMutableDictionary*)controlParams {
    @synchronized(self) {
        if (!_controlParams) _controlParams = [[NSMutableDictionary alloc] init];
        return _controlParams;
    }
}

+ (instancetype)linkPropertiesWithDictionary:(NSDictionary *)dictionary {
    BranchLinkProperties *object = [[BranchLinkProperties alloc] init];

    #define BNCWireFormatObjectFromDictionary
    #include "BNCWireFormat.h"

    addStringArray(tags, ~tags);
    addString(feature, ~feature);
    addString(alias, ~alias);
    addString(channel, ~channel);
    addString(stage, ~stage);
    addString(campaign, ~campaign);
    addInteger(matchDuration, ~duration);   // TODO: encodes as $match_duration in iOS

    NSMutableDictionary *controlParams = [[NSMutableDictionary alloc] init];
    for (NSString*key in dictionary.allKeys) {
        if ([key hasPrefix:@"$"]) {
            controlParams[key] = dictionary[key];
        }
    }
    object.controlParams = controlParams;
    
    return object;
}

- (NSDictionary*) dictionary {
    NSMutableDictionary*dictionary = [[NSMutableDictionary alloc] init];

    #define BNCWireFormatDictionaryFromSelf
    #include "BNCWireFormat.h"
    
    addStringArray(tags, ~tags);
    addString(feature, ~feature);
    addString(alias, ~alias);
    addString(channel, ~channel);
    addString(stage, ~stage);
    addString(campaign, ~campaign);
    addInteger(matchDuration, ~duration);

    [dictionary addEntriesFromDictionary:self.controlParams];

    return dictionary;
}

- (NSString *)description {
    return [NSString stringWithFormat:
        @"BranchLinkProperties | tags: %@ \n feature: %@ \n alias: %@ \n channel: %@ \n stage: %@ \n"
         " campaign: %@ \n matchDuration: %lu \n controlParams: %@",
            self.tags, self.feature, self.alias, self.channel, self.stage, self.campaign,
            (long)self.matchDuration, self.controlParams];
}

@end
