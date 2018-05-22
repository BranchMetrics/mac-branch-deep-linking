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
    dispatch_queue_t _saveQueue;
    dispatch_source_t _saveTimer;
    __weak BNCSettingsProxy* _proxy;
    NSMutableDictionary<NSString*, NSString*>* _requestMetadataDictionary;
    NSMutableDictionary<NSString*, NSString*>* _instrumentationDictionary;
}
@end

@interface BNCSettingsProxy : NSProxy {
    @public
    BNCSettings*_settings;
}
@end

@implementation BNCSettingsProxy

- (id) initWithSettings:(BNCSettings*)settings {
    self->_settings = settings;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation setTarget:self->_settings];
    [invocation invoke];
    NSString* selectorName = NSStringFromSelector(invocation.selector);
    if ([selectorName hasPrefix:@"set"] &&
        ![selectorName isEqualToString:@"setNeedsSave"]) {
        [self->_settings setNeedsSave];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector_ {
    return [self->_settings methodSignatureForSelector:selector_];
}

@end

#pragma mark - BNCSettings

@implementation BNCSettings

+ (instancetype) sharedInstance {
    // TODO: There's a weird ARC retain count problem here where the proxy is released at the end.
    // It's duct tape fixed by having sharedInstance have references to both the proxy and object.
    // It will be nice to really fix this.
    static __strong BNCSettings*sharedInstance = nil;
    static __strong BNCSettingsProxy*sharedInstanceProxy = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        BNCSettings* settings = [self loadSettings];
        if (settings) {
            sharedInstanceProxy = (id) settings;
            sharedInstance = ((BNCSettingsProxy*)sharedInstanceProxy)->_settings;
        }
    });
    return (BNCSettings*)sharedInstanceProxy;
}

BNCSettings*bnc_settings = nil;

+ (instancetype) loadSettings {
    BNCSettings* settings = nil;
    NSData*data = [BNCPersistence loadDataNamed:@"io.branch.sdk.settings"];
    settings = (data) ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : [[BNCSettings alloc] init];
    Class foundClass = [settings class];
    Class proxyClass = NSClassFromString(@"BNCSettingsProxy");
    Class settingsClass = NSClassFromString(@"BNCSettings");
    if ((__bridge void*) foundClass == (__bridge void*) proxyClass) {
        bnc_settings = settings;
        return bnc_settings;
    }
    else
    if ((__bridge void*) foundClass == (__bridge void*) settingsClass) {
        bnc_settings = (id) settings->_proxy;
        return bnc_settings;
    } else {
        bnc_settings = [[BNCSettings alloc] init];
        return bnc_settings;
    }
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) init {
    self = [super init];
    if (!self) return self;
    BNCSettingsProxy*proxy = [[BNCSettingsProxy alloc] initWithSettings:self];
    self->_proxy = proxy;
    return (BNCSettings*) proxy;
}

- (void) dealloc {
    if (_saveTimer) {
        dispatch_source_cancel(_saveTimer);
        _saveTimer = nil;
    }
}

+ (NSArray<NSString*>*) ignoreMembers {
    return @[@"_saveQueue", @"_saveTimer", @"_proxy", @"_settingsSavedBlock"];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [self init];
    if (!self) return self;
    BNCSettings*settings = ((BNCSettingsProxy*)self)->_settings;
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
