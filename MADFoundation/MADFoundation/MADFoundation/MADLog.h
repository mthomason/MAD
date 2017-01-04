//
//  MADLog.h
//  MADFoundation
//
//  Created by Michael on 10/19/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFoundation_MADLog_h
#define MADFoundation_MADLog_h

#import <objc/NSObjCRuntime.h>
#import <Foundation/Foundation.h>

@class NSString;

typedef void (^MADLogBlock)(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...);

extern MADLogBlock MADLogHandler;
extern NSUInteger MADCurrentLogLevel;

typedef NS_ENUM(NSUInteger, MADLogLevel) {
	MADLogLevelEmergency = 0,
	MADLogLevelAlert     = 1,
	MADLogLevelCritical  = 2,
	MADLogLevelError     = 3,
	MADLogLevelWarning   = 4,
	MADLogLevelNotice    = 5,
	MADLogLevelInfo      = 6,
	MADLogLevelDebug     = 7
};

void MADLogSetLoggerBlock(MADLogBlock handler);
void MADLogSetLogLevel(NSUInteger logLevel);
void MADLogMessagev(MADLogLevel logLevel, NSString *format, va_list args);
void MADLogMessage(MADLogLevel logLevel, NSString *format, ...);

NSArray *MADLogGetMessages(void);

#define MADLogEmergency(format, ...) MADLogCallHandlerIfLevel(MADLogLevelEmergency, format, ##__VA_ARGS__)
#define MADLogAlert(format, ...)     MADLogCallHandlerIfLevel(MADLogLevelAlert, format, ##__VA_ARGS__)
#define MADLogCritical(format, ...)  MADLogCallHandlerIfLevel(MADLogLevelCritical, format, ##__VA_ARGS__)
#define MADLogError(format, ...)     MADLogCallHandlerIfLevel(MADLogLevelError, format, ##__VA_ARGS__)
#define MADLogWarning(format, ...)   MADLogCallHandlerIfLevel(MADLogLevelWarning, format, ##__VA_ARGS__)
#define MADLogNotice(format, ...)    MADLogCallHandlerIfLevel(MADLogLevelNotice, format, ##__VA_ARGS__)
#define MADLogInfo(format, ...)      MADLogCallHandlerIfLevel(MADLogLevelInfo, format, ##__VA_ARGS__)
#define MADLogDebug(format, ...)     MADLogCallHandlerIfLevel(MADLogLevelDebug, format, ##__VA_ARGS__)
#define MADLogCallHandlerIfLevel(logLevel, format, ...) \
if (MADLogHandler && MADCurrentLogLevel>=logLevel) MADLogHandler(logLevel, MADLogSourceFileName, MADLogSourceLineNumber, MADLogSourceMethodName, format, ##__VA_ARGS__)

#define MADLogSourceFileName [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
#define MADLogSourceMethodName [NSString stringWithUTF8String:__PRETTY_FUNCTION__]
#define MADLogSourceLineNumber __LINE__

#endif /* MADLog_h */
