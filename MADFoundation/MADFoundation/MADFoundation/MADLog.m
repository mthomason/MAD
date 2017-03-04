//
//  MADLog.m
//  MADFoundation
//
//  Created by Michael on 10/19/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLog.h"
#import <asl.h>
#import <Foundation/NSBundle.h>

aslmsg mad_log_next(aslresponse response);
void mad_log_free(aslresponse response);

MADLogLevel MADCurrentLogLevel = MADLogLevelInfo;

#if TARGET_OS_IPHONE
  #if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_6_1 && __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_7_1
    #define MADLogAlsModern 1
  #endif
#else
  #if __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_9
    #define MADLogAlsModern 1
  #endif
#endif

#if DEBUG

  MADLogBlock MADLogHandler = ^(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber,
                                NSString *methodName, NSString *format, ...) {
	va_list args;
	va_start(args, format);
	MADLogMessagev(logLevel, format, args);
	
	va_end(args);
  };

#else
  MADLogBlock MADLogHandler = NULL;
#endif

void MADLogSetLogLevel(MADLogLevel logLevel) {
	MADCurrentLogLevel = logLevel;
}

void MADLogMessagev(MADLogLevel logLevel, NSString *format, va_list args) {
	NSString *facility = [[NSBundle mainBundle] bundleIdentifier];
	aslclient client = asl_open(NULL, [facility UTF8String], ASL_OPT_STDERR);
	aslmsg msg = asl_new(ASL_TYPE_MSG);
	asl_set(msg, ASL_KEY_READ_UID, "-1");
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	asl_log(client, msg, logLevel, "%s", [message UTF8String]);
	asl_free(msg);
	va_end(args);
}

void MADLogMessage(MADLogLevel logLevel, NSString *format, ...) {
	va_list args;
	va_start(args, format);
	MADLogMessagev(logLevel, format, args);
	va_end(args);
}

NSArray *MADLogGetMessages(void) {

    aslmsg query, message;
	
	const char *key, *val;
	
	NSString *facility = [[NSBundle mainBundle] bundleIdentifier];
	
	query = asl_new(ASL_TYPE_QUERY);
	
	asl_set_query(query, ASL_KEY_FACILITY, [facility UTF8String], ASL_QUERY_OP_EQUAL);
	
	aslresponse response = asl_search(NULL, query);
	
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
	
    while ((message = mad_log_next(response))) {
        
		NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
		
		for (unsigned int i = 0; ((key = asl_key(message, i))); i++) {
			NSString *keyString = [NSString stringWithUTF8String:(char *)key];
			
			val = asl_get(message, key);
			
			NSString *string = val ? [[NSString alloc] initWithUTF8String:val] : @"";
			[tmpDict setObject:string forKey:keyString];
		}
		
		[tmpArray addObject:tmpDict];
	}
	
	asl_free(query);
    mad_log_free(response);
	
	if (tmpArray.count) return [tmpArray copy];	
	
	return nil;
}

void mad_log_free(aslresponse response) {
    #if MADLogAlsModern
      asl_release(response);
    #else
      aslresponse_free(response);
    #endif
}

aslmsg mad_log_next(aslresponse response) {
    aslmsg msg;
    #if MADLogAlsModern
      msg = asl_next(response);
    #else
      msg = aslresponse_next(response);
    #endif
    return msg;
}
