//
//  MADOperationValidateSQL.h
//  MAD Designer
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The SQL entry feature's server probe (docs/project/MAD_SQL_ENTRY.md §7): the statement
//  wrapped as a zero-row derived table and run through the MADOperationRefresh
//  shape -- connect with credentials from operation dependencies, the driver's
//  executeSQL:…intoResultTable:… -- so the server's own name resolution and its
//  own errors come back.  Advisory: the probe never writes, and when the
//  database is unreachable or credentials are missing it skips, leaving the
//  structural check as the whole validation.
//

#ifndef MADDesigner_MADOperationValidateSQL_h
#define MADDesigner_MADOperationValidateSQL_h

#import <MADFoundation/MADOperation.h>
#import <MAD/MADDocumentDataProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class MADDatabase;

@interface MADOperationValidateSQL : MADOperation

/// `expectedColumns` maps each resolved select column's lowercase name to its
/// schema MADDataType; the server's columns are compared against it and
/// differences reported as warnings.
- (instancetype)initWithDocument:(id<MADDocumentDataProtocol>)document
					   statement:(NSString *)statement
			   expectedColumns:(NSDictionary<NSString *, NSNumber *> *)expectedColumns;

@property (nonatomic, readonly, weak) id<MADDocumentDataProtocol> document;
@property (nonatomic, readonly, copy) NSString *statement;

/// YES when the server answered the probe.
@property (nonatomic, readonly) BOOL probeRan;
/// YES when the probe could not run -- unreachable database or missing
/// credentials -- and the result is structural only.
@property (nonatomic, readonly) BOOL skipped;
/// One warning string per column the server reported differently from the
/// schema.  Warnings, never failures.
@property (nonatomic, readonly, copy) NSArray<NSString *> *warnings;

/// The §7 wrapper: `SELECT * FROM (<statement>) AS _mad_probe WHERE 1=0`.
/// `database` is the seam a future dialect would diverge at; today every
/// dialect uses the one form.  Nil for an empty statement.
+ (nullable NSString *)probeSQLForStatement:(NSString *)statement
								   database:(MADDatabase *)database;

@end

NS_ASSUME_NONNULL_END

#endif
