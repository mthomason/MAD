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
#import "MTDatabase.h"
#import "MTDatabaseConnection.h"
#import "MTDataColumn.h"
#import "libSqlite3_8.h"

@interface MTDataTableFastObjectEnumerator ()

@property (assign) sqlite3 *database;
@property (assign) sqlite3_stmt *statement;
@property (nonatomic, strong) NSDictionary *columns;
@property (nonatomic, strong) NSArray *columnKeys;
@property (assign) BOOL empty;

@end

@implementation MTDataTableFastObjectEnumerator

- (void)dealloc {
    sqlite3_finalize(_statement);
    sqlite3_close_v2(_database);
}

- (id)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection columns:(NSDictionary *)columns columnKeys:(NSArray *)columnKeys sql:(NSString *)sql {
    self = [super init];
    if (self) {
        
        NSUInteger numberOfColumns = [columnKeys count];
        BOOL empty = numberOfColumns == 0;
        [self setEmpty:empty];
        if (!empty) {
            _statement = NULL;
            const char *path = [[[databaseConnection databaseUrl] path] UTF8String];
            
            
            BOOL success = sqlite3_open_v2(path, &_database, SQLITE_OPEN_READONLY | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX, NULL) == SQLITE_OK;
            if (success == NO) {
                const char *errorMessage = sqlite3_errmsg(_database);
                NSString *message = [NSString stringWithUTF8String: errorMessage];
                NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
                NSLog(@"%@ %@", message, title);
            }
            success = sqlite3_extended_result_codes(_database, true) == SQLITE_OK;
            
            
            const char *queryStringConstChar = [sql UTF8String];
            char *queryString = sqlite3_mprintf((char *) queryStringConstChar);
            success = sqlite3_prepare_v2(_database, queryString, -1, &_statement, NULL) == SQLITE_OK;
            if (success == NO) {
                const char *errorMessage = sqlite3_errmsg(_database);
                NSString *message = [NSString stringWithUTF8String: errorMessage];
                NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
                NSLog(@"%@ %@", message, title);
            }
            sqlite3_free(queryString);
        }
        
        [self setColumnKeys:columnKeys];
        [self setColumns:columns];

    }
    return self;
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
    NSDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:[[self columns] count]];
    int columnCounter = 0;
    for (id key in [self columnKeys]) {
        MTDataColumn *dataColumn = [self columns][key];
        id columnValue;
        switch ([[dataColumn columnType] integerValue]) {
            case MTDataTypeInteger:
                columnValue = [NSNumber numberWithLongLong:sqlite3_column_int64(_statement, columnCounter)];
                break;
            case MTDataTypeBlob: {
                const void *blob = sqlite3_column_blob(_statement, columnCounter);
                if (blob == NULL) {
                    columnValue = nil;
                } else {
                    int bytes = sqlite3_column_bytes(_statement, columnCounter);
                    columnValue = [NSData dataWithBytes: blob
                                                 length: bytes];
                }
                break;
            }
            case MTDataTypeFloat:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(_statement, columnCounter)];
                break;
            case MTDataTypeDouble:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(_statement, columnCounter)];
                break;
            case MTDataTypeDecimal:
                columnValue = [NSNumber numberWithDouble:sqlite3_column_double(_statement, columnCounter)];
                break;
            case MTDataTypeString: {
                const unsigned char *text = sqlite3_column_text(_statement, columnCounter);
                if (text == NULL) {
                    columnValue = [NSNull null];
                } else {
                    columnValue = [NSString stringWithUTF8String:(const char *) text];
                }
                break;
            }
            default: {
                if (sqlite3_column_type(_statement, columnCounter) == SQLITE_TEXT) {
                    const unsigned char *text = sqlite3_column_text(_statement, columnCounter);
                    if (text == NULL) {
                        columnValue = [NSNull null];
                    } else {
                        columnValue = [NSString stringWithUTF8String:(const char *) text];
                    }
                }
                break;
            }
        }
        if (columnValue != nil) {
            [currentObject setValue:columnValue forKey:[dataColumn identifier]];
        }
        columnCounter++;
    }
    return currentObject;
}

@end
