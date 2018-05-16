/**
 @file          BranchMain.h
 @package       Branch-SDK
 @brief         The main Branch class.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BranchConfiguration : NSObject
@property (nonatomic, strong) NSString*_Nullable key;
@property (nonatomic, copy) void (^_Nullable linkCallback)(void);
@end

@interface Branch : NSObject
+ (instancetype) sharedInstance;
+ (NSString*)bundleIdentifier;
+ (NSString*)kitDisplayVersion;

- (void) startWithConfiguration:(BranchConfiguration*)configuration;
- (void) openURLs:(NSArray<NSURL*>*)urls;

//@property (nonatomic, weak) id<BranchDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
