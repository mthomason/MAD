//
//  MADDataTableSingleColumnEnumerator.m
//  MADSqlite3
//
//  Created by Michael on 5/9/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADDataTableSingleColumnEnumerator.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSKeyValueCoding.h>

#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MADQuery.h>

#import <MADSqlite3/sqlite3.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

@interface MADDataTableSingleColumnEnumerator ()

@property (nonatomic, strong) NSDictionary <NSString *, MADDataColumn *> *columns;
@property (nonatomic, strong) NSArray <NSString *> *columnKeys;

@property (nonatomic, strong) MADDatabaseSqlite3 *databaseForQuery;
@property (nonatomic, strong) NSMutableArray *fastEnumerationObjects;

@end

@implementation MADDataTableSingleColumnEnumerator {
	sqlite3_stmt *_statement;
	BOOL _empty;
}

- (void)dealloc {
	sqlite3_finalize(_statement);
	[_fastEnumerationObjects removeAllObjects];
	_databaseForQuery = nil;
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection
								   columns:(NSDictionary <NSString *, MADDataColumn *> *)columns
								columnKeys:(NSArray <NSString *> *)columnKeys
									 query:(MADQuery *)query {
	if (self = [super init]) {
		
		NSMutableArray *fastEnumerationObjects = [[NSMutableArray alloc] init];
		self.fastEnumerationObjects = fastEnumerationObjects;
		
		MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
		[database setDatabaseConnection:databaseConnection];
		[database openDatabase];
		self.databaseForQuery = database;
		
		_empty = columnKeys.count == 0;
		if (!_empty) {
			self->_statement = NULL;
			NSString *sql = [query getSql:nil];
			char *queryString = sqlite3_mprintf(sql.UTF8String);
			sqlite3_prepare_v2(self.databaseForQuery->_database, queryString, -1, &_statement, NULL);
			sqlite3_free(queryString);
		}
		
		NSArray <NSString *> *retainedColumKeys = [[NSArray alloc] initWithArray:columnKeys];
		self.columnKeys = retainedColumKeys;
		
		NSDictionary *retainedColumns = [[NSDictionary alloc] initWithDictionary:columns];
		self.columns = retainedColumns;
		
	}
	return self;
}

- (NSArray *)allObjects {
	NSMutableArray *results = [[NSMutableArray alloc] init];
	if (!_empty) {
		while (sqlite3_step(_statement) == SQLITE_ROW) {
			[results addObject:self.currentObject];
		}
	}
	return results;
}

- (id)nextObject {
	BOOL success;
	if (!_empty) {
		success = sqlite3_step(_statement) == SQLITE_ROW;
	} else {
		success = NO;
	}
	return success ? [self currentObject] : nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained *)stackbuf
									count:(NSUInteger)len {
	
	NSUInteger i = 0;
	int stepResult;
	
	if(state->state == 0) {
		state->state = 1;
		state->mutationsPtr = &state->extra[0];
		sqlite3_reset(_statement);
	}
	
	if (state->state != 2) {
		state->itemsPtr = stackbuf;
		
		[self.fastEnumerationObjects removeAllObjects];
		
		for (i = 0; i<len; i++) {
			@autoreleasepool {
				stepResult = sqlite3_step(_statement);
				if (stepResult == SQLITE_ROW) {
					id co = [self currentObject];
					if (co) {
						stackbuf[i] = co;
						[self.fastEnumerationObjects addObject:co];
					} else {
						stackbuf[i] = nil;
					}
					co = nil;
				} else if (stepResult == SQLITE_DONE) {
					sqlite3_reset(_statement);
					stackbuf[i] = nil;
					state->state = 2;
					break;
				} else {
					sqlite3_reset(_statement);
					stackbuf[i] = nil;
					state->state = 2;
					break;
				}
			}
		}
	}
	return i;
}

- (__kindof NSObject <NSCopying, NSSecureCoding> *)currentObject {
	return [MADDatabaseSqlite3 databaseResultValue:_statement columnNumber:0];
}

@end
