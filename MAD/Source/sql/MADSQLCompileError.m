//
//  MADSQLCompileError.m
//  MAD
//
//  Copyright © 2026 Everyday Apps LLC. All rights reserved.
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
