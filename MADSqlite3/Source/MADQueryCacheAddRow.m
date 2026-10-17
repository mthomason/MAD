//
//  MADQueryCacheAddRow.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryCacheAddRow.h"

#import <stdio.h>
#import <string.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>

#import <MADFoundation/madlib.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseDataBinding.h>

// FIXME: Remove dependency on MADDatabaseSqlite3
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import "MADQueryCacheAddRowParameters.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>

#import <MADAPI/MADQueryType.h>

static NSString * const SqlDelimitor = @", ";
static NSString * const SqlDelimitorObject = @", %@";

@interface MADQueryCacheAddRow ()

@end

@implementation MADQueryCacheAddRow {
	NSString *_sql;
	NSString *_sqlColumnPart;
}

@synthesize binaryBindings = _binaryBindings;

- (void)update {

	// -update runs once per row of a bulk insert, so the array is kept and emptied rather
	// than replaced: a fresh one per row is one more allocation in the row loop, and the
	// removeAllObjects below already showed that reusing it was the intent.
	NSMutableArray *binaryBindings = self.binaryBindings;
	if (binaryBindings == nil) {
		binaryBindings = [[NSMutableArray alloc] init];
		self.binaryBindings = binaryBindings;
	}

	id <MADQueryParametersStandardProtocol,
		MADQueryParametersColumnKeysProtocol,
		MADQueryParametersColumnMetaProtocol,
		MADQueryParametersColumnDataProtocol> delegate = _delegate;

	NSArray <NSString *> *columnKeys = [delegate queryColumnKeys];
	
	if (_sqlColumnPart == nil) {
		NSString *sqlColumnNames = [self columnNamesForKeys:columnKeys];
		_sqlColumnPart = [[NSString alloc] initWithString:sqlColumnNames];
	}

	[binaryBindings removeAllObjects];

	NSArray *rows = [delegate queryRowData];
	if (rows == nil) return;

	NSUInteger columnKeysCount = columnKeys.count;

	// The SQL below is built with "?" placeholders, so every column needs a
	// binding or sqlite3_step() runs with the parameters unbound and stores
	// NULL for each one.
	NSDictionary <NSString *, MADDataColumn *> *columns = [delegate queryColumns];
	for (NSUInteger columnCounter = 0; columnCounter < columnKeysCount; columnCounter++) {
		MADDataColumn *column = columns[columnKeys[columnCounter]];
		MADDataType datatype = column != nil ? column.type : MADDataTypeUnknown;
		id value = columnCounter < rows.count ? rows[columnCounter] : [NSNull null];

		MADDatabaseDataBinding *databinding = [[MADDatabaseDataBinding alloc] initWithDataType: datatype
																					fieldIndex: columnCounter
																						 value: value];
		[self.binaryBindings addObject: databinding];
	}

	// The statement is all "?" placeholders and the table and columns do not change under a
	// running insert, so it is built once.  Rebuilding it per row allocated an identical
	// string per row and threw it away: -insertRow: only reads it when it has to prepare,
	// which is the first row and never again.
	if (_sql == nil) {
		char buf[(count_digits_ul(columnKeysCount) + 3) * columnKeysCount + 1];
		buf[0] = '?';
		buf[1] = '\0';
		int buf_ptr = 1;
		for (NSUInteger columnCounter = 0; columnCounter < columnKeysCount; columnCounter++) {
			if (columnCounter > 0) {
				// The following line emits the message:
				// Call to function 'strcat' is insecure as it does not provide bounding of the memory buffer. Replace unbounded copy functions with analogous functions that support length arguments such as 'strlcat'. CWE-119
				strcat(buf, ", ?");
				buf_ptr += 3;
			}
			buf_ptr = buf_ptr + ultoa((unsigned int)columnCounter + 1, (buf+buf_ptr));
		}
		char *ptr = buf;
		_sql = [[NSString alloc] initWithFormat:@"INSERT INTO main.%@ (%@) VALUES (%s)", [delegate queryTableName], _sqlColumnPart, ptr];
	}
}

- (NSString *)columnNamesForKeys:(NSArray <NSString *> *)columnKeys {
	NSMutableString *colmunNames = [[NSMutableString alloc] init];
	NSUInteger columnCount = columnKeys.count;
	NSString *fieldName;
	for (NSUInteger columnCounter=0; columnCounter<columnCount; columnCounter++) {
		fieldName = columnKeys[columnCounter];
		
		MADSafeQueryField *safeFieldName = [MADDatabaseSqlite3 newSafeIdentifier:fieldName];
		if (columnCounter > 0) {
			[colmunNames appendFormat:SqlDelimitorObject, safeFieldName];
		} else {
			[colmunNames appendString:safeFieldName];
		}
		
	}
	return colmunNames;
}

- (instancetype)initWithObject:(id <MADQueryParametersStandardProtocol,
								MADQueryParametersColumnKeysProtocol,
								MADQueryParametersColumnMetaProtocol,
								MADQueryParametersColumnDataProtocol>)object {
	if (self = [super initWithObject:object]) {
		_delegate = object;
		[self update];
	}
	return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	if (_sql == nil) {
		[self update];
	}
	return _sql;
}

- (BOOL)returnsResults {
	return NO;
}

- (BOOL)partOfTransactionSet {
	return YES;
}

- (MADQueryType)type {
	return MADQueryTypeCacheAddRow;
}

@end
