//
//  MTDataTableFastObjectEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTableFastObjectEnumerator.h"
#import "MTDatabaseCache.h"
#import "MTDatabaseConnection.h"
#import "MTDataColumn.h"
#import "libSqlite3_8.h"
#import "MTQuery.h"
#import "MTLog.h"
#import "MTDatabaseSqlite3.h"

@interface MTDataTableFastObjectEnumerator ()

@property (assign) sqlite3_stmt *statement;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *columnKeys;
@property (assign) BOOL empty;

@property (nonatomic, strong) MTDatabaseCache *databaseForQuery;

@end

@implementation MTDataTableFastObjectEnumerator

- (void)dealloc {
    sqlite3_finalize(_statement);
    _databaseForQuery = nil;
}

- (id)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection columns:(NSDictionary *)columns columnKeys:(NSArray *)columnKeys query:(MTQuery *)query {
    self = [super init];
    if (self) {

        MTDatabaseCache *database = [MTDatabaseCache databaseFactory:databaseConnection];
        [self setDatabaseForQuery:database];

        NSUInteger numberOfColumns = [columnKeys count];
        BOOL empty = numberOfColumns == 0;
        [self setEmpty:empty];
        if (!empty) {
            self->_statement = NULL;
            NSString *sql = [query getSqlWithError:nil];
            const char *queryStringConstChar = [sql UTF8String];
            char *queryString = sqlite3_mprintf((char *) queryStringConstChar);
            sqlite3_prepare_v2([[self databaseForQuery] databaseHandle], queryString, -1, &_statement, NULL);
            sqlite3_free(queryString);
        }
        [self setColumnKeys:columnKeys];
        [self setColumns:columns];
        [self setAddRowId:YES];
        [self setSingleColumnNoWrapper:NO];

    }
    return self;
}

void sqliteCallback(void *foo, const char* statement);
void sqliteCallback(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}

- (NSArray *)allObjects {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    if ([self empty] == NO) {
        while (sqlite3_step(_statement) == SQLITE_ROW) {
            NSDictionary *newObject = [NSDictionary dictionaryWithDictionary:[self currentObject]];
            [results addObject:newObject];
        }
    }
    return results;
}

- (id)nextObject {
    BOOL success;
    if ([self empty] == NO) {
        success = sqlite3_step(_statement) == SQLITE_ROW;
    } else {
        success = NO;
    }
    return success ? [self currentObject] : nil;
}

- (id)currentObject {
    NSMutableDictionary *currentObject = [self singleColumnNoWrapper] ? nil : [[NSMutableDictionary alloc] initWithCapacity:[[self columns] count]];
    int columnCounter = 0;
    id columnValue;
    for (id key in [self columnKeys]) {
        
        @autoreleasepool {
            
            
            MTDataColumn *dataColumn = [self columns][key];
            
            int sqlite3DataType = sqlite3_column_type(_statement, columnCounter);
            if (sqlite3DataType == SQLITE_NULL) {
                columnValue = [NSNull null];
            } else {
                
                MTDataType madDataType = [[dataColumn columnType] integerValue];
                columnValue = [MTDatabaseSqlite3 object:_statement forColumnNumber:columnCounter withType:madDataType];
            }
            
            if (columnValue == nil) {
                columnValue = [NSNull null];
            }
            if (columnValue != nil && self.singleColumnNoWrapper == NO) {
                [currentObject setValue:columnValue forKey:[dataColumn identifier]];
            }
            columnCounter++;

        }
    }
    if (self.addRowId && self.singleColumnNoWrapper == NO && sqlite3_column_count(_statement) >= columnCounter) {
        NSNumber *rowid = @(sqlite3_column_int(_statement, columnCounter));
        [currentObject setValue:rowid forKey:@"ROWID"];
    }
    return self.singleColumnNoWrapper ? columnValue : currentObject;
}

@end
