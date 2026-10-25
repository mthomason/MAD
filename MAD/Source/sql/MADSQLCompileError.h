//
//  MADSQLCompileError.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The one error shape the pasted-SQL front half reports (docs/project/MAD_SQL_ENTRY.md §5):
//  a coded NSError whose userInfo carries the offending token's 1-based
//  position, so every rejection names the construct, the clause and the reason,
//  and tests assert codes and positions rather than message text.
//

#ifndef MAD_MADSQLCompileError_h
#define MAD_MADSQLCompileError_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const MADSQLCompileErrorDomain;

/// userInfo keys (NSNumber): the 1-based line and column of the offending token.
FOUNDATION_EXPORT NSString * const MADSQLCompileErrorLineKey;
FOUNDATION_EXPORT NSString * const MADSQLCompileErrorColumnKey;

/// One code per rejected construct, so the UI can present each model limitation
/// without matching message text.
typedef NS_ENUM(NSInteger, MADSQLCompileErrorCode) {
	MADSQLCompileErrorNone = 0,
	MADSQLCompileErrorSyntax = 1,
	MADSQLCompileErrorUnsupportedOR = 2,
	MADSQLCompileErrorUnsupportedIN = 3,
	MADSQLCompileErrorUnsupportedLIKE = 4,
	MADSQLCompileErrorUnsupportedBETWEEN = 5,
	MADSQLCompileErrorUnsupportedNOT = 6,
	MADSQLCompileErrorUnsupportedSubquery = 7,
	MADSQLCompileErrorUnsupportedUNION = 8,
	MADSQLCompileErrorUnsupportedDISTINCT = 9,
	MADSQLCompileErrorUnsupportedExpression = 10,
	MADSQLCompileErrorUnsupportedOnCondition = 11,
	MADSQLCompileErrorUnsupportedAlias = 12,
	MADSQLCompileErrorUnsupportedCommaJoin = 13,
	MADSQLCompileErrorUnsupportedNaturalCrossJoin = 14,
	MADSQLCompileErrorUnsupportedLIMIT = 15,
	MADSQLCompileErrorUnknownTable = 16,
	MADSQLCompileErrorUnknownColumn = 17,
	MADSQLCompileErrorAmbiguousColumn = 18,
	MADSQLCompileErrorOrderByOutsideGroupBy = 19,
	MADSQLCompileErrorDuplicateJoin = 20,
	MADSQLCompileErrorUnsupportedSelectAlias = 21,
	/// The apply's conflict check: a designer element or a group section holds a
	/// field of a table the new plan drops (docs/project/MAD_SQL_ENTRY.md §6.3).
	MADSQLCompileErrorDesignerConflict = 22,
};

@interface MADSQLCompileError : NSObject

/// The one factory every failure goes through.
+ (NSError *)errorWithCode:(MADSQLCompileErrorCode)code
					  line:(NSInteger)line
					column:(NSInteger)column
				   message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END

#endif
