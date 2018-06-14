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

static NSString*const _Nonnull BNCSettingsPersistenceName = @"io.branch.sdk.settings";

@interface BNCSettings () {
    dispatch_queue_t _saveQueue;
    dispatch_source_t _saveTimer;
    __strong BNCSettingsProxy* _proxy;
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
    @synchronized(self->_settings) {
        [invocation setTarget:self->_settings];
        [invocation invoke];
        NSString* selectorName = NSStringFromSelector(invocation.selector);
        // NSLog(@"Proxy trigger '%@'.", selectorName);
        if ([selectorName hasPrefix:@"set"] &&
            !([selectorName isEqualToString:@"setNeedsSave"] ||
              [selectorName isEqualToString:@"setSettingsSavedBlock:"])) {
            [self->_settings setNeedsSave];
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector_ {
    @synchronized(self->_settings) {
        return [self->_settings methodSignatureForSelector:selector_];
    }
}

@end

#pragma mark - BNCSettings

@implementation BNCSettings

/*
// TODO:
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
*/

+ (instancetype) loadSettings {
    @synchronized(self) {
        BNCSettingsProxy*result = nil;
        BNCSettings* settings = [BNCPersistence unarchiveObjectNamed:BNCSettingsPersistenceName];
        if (!settings) settings = [[BNCSettings alloc] init];
        Class foundClass = [settings class];
        Class proxyClass = [BNCSettingsProxy class];
        Class settingsClass = [BNCSettings class];
        if ((__bridge void*) foundClass == (__bridge void*) proxyClass) {
            result = (id) settings;
        }
        else
        if ((__bridge void*) foundClass == (__bridge void*) settingsClass) {
            result = [[BNCSettingsProxy alloc] initWithSettings:settings];
        } else {
            settings = [[BNCSettings alloc] init];
            result = [[BNCSettingsProxy alloc] initWithSettings:settings];
        }
        BNCLogAssert(result && result->_settings);
        return (id) result;
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
    [self save];
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

        NSTimeInterval kSaveTime = 1.0; // TODO: shorten?

        if (!_saveQueue)
            _saveQueue = dispatch_queue_create(BNCSettingsPersistenceName.UTF8String, DISPATCH_QUEUE_SERIAL);

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
        NSError*error = [BNCPersistence archiveObject:self named:BNCSettingsPersistenceName];
        if (self.settingsSavedBlock) self.settingsSavedBlock((BNCSettings*)self->_proxy, error);
    }
}

- (void) clearAllSettings {
    @synchronized(self) {
        BNCSettings*settings = [[BNCSettings alloc] init];
        [BNCEncoder copyInstance:self fromInstance:((BNCSettingsProxy*)settings)->_settings ignoring:self.class.ignoreMembers];
        [self setNeedsSave];
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
