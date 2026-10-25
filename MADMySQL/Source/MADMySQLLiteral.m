//
//  MADMySQLLiteral.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLLiteral.h"

#import <Foundation/NSString.h>

@interface MADMySQLLiteral ()

	@property(nonatomic, copy, readwrite) NSString *string;

@end

@implementation MADMySQLLiteral

+ (MADMySQLLiteral *)literalWithString:(NSString *)s {
	MADMySQLLiteral *literal = [[self alloc] init];
	literal.string = [s copy];
	return literal;
}

@end
