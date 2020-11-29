//
//  TestBedUIUtils.m
//  TestBed-macOSUITests
//
//  Created by Nidhi on 11/3/20.
//  Copyright © 2020 Branch. All rights reserved.
//

#import "TestBedUIUtils.h"

NSURL* _Nullable BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(NSSearchPathDirectory directory) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:directory inDomains:NSUserDomainMask | NSLocalDomainMask];

    for (NSURL *URL in URLs) {
        NSError *error = nil;
        NSURL *branchURL = [[NSURL alloc] initWithString:@"io.branch" relativeToURL:URL];
        BOOL success =
            [fileManager
                createDirectoryAtURL:branchURL
                withIntermediateDirectories:YES
                attributes:nil
                error:&error];
        if (success) {
            return branchURL;
        } else  {
            NSLog(@"[branch.io] Info: CreateBranchURL failed: %@ URL: %@.", error, branchURL);
        }
    }
    return nil;
}

NSURL* _Nonnull BNCURLForBranchDirectory_Unthreaded() {
    NSArray *kSearchDirectories = @[
        @(NSApplicationSupportDirectory),
        @(NSLibraryDirectory),
        @(NSCachesDirectory),
        @(NSDocumentDirectory),
    ];

    for (NSNumber *directory in kSearchDirectories) {
        NSSearchPathDirectory directoryValue = [directory unsignedLongValue];
        NSURL *URL = BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(directoryValue);
        if (URL) return URL;
    }

    // Worst case backup plan:
    NSString *path = [@"~/Library/io.branch" stringByExpandingTildeInPath];
    NSURL *branchURL = [NSURL fileURLWithPath:path isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success =
        [fileManager
            createDirectoryAtURL:branchURL
            withIntermediateDirectories:YES
            attributes:nil
            error:&error];
    if (!success) {
        NSLog(@"[io.branch] Error: Worst case CreateBranchURL error was: %@ URL: %@.", error, branchURL);
    }
    return branchURL;
}

NSURL*_Nonnull BNCURLForBranchDataDirectory() {
    static NSURL *urlForBranchDirectory = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        urlForBranchDirectory = BNCURLForBranchDirectory_Unthreaded();
    });
    return urlForBranchDirectory;
}


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
    NSURL *url = BNCURLForBranchDataDirectory();
    url = [url URLByAppendingPathComponent:@"io.branch.sdk.TestBed-Mac" isDirectory:YES];
    url = [url URLByAppendingPathComponent:@"io.branch.sdk.settings" isDirectory:NO];
        
    NSString *settingsFolder = [NSString stringWithFormat:@"%@" , [url path]];
    
    //Delete all settings files
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingsFolder] == YES) {
        [[NSFileManager defaultManager] removeItemAtPath:settingsFolder error:nil];
    }
    
    NSArray * searchPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString * applicationSupportDirectory = [searchPath objectAtIndex:0];
    settingsFolder = [NSString stringWithFormat:@"%@/io.branch/io.branch.sdk.TestBed-Mac" , applicationSupportDirectory];
    
    //Delete all settings files
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingsFolder] == YES) {
        [[NSFileManager defaultManager] removeItemAtPath:settingsFolder error:nil];
    }
}

@end
