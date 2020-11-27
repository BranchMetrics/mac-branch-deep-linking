//
//  TestBedUIUtils.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUIUtils.h"

@implementation TestBedUIUtils

+ (NSDictionary *) dictionaryFromString:(NSString *)APIDataString {
    
    NSRange startRange = [APIDataString rangeOfString:@"{"];
    
    NSMutableString *jsonPartOfAPIDataString = [[APIDataString stringByReplacingCharactersInRange:NSMakeRange(0, startRange.location) withString:@""] mutableCopy];
    
    NSRange endRange = [jsonPartOfAPIDataString rangeOfString:@"}" options:NSBackwardsSearch];
 
    jsonPartOfAPIDataString = [[jsonPartOfAPIDataString stringByReplacingCharactersInRange:(NSRange)NSMakeRange(endRange.location+1, (jsonPartOfAPIDataString.length - endRange.location -1) ) withString:@""] mutableCopy];
    NSError *error;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:[jsonPartOfAPIDataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"%@", [error debugDescription]);
    }
    return  jsonDictionary;
}

+ (void) deleteSettingsFiles
{
    //  Get Application Support Folder path
    NSArray * searchPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString * applicationSupportDirectory = [searchPath objectAtIndex:0];
    NSString *settingsFolder = [NSString stringWithFormat:@"%@/io.branch/io.branch.sdk.TestBed-Mac" , applicationSupportDirectory];
    
    //Delete all settings files
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingsFolder] == YES)
    {
        [[NSFileManager defaultManager] removeItemAtPath:settingsFolder error:nil];
    }
}

@end
