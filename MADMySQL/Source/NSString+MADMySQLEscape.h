//
//  NSString+MADMySQLEscape.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_NSString_MADMySQLEscape_h
#define MAD_NSString_MADMySQLEscape_h

#import <Foundation/NSString.h>

@class MADMySQLConnection;

/*
	Escapes a string with the connection's current character set, ready to be
	embedded in a statement the connection will run.
 */
@interface NSString (MADMySQLEscape)

	- (NSString *)mysqlEscapeInConnection:(MADMySQLConnection *)connection;

@end

#endif
