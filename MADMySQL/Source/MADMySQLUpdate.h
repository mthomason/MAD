//
//  MADMySQLUpdate.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLUpdate_h
#define MAD_MADMySQLUpdate_h

#import <Foundation/NSObject.h>

@class MADMySQLConnection;

/*
	Runs one UPDATE as a prepared statement. rowData maps the columns to set;
	qualifier maps the WHERE columns to values (strings are escaped and
	quoted, numbers go in raw, NSNull becomes IS NULL).
 */
@interface MADMySQLUpdate : NSObject

	@property(nonatomic, strong) NSString *table;
	@property(nonatomic, strong) NSDictionary *rowData;
	@property(nonatomic, strong) NSDictionary *qualifier;
	@property(nonatomic, readonly) NSNumber *affectedRows;

	+ (MADMySQLUpdate *)updateWithConnection:(MADMySQLConnection *)aConnection;
	- (void)execute;

@end

#endif
