//
//  MADMySQLTruncate.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLTruncate_h
#define MAD_MADMySQLTruncate_h

#import <Foundation/NSObject.h>

@class MADMySQLConnection;

/*
	Empties one table with TRUNCATE.
 */
@interface MADMySQLTruncate : NSObject

	@property(nonatomic, copy) NSString *tableName;

	+ (MADMySQLTruncate *)truncateWithConnection:(MADMySQLConnection *)aConnection;
	+ (MADMySQLTruncate *)truncateWithConnection:(MADMySQLConnection *)aConnection forTable:(NSString *)aTableName;
	- (void)execute;

@end

#endif
