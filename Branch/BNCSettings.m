/**
 @file          BNCSettings.m
 @package       Branch-SDK
 @brief         Branch SDK persistent settings.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCSettings.h"
#import "BNCEncoder.h"
#import "BNCThreads.h"
#import "BNCLog.h"
#import "BNCPersistence.h"
@class BNCSettingsProxy;

@interface BNCSettings () {
    @public
    dispatch_queue_t  _saveQueue;
    dispatch_source_t _saveTimer;
    __weak BNCSettingsProxy* _proxy;

    NSMutableDictionary<NSString*, NSString*>* _requestMetadataDictionary;
    NSMutableDictionary<NSString*, NSString*>* _instrumentationDictionary;
}
@end

@interface BNCSettingsProxy : NSProxy
@property (atomic, strong) BNCSettings*settings;
@end

@implementation BNCSettingsProxy

- (id) initWithSettings:(BNCSettings*)settings {
    self.settings = settings;
    settings->_proxy = self;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation setTarget:self.settings];
    [invocation invoke];
    NSString* selectorName = NSStringFromSelector(invocation.selector);
    if ([selectorName hasPrefix:@"set"] &&
        ![selectorName isEqualToString:@"setNeedsSave"]) {
        [self.settings setNeedsSave];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector_ {
    return [self.settings methodSignatureForSelector:selector_];
}

@end

#pragma mark - BNCSettings

@implementation BNCSettings

+ (instancetype) sharedInstance {
    static BNCSettings*sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        sharedInstance = [self loadSettings];
    });
    return sharedInstance;
}

+ (instancetype) loadSettings {
    BNCSettings* settings = nil;
    NSData*data = [BNCPersistence loadDataNamed:@"io.branch.sdk.settings"];
    if (data) settings = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([settings isKindOfClass:BNCSettingsProxy.class]) {
    }
    else if ([settings isKindOfClass:BNCSettings.class])
        settings = (BNCSettings*) settings->_proxy;
    else
        settings = [[BNCSettings alloc] init];
    return settings;
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    BNCSettingsProxy*proxy = [[BNCSettingsProxy alloc] initWithSettings:self];
    return (BNCSettings*) proxy;
}

+ (NSArray<NSString*>*) ignoreMembers {
    return @[@"_saveQueue", @"_saveTimer", @"_proxy", @"_settingsSavedBlock"];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [self init];
    BNCSettings*settings = ((BNCSettingsProxy*)self).settings;
    [BNCEncoder decodeInstance:settings withCoder:aDecoder ignoring:settings.class.ignoreMembers];
    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    @synchronized (self) {
        [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:self.class.ignoreMembers];
    }
}

- (void) setNeedsSave {
    @synchronized (self) {
        if (_saveTimer) return;

        NSTimeInterval kSaveTime = 1.0; // TODO: shorten

        if (!_saveQueue)
            _saveQueue = dispatch_queue_create("io.branch.sdk.settings", DISPATCH_QUEUE_SERIAL);

        _saveTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _saveQueue);
        if (!_saveTimer) return;

        dispatch_time_t startTime = BNCDispatchTimeFromSeconds(kSaveTime);
        dispatch_source_set_timer(
            _saveTimer,
            startTime,
            BNCNanoSecondsFromTimeInterval(kSaveTime),
            BNCNanoSecondsFromTimeInterval(kSaveTime / 10.0)
        );
        __weak __typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(_saveTimer, ^ {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf save];
        });
        dispatch_resume(_saveTimer);
    }
}

- (void) save {
    @synchronized(self) {
        if (_saveTimer) {
            dispatch_source_cancel(_saveTimer);
            _saveTimer = nil;
        }
        NSError*error = nil;
        @try {
            NSData*data = [NSKeyedArchiver archivedDataWithRootObject:self];
            error = [BNCPersistence saveDataNamed:@"io.branch.sdk.settings" data:data];
        }
        @catch (id exception) {
            if (error) {
                BNCLogDebugSDK(@"Exception: %@.", exception);
            } else {
                error = [NSError errorWithDomain:NSCocoaErrorDomain
                    code:NSFileWriteUnknownError userInfo:@{NSUnderlyingErrorKey: exception}];
            }
        }
        if (error) BNCLogDebugSDK(@"%@", error);
        if (self.settingsSavedBlock) {
            BNCPerformBlockOnMainThreadAsync(^{
                self.settingsSavedBlock((BNCSettings*)self->_proxy, error);
            });
        }
    }
}

- (void) setRequestMetadataDictionary:(NSMutableDictionary<NSString*, NSString*>*)dictionary {
    @synchronized(self) {
        _requestMetadataDictionary = dictionary;
    }
}

- (NSMutableDictionary<NSString*, NSString*>*) requestMetadataDictionary {
    @synchronized(self) {
        if (!_requestMetadataDictionary) _requestMetadataDictionary = [NSMutableDictionary new];
        [self setNeedsSave];
        return _requestMetadataDictionary;
    }
}

- (void) setInstrumentationDictionary:(NSMutableDictionary<NSString*, NSString*>*)dictionary {
    @synchronized(self) {
        _instrumentationDictionary = dictionary;
    }
}

- (NSMutableDictionary<NSString*, NSString*>*) instrumentationDictionary {
    @synchronized(self) {
        if (!_instrumentationDictionary) _instrumentationDictionary = [NSMutableDictionary new];
        [self setNeedsSave];
        return _instrumentationDictionary;
    }
}

@end
