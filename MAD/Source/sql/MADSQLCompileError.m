//
//  MADSQLCompileError.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSQLCompileError.h"

NSString * const MADSQLCompileErrorDomain = @"MADSQLCompileErrorDomain";
NSString * const MADSQLCompileErrorLineKey = @"MADSQLCompileErrorLine";
NSString * const MADSQLCompileErrorColumnKey = @"MADSQLCompileErrorColumn";

@implementation MADSQLCompileError

+ (NSError *)errorWithCode:(MADSQLCompileErrorCode)code
					  line:(NSInteger)line
					column:(NSInteger)column
				   message:(NSString *)message {
	return [NSError errorWithDomain:MADSQLCompileErrorDomain
							   code:code
						   userInfo:@{ NSLocalizedDescriptionKey: message,
									   MADSQLCompileErrorLineKey: @(line),
									   MADSQLCompileErrorColumnKey: @(column) }];
}

@end
