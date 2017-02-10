//
//  MTQueryCacheAddRow.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryCacheAddRow.h"
#import <Foundation/NSArray.h>
#import <MADFoundation/MADDataColumn.h>
#import "MADDatabaseDataBinding.h"
#import "MADDatabaseConnection.h"

// FIXME: Remove dependency on MTDatabaseSqlite3
#import "MTDatabaseSqlite3.h"
#import "MADQueryCacheAddRowParameters.h"

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <stdio.h>
#import <string.h>
#import "madlib.h"

static NSString * const SqlDelimitor = @", ";
static NSString * const SqlDelimitorObject = @", %@";

@interface MTQueryCacheAddRow ()

@end

@implementation MTQueryCacheAddRow {
    NSString *_sql;
    NSString *_sqlColumnPart;
}

- (void)update {

    id <MADQueryParametersStandardProtocol,
        MADQueryParametersColumnKeysProtocol,
        MADQueryParametersColumnMetaProtocol,
        MADQueryParametersColumnDataProtocol> delegate = _delegate;

    NSArray <NSString *> *columnKeys = [delegate queryColumnKeys];
    
    if (_sqlColumnPart == nil) {
        NSString *sqlColumnNames = [self columnNamesForKeys:columnKeys];
        _sqlColumnPart = [[NSString alloc] initWithString:sqlColumnNames];
    }

    NSArray *rows = [delegate queryRowData];
    if (rows == nil) return;
    
    [self.binaryBindings removeAllObjects];
    NSUInteger columnKeysCount = columnKeys.count;
    char buf[(count_digits_ul(columnKeysCount) + 3) * columnKeysCount + 1];
    buf[0] = '?';
    buf[1] = '\0';
    int buf_ptr = 1;
    for (NSUInteger columnCounter = 0; columnCounter < columnKeysCount; columnCounter++) {
        if (columnCounter > 0) {
            strcat(buf, ", ?");
            buf_ptr += 3;
        }
        buf_ptr = buf_ptr + ultoa((unsigned int)columnCounter + 1, (buf+buf_ptr));
    }
    char *ptr = buf;
    _sql = [[NSString alloc] initWithFormat:@"INSERT INTO main.%@ (%@) VALUES (%s)", [delegate queryTableName], _sqlColumnPart, ptr];
}

- (NSString *)columnNamesForKeys:(NSArray <NSString *> *)columnKeys {
    NSMutableString *colmunNames = [[NSMutableString alloc] init];
    NSUInteger columnCount = columnKeys.count;
    NSString *fieldName;
    for (NSUInteger columnCounter=0; columnCounter<columnCount; columnCounter++) {
        fieldName = columnKeys[columnCounter];
        
        MADSafeQueryField *safeFieldName = [MTDatabaseSqlite3 newSafeIdentifier:fieldName];
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

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    if (_sql == nil) {
        [self update];
    }
    return _sql;
}

- (BOOL)returnsResults {
    return NO;
}

- (BOOL)partOfTransactionSet {
    return YES;  //Can't use YES here, because insert is bound with different values on each run.
}

- (MADQueryType)type {
    return MADQueryTypeCacheAddRow;
}

@end
