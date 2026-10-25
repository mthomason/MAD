//
//  NSString+MADMySQLEscape.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "NSString+MADMySQLEscape.h"

#import "MADMySQLConnection.h"

#import <Foundation/NSString.h>

@implementation NSString (MADMySQLEscape)

- (NSString *)mysqlEscapeInConnection:(MADMySQLConnection *)connection {
	return [connection mysqlEscapeString:self];
}

@end
