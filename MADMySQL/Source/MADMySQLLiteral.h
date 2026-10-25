//
//  MADMySQLLiteral.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLLiteral_h
#define MAD_MADMySQLLiteral_h

#import <Foundation/NSObject.h>

/*
	A string that is inserted into a statement verbatim, without escaping --
	the caller vouches for it.
 */
@interface MADMySQLLiteral : NSObject

	@property(nonatomic, readonly) NSString *string;

	+ (MADMySQLLiteral *)literalWithString:(NSString *)s;

@end

#endif
