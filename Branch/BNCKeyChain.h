/**
 @file          BNCKeyChain.h
 @package       Branch
 @brief         Simple access routines for secure keychain storage.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BranchHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCKeyChain : NSObject

- (instancetype) init __attribute__((unavailable("init is not available.")));

- (instancetype) initWithSecurityAccessGroup:(NSString*)securityGroup NS_DESIGNATED_INITIALIZER;

/**
 @brief Remove a value for a service and key. Optionally removes all keys and values for a service.

 @param service     The name of the service under which to store the key.
 @param key         The key to remove the value from. If `nil` is passed, all keys and values are removed for that service.
 @return            Returns an `NSError` if an error occurs.
*/
- (NSError*_Nullable) removeValuesForService:(NSString*)service
                                         key:(NSString*_Nullable)key;

/**
 @brief Returns a value for the passed service and key.

 @param service     The name of the service that the value is stored under.
 @param key         The key that the value is stored under.
 @param error       If an error occurs, and `error` is a pointer to an error pointer, the error is returned here.
 @return            Returns the value stored under `service` and `key`, or `nil` if none found.
*/
- (id _Nullable) retrieveValueForService:(NSString*)service
                                     key:(NSString*)key
                                   error:(NSError*_Nullable __autoreleasing *_Nullable)error;

/**
 @brief Returns an array of all keys found for a service in the keychain.

 @param service     The service name.
 @param error       If an error occurs, the error is returned in `error` if it is not `NULL`.
 @return            Returns an array of the items stored in the keychain or `nil`.
*/
- (NSArray<NSString*>*_Nullable) retrieveKeysWithService:(NSString*)service
                                                   error:(NSError*_Nullable __autoreleasing *_Nullable)error;

/**
 @brief Stores an item in the keychain.

 @param value       The value to store.
 @param service     The service name to store the item under.
 @param key         The key to store the item under.
 @return            Returns an error if an error occurs.
 */
- (NSError*_Nullable) storeValue:(id)value
                      forService:(NSString*)service
                             key:(NSString*)key;

@property (atomic, copy, readonly) NSString* securityAccessGroup;
@end

NS_ASSUME_NONNULL_END
