/**
 @file          BNCLog.h
 @package       Branch
 @brief         Simple logging functions.

 @author        Edward Smith
 @date          October 2016
 @copyright     Copyright © 2016 Branch. All rights reserved.
*/

#import "BranchHeader.h"

#ifdef __cplusplus
extern "C" {
#endif

///@functiongroup Branch Logging Functions :nodoc:

#pragma mark Log Initialization

/// Log facility initialization. Usually there is no need to call this directly.
extern void BNCLogInitialize(void) __attribute__((constructor));

#pragma mark Log Message Severity

/// Log message severity
typedef NS_ENUM(NSInteger, BNCLogLevel) {
    BNCLogLevelAll = 0,                     //!< Show all log messages.
    BNCLogLevelDebugSDK = BNCLogLevelAll,   //!< Show debug messages specific to debugging the SDK.
    BNCLogLevelDebug,                       //!< Only show debug messages for debugging app problems and above.
    BNCLogLevelWarning,                     //!< Only show warning messages and above.
    BNCLogLevelError,                       //!< Only show error messages and above.
    BNCLogLevelAssert,                      //!< Only show assertion messages and above.
    BNCLogLevelLog,                         //!< Only show log messages and above.
    BNCLogLevelNone,                        //!< Don't show any log messages.
    BNCLogLevelMax
};

/*!
* @return Returns the current log severity display level.
*/
extern BNCLogLevel BNCLogDisplayLevel(void);

/*!
* @param level Sets the current display level for log messages.
*/
extern void BNCLogSetDisplayLevel(BNCLogLevel level);

/*!
* @param level The log level to convert to a string.
*
* @return Returns the string indicating the log level.
*/
extern NSString *_Nonnull BNCLogStringFromLogLevel(BNCLogLevel level);

/*!
* @param string A string indicating the log level.
*
* @return Returns The log level corresponding to the string.
*/
extern BNCLogLevel BNCLogLevelFromString(NSString*_Nullable string);

#pragma mark - Client Initialization Function

typedef void (*BNCLogClientInitializeFunctionPtr)(void);

///@param clientInitializationFunction The client function that should be called before logging starts.
extern BNCLogClientInitializeFunctionPtr _Nullable
    BNCLogSetClientInitializeFunction(BNCLogClientInitializeFunctionPtr _Nullable clientInitializationFunction);

#pragma mark - Optional Log Output Handlers

///@brief Pre-defined log message handlers --

typedef void (*BNCLogOutputFunctionPtr)(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);

///@param functionPtr   A pointer to the logging function.  Setting the parameter to NULL will flush
///                     and close the currently set log function and future log messages will be
///                     ignored until a non-NULL logging function is set.
extern void BNCLogSetOutputFunction(BNCLogOutputFunctionPtr _Nullable functionPtr);

///@return Returns the current logging function.
extern BNCLogOutputFunctionPtr _Nullable BNCLogOutputFunction(void);

/// If a predefined log handler is being used, the function closes the output file.
extern void BNCLogCloseLogFile(void);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
extern void BNCLogSetOutputToURL(NSURL*_Nullable URL);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxBytes Wraps the file at `maxBytes` bytes.  Must be an even number of bytes.
extern void BNCLogSetOutputToURLByteWrap(NSURL*_Nullable URL, long maxBytes);

typedef void (*BNCLogFlushFunctionPtr)(void);

///@param flushFunction The logging functions use `flushFunction` to flush the outstanding log
///                     messages to the output function.  For instance, this function may call
///                     `fsync` to assure that the log messages are written to disk.
extern void BNCLogSetFlushFunction(BNCLogFlushFunctionPtr _Nullable flushFunction);

///@return Returns the current flush function.
extern BNCLogFlushFunctionPtr _Nullable BNCLogFlushFunction(void);

#pragma mark - BNCLogWriteMessage

/// The main logging function used in the variadic logging defines.
extern void BNCLogWriteMessageFormat(
    BNCLogLevel logLevel,
    const char*_Nullable sourceFileName,
    int32_t sourceLineNumber,
    NSString*_Nullable messageFormat,
    ...
) NS_FORMAT_FUNCTION(4,5);

/// Swift-friendly wrapper for BNCLogWriteMessageFormat
extern void BNCLogWriteMessage(
    BNCLogLevel logLevel,
    NSString*_Nonnull sourceFileName,
    int32_t sourceLineNumber,
    NSString*_Nonnull message
);

/// This function synchronizes all outstanding log messages and writes them to the logging function
/// set by BNCLogSetOutputFunction.
extern void BNCLogFlushMessages(void);

///@return  Returns an NSString indicating the name of the enclosing method.
#define BNCSStringForCurrentMethod() \
    NSStringFromSelector(_cmd)

///@return  Returns an NSString indicating the name of the enclosing function.
#define BNCSStringForCurrentFunction() \
    [NSString stringWithFormat:@"%s", __FUNCTION__]

#pragma mark - Logging
///@info Logging

///@param format Log an info message with the specified formatting.
#define BNCLogDebugSDK(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelDebugSDK, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a debug message with the specified formatting.
#define BNCLogDebug(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelDebug, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a warning message with the specified formatting.
#define BNCLogWarning(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelWarning, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log an error message with the specified formatting.
#define BNCLogError(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelError, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a message with the specified formatting.
#define BNCLog(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelLog, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///Check that an asserting is true logging a message if the assertion fails.
#define BNCLogAssertWithMessage(condition, ...) \
    do  { \
        if (!(condition)) { \
            NSString *m = [NSString stringWithFormat:__VA_ARGS__]; \
            BNCLogWriteMessageFormat(BNCLogLevelAssert, __FILE__, __LINE__, \
                @"Assertion failed! Set 'BranchAssert' as a symbolic break point to catch this error."); \
            BNCLogWriteMessageFormat(BNCLogLevelAssert, __FILE__, __LINE__, @"(%s) !!! %@", #condition, m); \
            @try { \
                BNCLogFlushMessages(); \
                [NSException raise:@"BranchAssert" format:@"Branch assertion failed!"]; \
            } \
            @catch (id e) { \
            } \
        } \
    } while (0)

///Check that an assertion is true.
#define BNCLogAssert(condition) \
    BNCLogAssertWithMessage(condition, @"")

///Write the name of the current method to the log.
#define BNCLogMethodName() \
    BNCLogDebugSDK(@"Method '%@'.",  NSStringFromSelector(_cmd))

///Write the name of the current function to the log.
#define BNCLogFunctionName() \
    BNCLogDebugSDK(@"Function '%s'.", __FUNCTION__)

#ifdef __cplusplus
}
#endif
