/**
 @file          BNCURLBlackList.m
 @package       Branch
 @brief         Manages a list of URLs that we should ignore.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCURLBlackList.h"
#import "Branch.h"
#import "BranchMainClass+Private.h"

@interface BNCURLBlackList () {
    NSArray<NSString*>*_blackList;
}
@property (strong) NSArray<NSRegularExpression*> *blackListRegex;
@property (strong) id<BNCNetworkServiceProtocol> networkService;
@property (assign) BOOL hasRefreshedBlackListFromServer;
@property (strong) NSError *error;
@property (strong) NSURL *blackListJSONURL;
@end

@implementation BNCURLBlackList

- (instancetype) init {
    self = [self initWithBlackList:@[] version:0];
    return self;
}

- (instancetype) initWithBlackList:(NSArray<NSString*>*)blacklist_ version:(NSInteger)version_ {
    self = [super init];
    if (!self) return self;

    if (blacklist_.count != 0) {
        self.blackList = blacklist_;
        self.blackListVersion = version_;
    } else {
        self.blackList = @[
            @"^fb\\d+:",
            @"^li\\d+:",
            @"^pdk\\d+:",
            @"^twitterkit-.*:",
            @"^com\\.googleusercontent\\.apps\\.\\d+-.*:\\/oauth",
            @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b",
            @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b",
        ];
        self.blackListVersion = -1; // First time always refresh the list version, version 0.
    }

    return self;
}

- (void) dealloc {
    [self cancelAllOperations];
    self.networkService = nil;
}

- (void) cancelAllOperations {
    if ([self.networkService respondsToSelector:@selector(cancelAllOperations)]) {
        [self.networkService cancelAllOperations];
    }
}

- (void) setBlackList:(NSArray<NSString *> *)blackList_ {
    @synchronized (self) {
        _blackList = (blackList_) ?: @[];
        NSError*error = nil;
        _blackListRegex = [self.class compileRegexArray:_blackList error:&error];
        _error = error;
    }
}

- (NSArray<NSString*>*) blackList {
    @synchronized (self) {
        return _blackList;
    }
}

+ (NSArray<NSRegularExpression*>*) compileRegexArray:(NSArray<NSString*>*)blacklist
                                               error:(NSError*_Nullable __autoreleasing *_Nullable)error_ {
    if (error_) *error_ = nil;
    NSMutableArray *array = [NSMutableArray new];
    for (NSString *pattern in blacklist) {
        NSError *error = nil;
        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:pattern
                options: NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnicodeWordBoundaries
                error:&error];
        if (error || !regex) {
            BNCLogError(@"Invalid regular expression '%@': %@.", pattern, error);
            if (error_ && !*error_) *error_ = error;
        } else {
            [array addObject:regex];
        }
    }
    return array;
}

- (NSString*_Nullable) blackListPatternMatchingURL:(NSURL*_Nullable)url {
    NSString *urlString = url.absoluteString;
    if (urlString == nil || urlString.length <= 0) return nil;
    NSRange range = NSMakeRange(0, urlString.length);

    for (NSRegularExpression* regex in self.blackListRegex) {
        NSUInteger matches = [regex numberOfMatchesInString:urlString options:0 range:range];
        if (matches > 0) return regex.pattern;
    }

    return nil;
}

- (BOOL) isBlackListedURL:(NSURL *)url {
    return ([self blackListPatternMatchingURL:url]) ? YES : NO;
}

- (void) refreshBlackListFromServerWithBranch:(Branch*)branch
        completion:(void (^_Nullable) (BNCURLBlackList*blackList, NSError*_Nullable))completion {
    @synchronized(self) {
        if (self.hasRefreshedBlackListFromServer) {
            if (completion) completion(self, self.error);
            return;
        }
        self.hasRefreshedBlackListFromServer = YES;

        self.error = nil;
        NSString *urlString = [self.blackListJSONURL absoluteString];
        if (!urlString) {
            urlString = [NSString stringWithFormat:@"https://cdn.branch.io/sdk/uriskiplist_v%ld.json",
                (long) self.blackListVersion+1];
        }
        NSMutableURLRequest *request =
            [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                timeoutInterval:30.0];

        self.networkService = [branch.configuration.networkServiceClass new];
        id<BNCNetworkOperationProtocol> operation =
            [self.networkService networkOperationWithURLRequest:request completion:
                ^(id<BNCNetworkOperationProtocol> operation) {
                    [self processServerOperation:operation];
                    if (completion) completion(self, self.error);
                    [self cancelAllOperations];
                    self.networkService = nil;
                }
            ];
        [operation start];
    }
}

- (void) processServerOperation:(id<BNCNetworkOperationProtocol>)operation {
    NSError *error = nil;
    NSString *responseString = nil;
    if (operation.responseData)
        responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
    if (operation.HTTPStatusCode == 404) {
        BNCLogDebugSDK(@"No new BlackList refresh found.");
    } else {
        BNCLogDebugSDK(@"BlackList refresh result. Error: %@ status: %ld body:\n%@.",
            operation.error, (long) operation.HTTPStatusCode, responseString);
    }
    if (operation.error || operation.responseData == nil || operation.HTTPStatusCode != 200) {
        self.error = operation.error;
        return;
    }

    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:operation.responseData
            options:0
            error:&error];
    if (error) {
        self.error = error;
        BNCLogError(@"Can't parse JSON: %@.", error);
        return;
    }

    NSArray *blackListURLs = dictionary[@"uri_skip_list"];
    if (![blackListURLs isKindOfClass:NSArray.class]) return;

    NSNumber *blackListVersion = dictionary[@"version"];
    if (![blackListVersion isKindOfClass:NSNumber.class]) return;

    self.blackList = blackListURLs;
    self.blackListVersion = [blackListVersion longValue];
}

@end
