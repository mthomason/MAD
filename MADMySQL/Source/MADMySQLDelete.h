//
//  MADMySQLDelete.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLDelete_h
#define MAD_MADMySQLDelete_h

#import <Foundation/NSObject.h>

@class MADMySQLConnection;

/*
	Runs one DELETE with a literal WHERE clause. The qualifier is the caller's
	SQL fragment, inserted verbatim; a delete without one is refused.
 */
@interface MADMySQLDelete : NSObject

	@property(nonatomic, copy) NSString *tableName;
	@property(nonatomic, copy) NSString *qualifier;
	@property(nonatomic, readonly) NSNumber *affectedRows;

	+ (MADMySQLDelete *)deleteWithConnection:(MADMySQLConnection *)aConnection;
	- (void)execute;

@end

#endif
