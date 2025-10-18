//
//  MADArrayCachingEnumerator.m
//  MADSqlite3
//
//  Created by Michael on 5/8/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADArrayCachingEnumerator.h"
#import <MADSqlite3/sqlite3.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import "MADDatabaseConnectionSqlite3.h"

NSString * const MTArrayCachedTableName = @"ac";
NSString * const MTArrayCachedColumnKey = @"ci";
NSString * const MTArrayCachedColumnValue = @"ck";
NSString * const MTArrayCachedExtension = @"madac";

@implementation MADArrayCachingEnumerator {
	sqlite3_stmt *_statementEnumer;
}

- (void)dealloc {
	sqlite3_finalize(_statementEnumer);
	_statementEnumer = NULL;
}

- (id)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		NSString *sql = [[NSString alloc] initWithFormat: @"SELECT %@ FROM %@ ORDER BY %@;",
						 MTArrayCachedColumnValue,
						 MTArrayCachedTableName,
						 MTArrayCachedColumnKey];
		MADDatabaseConnection *databaseConnection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:url];
		MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
		[database setDatabaseConnection:databaseConnection];
		[database openDatabase];
		int prepare_result = sqlite3_prepare_v2(database->_database, sql.UTF8String, -1,
												&_statementEnumer, NULL);
		NSAssert(prepare_result == SQLITE_OK,
				 @"sqlite3_prepare_v2 failed (%s).", (char *)sqlite3_errmsg(database->_database));
	}
	return self;
}

- (NSArray *)allObjects {
	
	NSMutableArray *results = [[NSMutableArray alloc] init];
	sqlite3_stmt *stmt_enum = _statementEnumer;
	NSData *queryResult;
	
	while (sqlite3_step(stmt_enum) == SQLITE_ROW) {
		
		const void *blob = sqlite3_column_blob(stmt_enum, 0);
		int bytes = sqlite3_column_bytes(stmt_enum, 0);
		
		queryResult = [[NSData alloc] initWithBytes: blob
											 length: (NSUInteger)bytes];
		id result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
		
		//NSError *error = nil;
		//id result = [NSKeyedUnarchiver unarchivedObjectOfClasses:self.types fromData:queryResult error:&error];
		//if (error != nil) {
		//	os_log_error(caching_log, "NSKeyedArchiver Error: %@", error.localizedDescription);
		//}
		
		
		[results addObject:result];
	}
	return results;
}

- (id)nextObject {
	__block id result = nil;
	sqlite3_stmt *stmt_enum = _statementEnumer;
	int stepResult;
	stepResult = sqlite3_step(stmt_enum);
	if (stepResult == SQLITE_ROW) {
		NSData *queryResult;
		queryResult = [[NSData alloc] initWithBytes: sqlite3_column_blob(stmt_enum, 0)
											 length: (NSUInteger)sqlite3_column_bytes(stmt_enum, 0)];
		result = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
	}
	sqlite3_reset(stmt_enum);
	return result;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained *)stackbuf
									count:(NSUInteger)len {
	
	NSUInteger i = 0;
	int stepResult;
	
	if(state->state == 0) {
		state->state = 1;
		state->mutationsPtr = &state->extra[0];
		sqlite3_reset(_statementEnumer);
	}
	
	if (state->state != 2) {
		state->itemsPtr = stackbuf;
		
		NSData *queryResult;
		
		for (i = 0; i<len; i++) {
			
			stepResult = sqlite3_step(_statementEnumer);
			if (stepResult == SQLITE_ROW) {
				const void *blob = sqlite3_column_blob(_statementEnumer, 0);
				int bytes = sqlite3_column_bytes(_statementEnumer, 0);
				
				queryResult = [[NSData alloc] initWithBytes: blob
													 length: (NSUInteger)bytes];
				id obj = [NSKeyedUnarchiver unarchiveObjectWithData:queryResult];
				stackbuf[i] = obj;
				
			} else if (stepResult == SQLITE_DONE) {
				sqlite3_reset(_statementEnumer);
				stackbuf[i] = nil;
				state->state = 2;
				break;
				
			} else {
				sqlite3_reset(_statementEnumer);
				stackbuf[i] = nil;
				state->state = 2;
				break;
				
			}
		}
	}
	return i;
}

@end
