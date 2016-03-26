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
#import <MADFoundation/MTDataColumn.h>
#import <MADCocoaExtensions/MTLog.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSKeyValueCoding.h>
#import "MTQuery.h"
#import "MTDatabaseSqlite3.h"

@interface MTDataTableFastObjectEnumerator ()

@property (atomic, assign) sqlite3_stmt *statement;
@property (atomic, assign) bool empty;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *columnKeys;

@property (nonatomic, strong) MTDatabaseCache *databaseForQuery;
@property (nonatomic, strong) NSMutableArray *fastEnumerationObjects;

@end

@implementation MTDataTableFastObjectEnumerator

void sqliteCallback(void *foo, const char* statement);
void sqliteCallback(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}

- (void)dealloc {
    sqlite3_finalize(_statement);
    _databaseForQuery = nil;
}

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection columns:(NSDictionary *)columns columnKeys:(NSArray *)columnKeys query:(MTQuery *)query {
    self = [super init];
    if (self) {
        
        NSMutableArray *fastEnumerationObjects = [[NSMutableArray alloc] init];
        self.fastEnumerationObjects = fastEnumerationObjects;

        MTDatabaseCache *database = [MTDatabaseCache newDatabaseWithConnection:databaseConnection];
        self.databaseForQuery = database;

        self.empty = columnKeys.count == 0;
        if (!self.empty) {
            self->_statement = NULL;
            NSString *sql = [query getSqlWithError:nil];
            char *queryString = sqlite3_mprintf(sql.UTF8String);
            sqlite3_prepare_v2(self.databaseForQuery.databaseHandle, queryString, -1, &_statement, NULL);
            sqlite3_free(queryString);
        }
        
        NSArray *retainedColumKeys = [NSArray arrayWithArray:columnKeys];
        self.columnKeys = retainedColumKeys;
        
        NSDictionary *retainedColumns = [NSDictionary dictionaryWithDictionary:columns];
        self.columns = retainedColumns;
        self.addRowId = YES;
        self.singleColumnNoWrapper = NO;

    }
    return self;
}

- (NSArray *)allObjects {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    if (!self.empty) {
        while (sqlite3_step(_statement) == SQLITE_ROW) {
            NSDictionary *newObject = [NSDictionary dictionaryWithDictionary: self.currentObject];
            [results addObject:newObject];
        }
    }
    return results;
}

- (id)nextObject {
    BOOL success;
    if (!self.empty) {
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

- (id)currentObject {
    NSMutableDictionary *currentObject = self.singleColumnNoWrapper ?
                                            nil : [[NSMutableDictionary alloc] initWithCapacity:self.columns.count];
    int columnCounter = 0;
    id columnValue;
    for (id key in self.columnKeys) {
        
        @autoreleasepool {
            
            MTDataColumn *dataColumn = self.columns[key];
            
            int sqlite3DataType = sqlite3_column_type(_statement, columnCounter);
            if (sqlite3DataType == SQLITE_NULL) {
                columnValue = [NSNull null];
            } else {
                columnValue = [MTDatabaseSqlite3 valueForStatement:_statement columnNumber:columnCounter];
            }
            
            if (columnValue == nil) {
                columnValue = [NSNull null];
            }
            if (columnValue != nil && self.singleColumnNoWrapper == NO) {
                [currentObject setValue:columnValue forKey:dataColumn.identifier];
            }
            columnCounter++;

        }
    }
    if (self.addRowId && self.singleColumnNoWrapper == NO && sqlite3_column_count(_statement) >= columnCounter) {
        NSNumber *rowid = @(sqlite3_column_int(_statement, columnCounter));
        [currentObject setValue:rowid forKey:MADIdentifierROWID];
    }
    return self.singleColumnNoWrapper ? columnValue : currentObject;
}

@end
