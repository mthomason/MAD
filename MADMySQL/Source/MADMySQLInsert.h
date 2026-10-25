//
//  MADMySQLInsert.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLInsert_h
#define MAD_MADMySQLInsert_h

#import <Foundation/NSObject.h>

@class MADMySQLConnection;

/*
	Runs one INSERT as a prepared statement. rowData maps column names to
	values (NSString, NSData, NSNumber or NSNull); execute binds them and
	reports the affected-row count and the new row id.
 */
@interface MADMySQLInsert : NSObject

	@property(nonatomic, readwrite, assign) BOOL ignoreDuplicateErrors;

	@property(nonatomic, readwrite, copy) NSString *table;
	@property(nonatomic, readwrite, copy) NSDictionary *rowData;
	@property(nonatomic, readonly, strong) NSNumber *affectedRows;
	@property(nonatomic, readonly, strong) NSNumber *rowid;

	+ (MADMySQLInsert *)insertWithConnection:(MADMySQLConnection *)aConnection;
	- (void)execute;

@end

#endif
