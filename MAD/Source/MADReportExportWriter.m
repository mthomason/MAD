//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportExportWriter.m
//  MAD
//
//  See MADReportExportWriter.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportExportWriter.h"

#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSFileHandle.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>

#import <MADFoundation/madlog.h>

#import <stdio.h>

@implementation MADReportExportWriter

+ (BOOL)writeString:(NSString *)string toURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error {
	NSData *data = [string dataUsingEncoding: NSUTF8StringEncoding];
	if (data == nil) {
		if (error) *error = [NSError errorWithDomain: @"MADReportExport"
											   code: 1
										   userInfo: @{ NSLocalizedDescriptionKey: @"The export could not be encoded as UTF-8." }];
		return NO;
	}
	return [self writeData: data toURL: url error: error];
}

+ (BOOL)writeData:(NSData *)data toURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error {

	if (url == nil) {
		// A stream, not a file: the standard output of a spawned CLI is the caller's
		// pipe, and writing it whole is one call either way.
		if (data.length > 0) {
			[[NSFileHandle fileHandleWithStandardOutput] writeData: data];
		}
		return YES;
	}

	NSError *writeError = nil;
	if (![data writeToURL: url options: NSDataWritingAtomic error: &writeError]) {
		if (error) *error = writeError;
		os_log_error(OS_LOG_DEFAULT, "Error: %s", writeError.localizedDescription.UTF8String);
		return NO;
	}
	return YES;
}

@end
