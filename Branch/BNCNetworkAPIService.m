/**
 @file          BNCNetworkAPIService.m
 @package       Branch
 @brief         Branch API network service interface.

 @author        Edward Smith
 @date          May 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCNetworkAPIService.h"
#import "BNCSettings.h"
#import "BNCApplication.h"
#import "BNCDevice.h"
#import "BNCWireFormat.h"
#import "BNCThreads.h"
#import "BranchSession.h"
#import "BranchMainClass.h"
#import "BranchMainClass+Private.h"
#import "BNCLog.h"
#import "BranchDelegate.h"
#import "BranchEvent.h"
#import "BranchError.h"
#import "BNCLocalization.h"
#import "BNCPersistence.h"
#import "NSData+Branch.h"

static NSString*_Nonnull BNCNetworkQueueFilename =  @"io.branch.sdk.network_queue";

#pragma mark BNCNetworkAPIOperation

@interface BNCNetworkAPIOperation () <NSSecureCoding>
- (instancetype) initWithNetworkService:(id<BNCNetworkServiceProtocol>)networkService
                               settings:(BNCSettings*)settings
                                    URL:(NSURL*)URL
                             dictionary:(NSDictionary*)dictionary
                             completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion;
- (void) main;
- (BOOL) isAsynchronous;

@property (strong) id<BNCNetworkServiceProtocol>networkService;
@property (strong) BNCSettings*settings;
@property (strong) NSURL*URL;
@property (strong) NSMutableDictionary*dictionary;
@property (strong) NSString*identifier;
@property (copy)   void (^_Nullable completion)(BNCNetworkAPIOperation*operation);
@end

#pragma mark - BNCAPIService

@interface BNCNetworkAPIService ()
@property (atomic, strong) id<BNCNetworkServiceProtocol> networkService;
@property (atomic, strong) BranchConfiguration *configuration;
@property (atomic, strong) BNCSettings *settings;
@property (atomic, strong) NSOperationQueue *operationQueue;
@property (atomic, strong) NSMutableDictionary<NSString*, NSData*> *archivedOperations;
- (void) saveOperation:(BNCNetworkAPIOperation*)operation;
- (void) deleteOperation:(BNCNetworkAPIOperation*)operation;
- (void) loadOperations;
@end

#pragma mark - BNCNetworkAPIService

@implementation BNCNetworkAPIService

- (instancetype) initWithConfiguration:(BranchConfiguration *)configuration {
    self = [super init];
    if (!self) return self;
    self.configuration = configuration;
    self.settings = self.configuration.settings;
    self.networkService = [configuration.networkServiceClass new];
    if (self.configuration.useCertificatePinning) {
        NSError*error = [self.networkService pinSessionToPublicSecKeyRefs:self.class.publicSecKeyRefs];
        if (error) {
            BNCLogError(@"Can't pin network certificates: %@.", error);
            error = [NSError branchErrorWithCode:BNCInvalidNetworkPublicKeyError];
            BNCLogError(@"Can't pin network certificates: %@.", error);
        }
    }
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.operationQueue.name = @"io.branch.sdk.BNCNetworkAPIService";
    self.operationQueue.maxConcurrentOperationCount = 1;
    [self loadOperations];
    return self;
}

- (void) dealloc {
    if ([self.networkService respondsToSelector:@selector(cancelAllOperations)]) {
        [self.networkService cancelAllOperations];
    }
}

- (void) setQueuePaused:(BOOL)paused_ {
    @synchronized(self) {
        self.operationQueue.suspended = paused_;
    }
}

- (BOOL) queueIsPaused {
    @synchronized(self) {
        return self.operationQueue.isSuspended;
    }
}

- (NSInteger) queueDepth {
    @synchronized(self) {
        return self.operationQueue.operationCount;
    }
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ %p Queued: %ld %@>",
        NSStringFromClass(self.class),
        (void*) self,
        self.queueDepth,
        self.operationQueue.operations];
}

#pragma mark - Utilities

- (void) appendV1APIParametersWithDictionary:(NSMutableDictionary*)dictionary {
    @synchronized(self) {
        if (!dictionary) return;
        NSMutableDictionary* device = [BNCDevice currentDevice].v1dictionary;
        [dictionary addEntriesFromDictionary:device];

        dictionary[@"sdk"] = [NSString stringWithFormat:@"mac%@", Branch.kitDisplayVersion];
        dictionary[@"ios_extension"] =
            BNCWireFormatFromBool([BNCApplication currentApplication].isApplicationExtension);

        // Add metadata:
        NSMutableDictionary *metadata = [dictionary[@"metadata"] mutableCopy];
        if (![metadata isKindOfClass:NSMutableDictionary.class]) metadata = [NSMutableDictionary new];
        [metadata addEntriesFromDictionary:self.configuration.settings.requestMetadataDictionary];
        if (metadata.count) dictionary[@"metadata"] = metadata;
        NSDictionary*instrumentation = [self.settings.instrumentationDictionary copy];
        if (instrumentation.count) dictionary[@"instrumentation"] = instrumentation;
        dictionary[@"branch_key"] = self.configuration.key;
    }
}

- (void) appendV2APIParametersWithDictionary:(NSMutableDictionary*)dictionary {
    @synchronized(self) {
        BNCApplication*application = [BNCApplication currentApplication];

        // Add user_data:
        NSMutableDictionary*userData = [NSMutableDictionary new];
        [userData addEntriesFromDictionary:[BNCDevice currentDevice].v2dictionary];
        userData[@"app_version"] = application.displayVersionString;
        userData[@"device_fingerprint_id"] = self.settings.deviceFingerprintID;
        userData[@"environment"] = application.branchExtensionType;
        userData[@"limit_facebook_tracking"] = BNCWireFormatFromBool(self.settings.limitFacebookTracking);
        userData[@"sdk"] = @"mac";
        userData[@"sdk_version"] = Branch.kitDisplayVersion;
        dictionary[@"user_data"] = userData;

        // Add metadata:
        NSMutableDictionary *metadata = [dictionary[@"metadata"] mutableCopy];
        if (![metadata isKindOfClass:NSMutableDictionary.class]) metadata = [NSMutableDictionary new];
        [metadata addEntriesFromDictionary:self.settings.requestMetadataDictionary];
        if (metadata.count) dictionary[@"metadata"] = metadata;
        NSDictionary*instrumentation = self.settings.instrumentationDictionary;
        if (instrumentation.count) dictionary[@"instrumentation"] = instrumentation;
        dictionary[@"branch_key"] = self.configuration.key;
    }
}

- (void) postOperationForAPIServiceName:(NSString*)serviceName
        dictionary:(NSMutableDictionary*)dictionary
        completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion {

    serviceName = [serviceName stringByTrimmingCharactersInSet:
        [NSCharacterSet characterSetWithCharactersInString:@" \t\n\\/"]];
    NSString *string = [NSString stringWithFormat:@"%@/%@", self.configuration.branchAPIServiceURL, serviceName];
    NSURL*url = [NSURL URLWithString:string];

    if (self.settings.trackingDisabled) {
        NSString *endpoint = url.path;
        if (([endpoint isEqualToString:@"/v1/install"] ||
             [endpoint isEqualToString:@"/v1/open"]) &&
             (dictionary[@"external_intent_uri"] != nil ||
              dictionary[@"universal_link_url"] != nil  ||
              dictionary[@"spotlight_identitifer"] != nil ||
              dictionary[@"link_identifier"] != nil)) {

              // Clear any sensitive data:
              dictionary[@"tracking_disabled"] = BNCWireFormatFromBool(YES);
              dictionary[@"local_ip"] = nil;
              dictionary[@"lastest_update_time"] = nil;
              dictionary[@"previous_update_time"] = nil;
              dictionary[@"latest_install_time"] = nil;
              dictionary[@"first_install_time"] = nil;
              dictionary[@"ios_vendor_id"] = nil;
              dictionary[@"hardware_id"] = nil;
              dictionary[@"hardware_id_type"] = nil;
              dictionary[@"is_hardware_id_real"] = nil;
              dictionary[@"device_fingerprint_id"] = nil;
              dictionary[@"identity_id"] = nil;
              dictionary[@"identity"] = nil;
              dictionary[@"update"] = nil;

        } else {

            [self.settings clearTrackingInformation];
            BNCNetworkAPIOperation* operation = [[BNCNetworkAPIOperation alloc] init];
            operation.error = [NSError branchErrorWithCode:BNCTrackingDisabledError];
            BNCLogError(@"Network service error: %@.", operation.error);
            if (completion) completion(operation);
            return;
        }
    }

    __weak __typeof(self) weakSelf = self;
    BNCNetworkAPIOperation* networkAPIOperation =
        [[BNCNetworkAPIOperation alloc]
            initWithNetworkService:self.networkService
            settings:self.settings
            URL:url
            dictionary:dictionary
            completion:^ (BNCNetworkAPIOperation*operation) {
                __typeof(self) strongSelf = weakSelf;
                [strongSelf deleteOperation:operation];
                if (completion) completion(operation);
            }];
    [self saveOperation:networkAPIOperation];
    [self.operationQueue addOperation:networkAPIOperation];
}

#pragma mark - Persistence

- (void) saveOperation:(BNCNetworkAPIOperation *)operation {
    @synchronized(self) {
        NSData*data = [NSKeyedArchiver archivedDataWithRootObject:operation];
        self.archivedOperations[operation.identifier] = data;
        [self saveArchivedOperations];
    }
}

- (void) deleteOperation:(BNCNetworkAPIOperation *)operation {
    @synchronized(self) {
        self.archivedOperations[operation.identifier] = nil;
        [self saveArchivedOperations];
    }
}
- (void) saveArchivedOperations {
    @synchronized(self) {
        [BNCPersistence archiveObject:self.archivedOperations named:BNCNetworkQueueFilename];
    }
}

- (void) loadOperations {
    @synchronized(self) {
        self.archivedOperations = [NSMutableDictionary new];
        NSDictionary*d = [BNCPersistence unarchiveObjectNamed:BNCNetworkQueueFilename];
        if (![d isKindOfClass:NSDictionary.class]) return;
        // Start the operations:
        __weak __typeof(self) weakSelf = self;
        for (NSString*key in d.keyEnumerator) {
            if (![key isKindOfClass:NSString.class])
                continue;
            NSData*data = d[key];
            if (![data isKindOfClass:NSData.class])
                continue;
            BNCNetworkAPIOperation*op = nil;
            @try {
                op = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
            @catch (id e) {
                BNCLogError(@"Can't unarchive network operation: %@.", e);
                op = nil;
            }
            if (![op isKindOfClass:BNCNetworkAPIOperation.class])
                continue;
            if (!self.archivedOperations[op.identifier]) {
                self.archivedOperations[op.identifier] = data;
                op.networkService = self.networkService;
                op.settings = self.configuration.settings;
                op.completion = ^ (BNCNetworkAPIOperation*operation) {
                    __typeof(self) strongSelf = weakSelf;
                    [strongSelf deleteOperation:operation];
                };
                [self.operationQueue addOperation:op];
            }
        }
    }
}

- (void) clearNetworkQueue {
    @synchronized(self) {
        self.archivedOperations = [NSMutableDictionary new];
        [BNCPersistence removeDataNamed:BNCNetworkQueueFilename];
        if ([self.networkService respondsToSelector:@selector(cancelAllOperations)])
            [self.networkService cancelAllOperations];
        [self.operationQueue cancelAllOperations];
    }
}

#pragma mark - Certificates

+ (SecKeyRef) publicSecKeyFromPKCS12CertChainData:(NSData*)keyData {
    OSStatus    status = errSecSuccess;
    NSArray     *items = nil;
    SecKeyRef   secKey = NULL;
    SecTrustResultType trustType = kSecTrustResultInvalid;

    // Release these
    CFArrayRef  itemsRef = NULL;

    NSDictionary *options = @{
        (id)kSecImportExportPassphrase: @"pass", // Mac requires a kSecImportExportPassphrase.
    };
    if (!keyData) {
        goto exit;
    }
    status = SecPKCS12Import((CFDataRef) keyData, (CFDictionaryRef)options, &itemsRef);
    if (status != errSecSuccess || !itemsRef || CFArrayGetCount(itemsRef) == 0) goto exit;

    items = (__bridge NSArray*) itemsRef;
    SecTrustRef trust = (__bridge SecTrustRef)(items[0][(id)kSecImportItemTrust]);
    if (!trust) goto exit;

    status = SecTrustEvaluate(trust, &trustType);
    if (trustType != kSecTrustResultInvalid) {
        secKey = SecTrustCopyPublicKey(trust);
    } else {
        status = errSecDecode;
    }

exit:
    if (secKey == NULL && status == errSecSuccess) {
        status = errSecItemNotFound;
    }
    if (status != errSecSuccess) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        BNCLogError(@"Can't import public key from pkcs12 data: %@.", error);
    }
    if (itemsRef) CFRelease(itemsRef);
    return secKey;
}

+ (NSArray/**<SecKeyRef>*/*) publicSecKeyRefs {

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wobjc-string-concatenation"

    NSArray *hexKeys = @[

        // star_branch_io.pub.p12
        @"30820b6102010330820b2706092a864886f70d010701a0820b1804820b1430820b10308205c70609"
         "2a864886f70d010706a08205b8308205b4020100308205ad06092a864886f70d010701301c060a2a"
         "864886f70d010c0106300e0408b2f4b4812a761cc402020800808205808cf564b6883d5fab3ca5e5"
         "87bcfcc3ca2694fd545b9d7941ca52638c25c922739ffc00d0e13476599c101d22bf29b545e2bd27"
         "59031249d19e8d1e16fc96fcc460e65450f178614052d45cffbf6ecb4bfe4ea26733d7f9f43492fa"
         "c9e35aa7d5a50aa91f6d0c2ef6cc3f14a38b4c83646a653018f0c36031f4dc461a22a6fcfc139c1e"
         "d060ae714cb3c6ecabd6b074004d5d2874ea92612591edfc6761e36f0488b90c7013f5d773bcdbc6"
         "ddbdade18198a6add9f01c0d7dbf8bf8724dd8e2f55088a9745dc74bc79a499225b08c1240dff655"
         "298e6ec97b74b91d70a65cf6c55c4f0b128051a45ab8c1c98b368e0162953ca4cac9372eb5a59719"
         "eac0781daaac26ce5b9e30522e75124c5e69ab21777c39c7c7d14a362d13f7991ee21d97af7d76b3"
         "b8271ddb022e81a165b6e98408b601f68660d9aa7bc1f48a6b76ffcdf7e66b976af31229b89daff2"
         "36e26dc60fcaeb512c6c437f99b1934e871228632ec1fcd13736f9544dcc5bb0388bde0b5e142029"
         "413d8de139830ac6b323db2fc2086d41208979eff8faaf74654f7370f5fd21a465a66832daff27ad"
         "bc3ce4b419df01b6f77a5f54faf34dd0676b2a5de525a8a1749756949a779573640c94b96c37fd12"
         "f0814560a52742742b5973b203c5eed93d6384ecc63474556bc169c34a762135708cf81e10b00bbf"
         "a551ddffa17b78bbfae0188b95aa3c9fd2923528170e8f930d72a0dc8875322b9ceb9afd8569dc14"
         "ee647757756868bcb4951ea5e022d096fead31e8ba6e254fe063f9627b40ed2649bdefb0e4a6c258"
         "6a6c58dbd894e1a4326d514d39b5eaac06550f7128c73ef039ae0247898cb98680cc575702463614"
         "84f8268ce5bf366579f0d0a9f1dfd90fcd972a65f8d95589214ed19369727d3c9ffc4e3088a7db55"
         "53e0b199de54e32e747aeab6f8624572bb5cd6efe7d5a27f26b3ffefed4830abdb434fe471ece6f8"
         "91b3404d1a5167a481d85377548a70f5f39c37b3e1a725c7f6f3f02bc500dbc8d3326f45b4d6c4ee"
         "39a1b9922496b413499254fd77bc4c5b5a8579a8cfb1a472b017baf3e13a769eedf2b20754ab2929"
         "f811d6a6a2fdd17cbdc1baca88d760f167a9321d956431c0300f4a63a831ba6430fc34d122a810e1"
         "d1b11b56ef35979386e222cd91643d4efc70e236c0efa8faf1895ed698dcc010d20bfa274e123f91"
         "61552b19574fe373d4d16d45d6048c4d1d935a58d2cdba5bd78330c5387799e3b31758ca593ab4ea"
         "1a101d997d5e0ea6bba9dfc814c8a7fd447c6612808c35ddb59a0145eda50e2fa6a5113eb4f5ef4e"
         "20e8769c204461f286d5257a74e591ef3b408b0a889a6cd3c8fd8011c4afcf05a17e36b503d78dba"
         "f019c51f851c11249467d6a226653546358622ed487238aa5fa91acb8a9603074bd56fa9aa797e8c"
         "b719c2e25c18c05c62f4b9646434217b890307a482ea0e074e3f4f354499495baac89f660d496585"
         "d655005e22070922f238cc8ec3b74762936df5913d3680a3cf2ccc83550a1b9d9ddcab8bc3b7f761"
         "a4762934c4b3992461978483396e867acc778254f1bd14989c0b46631e6f47548eb5e7cab400f299"
         "357b1a133413cf33a3deec3de244226ce9d60cb778f0545d761f3129e64d72b3ba9c4dc6dec40e92"
         "26a2ff72c38a6fcedda2173817c7bb523a3a7feae20126e5a7cd33ab0b844c21a58b096e40a121b1"
         "d5d70ea92b3f61417374ccff8935a0073197da9242ad419326dcaa9301331d5df3459f82614bfebf"
         "6a74a75c18c12abb8794b7badd623636a39b101bef78966369d33b3104c68a2979a107b79167519b"
         "9cb3dbabf8fd7a25b53aabff4e79d1f475b99306cc9c2f7849c79e2a37cb354ffd203fd673839aae"
         "0602c9d3ce4cdc695cd06fa3dec16b5740d35c04e3645d24682962a4f09e7f340ea2f0287a70b145"
         "c8c083ddbda493e880d9eeb6454e82e6814679bc8e477c75ea8aa5ec3ed389a4cce52bacd7308205"
         "4106092a864886f70d010701a08205320482052e3082052a30820526060b2a864886f70d010c0a01"
         "02a08204ee308204ea301c060a2a864886f70d010c0103300e04082d73660391f709240202080004"
         "8204c87691f8c778bea26c01a6a5a656b9b6546253ae94126ed43d5e4a3b31b3b3a9069ea09d11ea"
         "426465eead081da3b595cbd95aca497cf1d98fcb73d28684f565ae7b152cf0a826a553a274714b5c"
         "fb0d02d452b248e0ec8b7703181d00210aa60f4cfc0d83072d3d10e962e70bca7feef48433144323"
         "d1cb35dd4eba06288d624e0113ae8ea33076615eea97e24cd91b454b45578cf09f8905a64012aedf"
         "82e41516a90858cae0694449746526f79e76c3a44edcb7ba517d212c2fa6e831aa9a4df96343c8f7"
         "a630ab26f47b41aaf1c362f843914b5300bcfc37c1faf4ffce9acb12c78a704c495c1da0cfd96f35"
         "646e40e7501685fab143997005781cbce1c08279182c9712435f049870813a11094caaaf71a099a6"
         "4a279f9f1d8b365a512f6abac813bd190273973d44f10c7cfd12d9758d624fdc09bb451143aeb430"
         "9e01fe5ad409d1994e6b33cc31bd354a45ba68827705a345615087e1777ec0536301410fbde6e7f6"
         "863844f01f43c629db7f8ed76c3fcfac518c5ab824112b6eece6eca2701dc23abbd66c0d4b9a9892"
         "c885adfb92620a2783be4a09bd8abfd5e7bb612340f96f592d34d04c9c81c5d6e3141417fddc255f"
         "2e469202a33735aef02dbfc8b19a82b3fea8237ef5eaa041b217bb057a20f7d90aa1fbb50288d825"
         "042ecef4de1bc6eb21aa33acc6f987da79ec46bf91f88eafd167b89f294735cd55ac6af775be2226"
         "a5e958e6e31717b000da01bd0f8800f725a9f37490ae20687a8051d0b2389df783a18390393eb7e2"
         "d5b74e3cc47055b05d8def510fe8e08efbc770aa0fb0125c0ee9ca8c0fbf3dd3e5e60cbffb0d74e0"
         "ff15836bba27fdbce7d9bb4b204e7527b39fa192deba42863c23a710c62b0960dbada2de3594c2af"
         "1c7c61a02b67fbef7219f2efe9b36feabac2c8f8d34ff318fc5fc9843165b68204e6137664cdd9d2"
         "9738c88a49c5ea9f0ca84481e797956d821717fb80ab02eca785fc4fac53f36275e6833e063ea29c"
         "16391bf5840b6d5d45529f72012c8c22c5cd5a8518c9ddca6a73ea7c20008618b824d208626b102e"
         "2b20cbd34d394778b8cfcccc8d250f05371723dc3875b3a7ad03f0934b108d06131d1b178edb3a68"
         "f787216c16cea9e2f468f5cf602c172fab5c921de2e6fa9b47e81c61f4f79029a37b75894e979c20"
         "b3067f7d2eeddaa0bc0adad0f9b17ad37a338442aa3486da4272e7d58045873c73d1fe128138e06c"
         "c790d207fbd95e9acc6f052ee22b33389a142ba9447f9bceefb3fb7c1c2e13e98e27b46b3b738e20"
         "b96ea9e041852e99a73e95eae14189756bbfad2c0dcd55f61abd9687fbc302c5a5cc173f1bdf0422"
         "4c2ea60c129cc07a2edcf98fa4179e55fb95be0bbbe9eff9c41bc43f5f404afd28ec7f99e2e831d2"
         "a827b63bb7be5f23e815d724f2f44dc575727362d010bdfead4fe3ca2a02864de1901914dea214e7"
         "70b14f4665dd8d4424f1d84713e233665c8b522182c9329ed3bf0dea0f54a0533eb7d83b4adbac47"
         "9b1ec09e17283aaa535436063de8354f540ba22dd33636b7c9c2b7eebc551e6d38362a18b810b24b"
         "a760d09bbde49b8bcdfbfec029c401a789ebcab0d34b8a05821413d313afe78f78027d8741edcd13"
         "2c8541d10a75766ab82c5e82058102ceb46959c00916a5f90135098f23f089dadf60808269a5031d"
         "b941ecd48abfcdf24235f136daabfdee36a36ed26b3d995f51835d3125302306092a864886f70d01"
         "09153116041433d43dfd9efcdf7b8d8708b8cee57e9d59896bb830313021300906052b0e03021a05"
         "000414ea1ab3f87d18c4b624c3446e0173d2052e71a8150408c32f83c754ec517e02020800",

        // backup.pub.p12
        @"30820a31020103308209f706092a864886f70d010701a08209e8048209e4308209e0308204970609"
         "2a864886f70d010706a0820488308204840201003082047d06092a864886f70d010701301c060a2a"
         "864886f70d010c0106300e04087317d07edab3645f02020800808204507290c6b815b98265350c80"
         "cf7a1376919081ae32c31f24ef1bb67e4a77d37016c65bb7f4acad23692238c3ddc729504219fa71"
         "a93318054390ca8a253358164494ace9861701c6fb58adbdf4fa6e8509df7e043464134bc284d7be"
         "5cd2729d50c8170555e7e98f0e7f5062c634babd1d4490ace2ae485d1fb024c85d0b2fd3deaddf88"
         "3fc35ed76db3c40e063accba1ae7386ea8087377ae765f4bbab8337f44d83ef4db3ce4361e1804cc"
         "4ee395ffca3231202303b54f1d5a9d9329f077a2737e2f1fb52cc6111724d89f80e16243f1d3cac5"
         "44312362fb2254498ca384a803400f4afa141a0c2bc0deba1c3e24ccfe9abaf45b008953c19f9d6e"
         "550d612dc3bd600cd8fecc8cd7a3e4ab5846470bfa0c2ee7f31c5b39f9859fdea82ed5310d068ca8"
         "6a761c9faee7ae472445aec10b08bf66ce6e0574e9d930e398d8b6b526fd2d6109f50ae24f7d21a7"
         "9ecc0f36cf58c50beb0f6ea360a34058893f039269d13e6c3710649f08e3c621a6d0bd901053cfd2"
         "a0742484e01e2df76c5f4e1286a38a792d06c2279731299c1d1aa1e2f7a283691c84ae3f85876344"
         "167cf6b13cb7ff0a8e23ee35fc3573e43df141b0ae4ba71b927039c830133ab1dff1fa1ac95e143a"
         "b306a0c59d3ec07c91b3c7659cd4d11713fdb15d0b05ad624ba6435dbeb52cede0a5852d708124f2"
         "044a51dabfdf7911b1c5bd88a83c0b03c6c2f984d0e5b00e231f6d4c3a2f1c8327671ecb311ea978"
         "4055426de3db02605d2a5e3b09bff7faf6f81a8ef816eebf672abc3bcf733fc9fce405ab65dea25d"
         "baa4dbcc8e8b263db4fbe02295dd619ee3d53a87a7dd4a79129ab1aa72faaa253118ea464212123b"
         "0dea5428d7fa6907394792f7d9a74219237cd5a759e5b0cf21473dcc6a1648eb3a377e94cfab5ec0"
         "f546c459a052cee0d79ddf1a44ae2dd97dcc0cc1a5b45e3fbd1ae24506c06724f2fc2c14be2ca965"
         "7c569702ceb94256ac146b2583e2a4a22cadb6ace82dcb00b4b4044cb38476ef056091d731ff2410"
         "9bddfd67d7b7c715ccd90f7acc6ecb9462db2174b0f3b08593a5b08f58d0f0fa256f214218090d78"
         "05494c26dd448bc92a647c61fe3fbd8a95f142e8eb1bbc080038a7f47b1e4574c6ec8423539b0181"
         "aabe071015dda4a521c5361d88bb1be6f0d23971072de03c0b4de364ef7697ddd5f989bdc3a3eaca"
         "0a1f8958896ca7650175bde212b4c9d400d99c10056266d1708d15bb47c20a143d06f7e934aba7a5"
         "18f6344e04dbb12e4b26e3be978e7e26fd32da60432e1ed06571b94dbbf04febc55d4babea733c89"
         "3185dc80e34e1677fbf706bd6d9b97934fbfa2aab5ad67354122a880a2a52e86c65776d43d5a5962"
         "b4c1d550f845bc61b7979c0a8808bbe36b061aba4b48a479bfcd308ed40c34f9690168344b9a9dd3"
         "1ce70c6e89baeda6a1e720e2bb26adab841d5e2f0934d5d92316574bbe99ffea8fe7419e3cd1a2d3"
         "31ee7efbe5cb1e02e67197b6c2e28f7a13729964b5426113c8122aa450e861d62ba829f506829fce"
         "9411d767cc9eb7da4560a4664e3082054106092a864886f70d010701a08205320482052e3082052a"
         "30820526060b2a864886f70d010c0a0102a08204ee308204ea301c060a2a864886f70d010c010330"
         "0e0408c8321002f801e42f02020800048204c8743bfdc5f0633c349ed9516d1b5c0fcfc5acdceac1"
         "3a77a3ab2efd91ceddfe21ac86e2da3a36d0c7cdfe1f6beddc359623be4fa5026a088caaaf5dae43"
         "99b1dacae8f0847ef597e918a1328c2424af5987e37f45e48d4e1153652a17d838aa50ba44a4b265"
         "cbe41e3d36f46294a7a71adcb858f0ef4bbdb560d555e8f4af9a061ca0aa591bde0c4d5d5ae6d227"
         "a91a895a00080b46513cb107ec088add31fa38cdd8f072ef93d6ea8377cbba857d5b76ddaad53fd5"
         "7747cf262939b76534bb670c52bc1b7bb197a0f985f9d38f66f92cc0eef3bede7a99ffffb258c755"
         "801dbbb768da1a5bb8aa9ef0a064c531e6eb88f2ed115bea05d1f8ce8ad59f736b90ed38f32c9d97"
         "ae62a19e0051f036b08b4c908787ec8143a1d87842eee0ee4bee6ef784c199d6527d49b7c9ba52ed"
         "648a39c0dd16b5f1fd815ffc6648bb1891e9d91917a751e35716b0019bed69e39a15ae0ed6b62cbb"
         "3af3fb977643df88b7a19820657657d0828dfd1c87402a93a992a7c8a6ddc024d4f13b90fb26ab5e"
         "0f29b05cc877fdd010bffcf1410bd8fece7a823d768187fddad1bb125feefde42bc030d7a3ddf334"
         "349f2414594ae39dadb0df3bb56b03a2b81ba7c16c4045ffdf1e6374d46af515849de593eed00a45"
         "14784063516fe8f43c326e8d3756df7e516da6a0f13be11b368010177e4e8bc9e1182043f0e244d2"
         "3f0af9dd21c3b0dc3f9f3e1a36d553cfa3d9efc2dfdf5ea0adf722d62e2e39672dd24d192e94e555"
         "2b3120112b419707d78ef683a21c3de056680b6d5dabd9e91f20da0a03ea0ce584ed85628bc44ec4"
         "3f1c9f23ee60131e28b95376ee1ff6e7b985035548d515a354a8a91d325821d5b65f74fab56cba28"
         "db473580e8d5492dd141622efa95dc473582de85ad522dbad33e473aec7d4b2712a4f4373a8f08c0"
         "bc71cb765e67ddd2132b7da6219971640954444100d3665f83cf7d3e4195c2b5859f078661a579f2"
         "cad13d1c97c989b82f93878e8c273157825b4fb6ac5fd035cd02db093c6d7c1bf24692a455a77546"
         "ea1490c1e846a194dd65f76bf28b21fb70718276c14f8aa855c38a7f4e24c408a6fb6e3698cebc77"
         "ae6186e1ccc5f54987b03221b65f18765d8b2285b59f25a2512d4be3b5e4a1292b141cd21b33e5a3"
         "b27aa5908c7d2f56bc82fb1ce14fc1fa344786179ac67db788cb508f11e72923714d5d4cce792a9b"
         "7525b8fabc8741a9b74303d88a345f79949f00620ecae07b80538d4c1814733cc748122864b00417"
         "1053daf2ba7f50e4e069b08ae7c114bed73a7f2f1b056da33d19e957ca06e7ab7289bbed1466c4d2"
         "79285d8fead0c1ddaad30d06cb212ee77e945289b4f9f2f0a00a705b68b52f172013ee962a9881d5"
         "f51be22b9520798344d7444700ffb3c7332ee9a08100db47c0017a08b207137f3984af74cc5c1fe6"
         "03e38b085b25df52d3a3821fcbe3bb077c90cbdc2470793143602f7d95dec38408e1980e6b009518"
         "abd97a95d7bea0bd188df7a338e9e112078531fd86327e82cb7bc14e767c2b7330b8c90b9172cb61"
         "8f3badae58af31b0efd5d0526b0b0623514b2f740f58cfa4c786d6c50e34032b5876d58a70992205"
         "9b6b1320b43abb8a10bd087dad0cbd81ced47a26436ad8dd1a12a51a2a4db9e76754e1796fc931db"
         "0bfdfba6577d53c42ee22aec2b72731efdd8912951ebe3d13a36e8c6b859eeb4b3334083f012e9d1"
         "1600d73125302306092a864886f70d010915311604142942010915a821745e3f65fd1a7b0e1daaf6"
         "d56930313021300906052b0e03021a05000414af689a53fc5fc774b1020bfa4e294bef4c9d29ea04"
         "08dbe20565b30b976b02020800"
    ];

    #pragma clang diagnostic pop

    NSMutableArray *array = [NSMutableArray array];
    for (NSString* hexKey in hexKeys) {
        NSData *data = [NSData bnc_dataWithHexString:hexKey];
        if (data) {
            SecKeyRef secKey = [self publicSecKeyFromPKCS12CertChainData:data];
            if (secKey) [array addObject:(__bridge_transfer id)secKey];
        } else {
            BNCLogError(@"Can't read data for public key.");
        }
    }
    return array;
}

@end

#pragma mark - BNCNetworkAPIOperation

@implementation BNCNetworkAPIOperation

- (instancetype) initWithNetworkService:(id<BNCNetworkServiceProtocol>)networkService
                               settings:(BNCSettings*)settings
                                    URL:(NSURL*)URL
                             dictionary:(NSDictionary*)dictionary
                             completion:(void (^_Nullable)(BNCNetworkAPIOperation*operation))completion {
    self = [super init];
    if (!self) return self;
    self.networkService = networkService;
    self.settings = settings;
    self.URL = URL;
    self.dictionary = [dictionary mutableCopy];
    self.completion = completion;
    self.qualityOfService = NSQualityOfServiceUserInitiated;
    self.name = [URL path];
    self.identifier = [[NSUUID UUID] UUIDString];
    return self;
}

- (BOOL) isAsynchronous {
    return YES;
}

- (void) main {
    NSInteger retry = 0;
    NSError*error = nil;
    self.startDate = [NSDate date];
    self.timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60.0];
    {
        if (([self.timeoutDate timeIntervalSinceNow] < 0) || self.isCancelled)
            goto exit;

        do  {
            if (retry > 0) {
                // Wait before retrying to avoid flooding the network.
                BNCSleepForTimeInterval(1.0);
            }
            NSData *data = nil;
            if (self.dictionary) {
                NSError *error = nil;
                self.dictionary[@"retry_number"] = BNCWireFormatFromInteger(retry);
                data = [NSJSONSerialization dataWithJSONObject:self.dictionary options:0 error:&error];
                if (error) {
                    BNCLogError(@"Can't convert to JSON: %@.", error);
                    goto exit;
                }
            }

            NSTimeInterval timeout = MIN(20.0, [self.timeoutDate timeIntervalSinceNow]);
            if (timeout < 0.0) {
                error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
                goto exit;
            }

            NSMutableURLRequest*request =
                [[NSMutableURLRequest alloc]
                    initWithURL:self.URL
                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                    timeoutInterval:timeout];
            request.HTTPMethod = @"POST";
            request.HTTPBody = data;
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

            dispatch_semaphore_t network_semaphore = dispatch_semaphore_create(0);
            self.operation =
                [self.networkService networkOperationWithURLRequest:request
                    completion:^ (id<BNCNetworkOperationProtocol>operation) {
                        dispatch_semaphore_signal(network_semaphore);
                    }
                ];
            [self.operation start];
            dispatch_semaphore_wait(network_semaphore, DISPATCH_TIME_FOREVER);
            error = [self verifyNetworkOperation:self.operation];
            if (error) {
                BNCLogError(@"Bad network interface: %@.", error);
                goto exit;
            }
            [self collectInstrumentationMetrics];
            if (self.operation.error) {
                BNCLogError(@"Network service error: %@.", error);
            }

            retry++;

        } while (!self.isCancelled && [self.class canRetryOperation:self.operation]);

    error = [self.class errorWithOperation:self.operation];
    if (error) goto exit;

    NSDictionary*dictionary = [self.class dictionaryWithJSONData:self.operation.responseData error:&error];
    if (error) goto exit;

    if (![dictionary isKindOfClass:NSDictionary.class]) {
        error = [NSError branchErrorWithCode:BNCBadRequestError];
        goto exit;
    }
    self.session = [BranchSession sessionWithDictionary:dictionary];

    if (self.session.linkCreationURL.length)
        self.settings.linkCreationURL = self.session.linkCreationURL;
    if (self.session.deviceFingerprintID.length)
        self.settings.deviceFingerprintID = self.session.deviceFingerprintID;
    if (self.session.userIdentityForDeveloper.length)
        self.settings.userIdentityForDeveloper = self.session.userIdentityForDeveloper;
    if (self.session.sessionID.length)
        self.settings.sessionID = self.session.sessionID;
    if (self.session.identityID.length)
        self.settings.identityID = self.session.identityID;
    }
exit:
    self.error = error;
    if (self.completion)
        self.completion(self);
}

- (NSError*) verifyNetworkOperation:(id<BNCNetworkOperationProtocol>)operation {
    if (!operation) {
        NSString *message = BNCLocalizedString(
            @"A network operation instance is expected to be returned by the"
             " networkOperationWithURLRequest:completion: method."
        );
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (![operation conformsToProtocol:@protocol(BNCNetworkOperationProtocol)]) {
        NSString *message =
            BNCLocalizedFormattedString(
                @"Network operation of class '%@' does not conform to the BNCNetworkOperationProtocol.",
                NSStringFromClass([operation class]));
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    if (!operation.request) {
        NSString *message = BNCLocalizedString(
            @"The network operation request is not set. The Branch SDK expects the network operation"
             " request to be set by the network provider."
        );
        NSError *error = [NSError branchErrorWithCode:BNCNetworkServiceInterfaceError localizedMessage:message];
        return error;
    }
    return nil;
}

- (void) collectInstrumentationMetrics {
    if ([self.operation.request.HTTPMethod isEqualToString:@"POST"]) {
        NSTimeInterval elapsedTime = [self.startDate timeIntervalSinceNow] * -1000.0;
        NSString *lastRoundTripTime = [[NSNumber numberWithDouble:floor(elapsedTime)] stringValue];
        NSString *path = [self.operation.request.URL path];
        NSString *brttKey = [NSString stringWithFormat:@"%@-brtt", path];
        self.settings.instrumentationDictionary = nil;
        self.settings.instrumentationDictionary[brttKey] = lastRoundTripTime;
    }
}

+ (BOOL) canRetryOperation:(id<BNCNetworkOperationProtocol>)operation {
    if (operation.error == nil && operation.HTTPStatusCode >= 200 && operation.HTTPStatusCode < 300)
        return NO;
    if (operation.HTTPStatusCode >= 500 || operation.HTTPStatusCode == 408)
        return YES;
    switch (operation.error.code) {
    // Possible poor network condition codes. From NSURLError.h:
    case NSURLErrorTimedOut:                // Timeout.
    case NSURLErrorCannotFindHost:          // DNS error.
    case NSURLErrorNetworkConnectionLost:   // Network dropped.
    case NSURLErrorSecureConnectionFailed:  // SSL may have timed out.
    case errSSLClosedAbort:                 // SSL may have timed out.
        return YES;
    default:
        return NO;
    }
}

+ (NSDictionary*) dictionaryWithJSONData:(NSData*)data
        error:(NSError*_Nullable __autoreleasing *_Nullable)error_ {
    NSError*error = nil;
    NSDictionary *dictionary = nil;
    @try {
        if ([data isKindOfClass:[NSData class]]) {
            dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        } else {
            error =
                [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                    userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode JSON data."}];
        }
    }
    @catch (id object) {
        dictionary = nil;
        if ([object isKindOfClass:[NSError class]]) {
            error = object;
        } else {
            error =
                [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCannotDecodeContentData
                    userInfo:@{ NSLocalizedDescriptionKey: @"Can't decode JSON data."}];
        }
    }
exit:
    if (error_) *error_ = error;
    return dictionary;
}

+ (NSError*) errorWithOperation:(id<BNCNetworkOperationProtocol>)operation {
    NSError *underlyingError = operation.error;
    NSInteger status = operation.HTTPStatusCode;
    NSError *branchError = nil;

    // Wrap up bad statuses w/ specific error messages
    if (status >= 500 || status == 408) {
        branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
    }
    else if (status == 409) {
        branchError = [NSError branchErrorWithCode:BNCDuplicateResourceError error:underlyingError];
    }
    else if (status >= 400) {

        NSDictionary*dictionary = [self dictionaryWithJSONData:operation.responseData error:nil];
        if (![dictionary isKindOfClass:NSDictionary.class])
            dictionary = nil;

        NSString *errorString = nil;
        NSString *s = dictionary[@"error"];
        if ([s isKindOfClass:[NSString class]]) {
            errorString = s;
        }
        if (!errorString) {
            s = dictionary[@"error"][@"message"];
            if ([s isKindOfClass:[NSString class]])
                errorString = s;
        }
        if (!errorString)
            errorString = underlyingError.localizedDescription;
        if (!errorString)
            errorString = BNCLocalizedString(@"The request was invalid.");
        branchError = [NSError branchErrorWithCode:BNCBadRequestError localizedMessage:errorString];
    }
    else if (underlyingError) {
        branchError = [NSError branchErrorWithCode:BNCServerProblemError error:underlyingError];
    }

    if (branchError) {
        BNCLogError(@"An error prevented request to %@ from completing: %@",
            operation.request.URL.absoluteString, branchError);
    }

    return branchError;
}

#pragma mark - NSSecureCoding

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    self.URL = [aDecoder decodeObjectOfClass:NSURL.class forKey:@"URL"];
    self.dictionary = [aDecoder decodeObjectOfClass:NSDictionary.class forKey:@"dictionary"];
    self.identifier = [aDecoder decodeObjectOfClass:NSString.class forKey:@"identifier"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.URL forKey:@"URL"];
    [aCoder encodeObject:self.dictionary forKey:@"dictionary"];
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
}

@end
