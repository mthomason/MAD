//
//  MTDatabaseSqlServer.m
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSqlServer.h"
#import "MTDatabaseConnectionSqlServer.h"
#import "MTDatabaseTable.h"
#import "MTQuery.h"
#import "MTKeyChain.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqQueryTable.H"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "sybdb.h"

#import "MTDatabaseProcessSqlServer.h"

#import "NSError+UserInterface.h"

#import "MTDataTable.h"
#import "MTDataColumn.h"
#import "UIApplication+Extras.h"

NSString * const MTDatabaseConnectionUsername   = @"MTDatabaseConnectionUsername";
NSString * const MTDatabaseConnectionPassword   = @"MTDatabaseConnectionPassword";
NSString * const MTDatabaseConnectionDatabase   = @"MTDatabaseConnectionDatabase";
NSString * const MTDatabaseConnectionPort       = @"MTDatabaseConnectionPort";
NSString * const MTDatabaseConnectionHost       = @"MTDatabaseConnectionHost";
NSString * const MTDatabaseConnectionServer     = @"MTDatabaseConnectionServer";
NSString * const MTDatabaseConnectionAppName    = @"MTDatabaseConnectionAppName";

@interface MTDatabaseSqlServer ()

@end

@implementation MTDatabaseSqlServer

- (void)getTablesFromConnection:(id)process completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    
    id results = nil;
    NSError *error = nil;
    DBPROCESS *dbconn = [process process];
    if (dbconn) {
        
        dbcmd(dbconn, "SELECT name FROM sys.tables");
        
        RETCODE success = dbsqlexec(dbconn);
        
        if (success != SUCCEED) {
            
            NSString *message = @"Sql Syntax Error";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            error = [NSError errorWithDomain:@"MTDatabaseTds" code:3 userInfo:errorInfo];
            
        }
        
        NSInteger numberOfColumns = dbnumcols(dbconn);
        
        results = [[NSMutableArray alloc] initWithCapacity: numberOfColumns];
        
        while (dbresults(dbconn) != NO_MORE_RESULTS) {
            
            //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
            DBINT columnLength      = dbcollen(dbconn, 1);
            char *sybVarCharBind;
            DBINT sybVarCharBindNull;
            
            sybVarCharBind = malloc( sizeof(char) * ( columnLength + 1 ) );
            dbbind(dbconn, 1, NTBSTRINGBIND, columnLength, (BYTE *)sybVarCharBind);
            dbnullbind(dbconn, 1, &sybVarCharBindNull);
            
            while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                
                if (sybVarCharBindNull != -1) {
                    if (sybVarCharBind != nil) {
                        NSString *tableName = [[NSString alloc] initWithCString: sybVarCharBind
                                                                       encoding: NSStringEncodingConversionAllowLossy];
                        MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                        [results addObject:table];
                    }
                }
            }
            free(sybVarCharBind);
        }
        
        //dbclose(dbconn);
        
    }
    completion(error == nil, error, results);
}

- (void)getFieldsForTableName: (NSString *)tableName connection:(id)process
                   completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    NSMutableArray *results = nil;
    NSError *error = nil;
    RETCODE sqlReturnCode = FAIL;
    DBPROCESS *dbconn = [process process];
    if (dbconn) {
        NSString *query = [NSString stringWithFormat:@"SELECT name, system_type_id, max_length, precision, scale FROM sys.columns WHERE object_id = OBJECT_ID('%@')", tableName];
        dbcmd(dbconn, [query cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
        
        sqlReturnCode = dbsqlexec(dbconn);
        
        if (sqlReturnCode != SUCCEED) {
            
            NSString *message = @"Sql Syntax Error";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            error = [NSError errorWithDomain:@"MTDatabaseTds" code:3 userInfo:errorInfo];
            
        }
        
        
        
        NSInteger numberOfColumns = dbnumcols(dbconn);
        
        
        results = [[NSMutableArray alloc] initWithCapacity: numberOfColumns];
        
        //BOOL success = success == SUCCEED;
        //NSMutableDictionary *resultsDictionary = nil;
        
        if (sqlReturnCode == SUCCEED) {
            
            while (dbresults(dbconn) != NO_MORE_RESULTS) {
                
                //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
                DBINT nameLenght            = dbcollen(dbconn, 1);
                //DBINT typeLenght            = dbcollen(dbconn, 2);
                //DBINT lengthLenght          = dbcollen(dbconn, 3);
                //DBINT percisionLenght       = dbcollen(dbconn, 4);
                //DBINT scaleLenght           = dbcollen(dbconn, 5);
                
                char *nameBind;
                NSInteger typeBind, lengthBind, percisionBind, scaleBind;
                
                DBINT nameBindNull, typeBindNull, lengthBindNull, percisionBindNull, scaleBindNull;
                NSInteger nameSize = ( nameLenght + 1 );
                nameBind = malloc( sizeof(char) * nameSize );
                dbbind(dbconn, 1, NTBSTRINGBIND, ( nameLenght + 1 ), (BYTE *)nameBind);
                dbnullbind(dbconn, 1, &nameBindNull);
                
                dbbind(dbconn, 2, INTBIND, sizeof(NSInteger), (BYTE *)&typeBind);
                dbnullbind(dbconn, 2, &typeBindNull);
                
                dbbind(dbconn, 3, INTBIND, sizeof(NSInteger), (BYTE *)&lengthBind);
                dbnullbind(dbconn, 3, &lengthBindNull);
                
                dbbind(dbconn, 4, INTBIND, sizeof(NSInteger), (BYTE *)&percisionBind);
                dbnullbind(dbconn, 4, &percisionBindNull);
                
                dbbind(dbconn, 5, INTBIND, sizeof(NSInteger), (BYTE *)&scaleBind);
                dbnullbind(dbconn, 5, &scaleBindNull);
                
                while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                    
                    
                    NSString *name = nil;
                    
                    if (nameBindNull != -1) {
                        if (nameBind != nil) {
                            
                            NSString *object = [[NSString alloc] initWithCString: nameBind
                                                                        encoding: NSStringEncodingConversionAllowLossy];
                            name = object;
                        }
                    }
                    if (name != nil) {
                        MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName:name];
                        //const char *typeDesc = dbprtype((int)typeBind);
                        //NSString *typeDescWrapper = [[NSString alloc] initWithCString: typeDesc
                        //                                                     encoding: NSStringEncodingConversionAllowLossy];
                        NSInteger fieldTypeCalculated = [MTDatabaseSqlServer dataTypeForNativeType:typeBind];
                        [databaseField setFieldTypeNative:fieldTypeCalculated];
                        [databaseField setFieldType:fieldTypeCalculated];
                        [databaseField setWidth:lengthBind];
                        [databaseField setDecimals:scaleBind];
                        [databaseField setPrimaryKey:0];
                        
                        [results addObject:databaseField];
                        
                    }
                }
                free(nameBind);
            }
        }
        //dbclose(dbconn);
        
    }
    
    completion(error == nil, error, results);
    
}

- (void)closeProcess:(id)process {
    DBPROCESS *dbconn = [process process];
    dbclose(dbconn);
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    __block MTDatabaseSqlServer *blockSelf = self;
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            MTDatabaseConnection *databaseConnection = [blockSelf databaseConnection];
            [blockSelf connectWithCredentals:databaseConnection completion:^(MTDatabaseProcessSqlServer *process, BOOL success, NSError *connectionError) {
                
                if (success) {

                    id results = nil;
                    NSError *error = nil;
                    DBPROCESS *dbconn = [process process];
                    if (dbconn) {
                        
                        dbcmd(dbconn, "SELECT name FROM sys.tables");
                        
                        RETCODE success = dbsqlexec(dbconn);
                        
                        if (success != SUCCEED) {
                            
                            NSString *message = @"Sql Syntax Error";
                            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                            error = [NSError errorWithDomain:@"MTDatabaseTds" code:3 userInfo:errorInfo];
                            
                        }
                        
                        NSInteger numberOfColumns = dbnumcols(dbconn);
                        
                        results = [[NSMutableArray alloc] initWithCapacity: numberOfColumns];
                        
                        while (dbresults(dbconn) != NO_MORE_RESULTS) {
                            
                            //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
                            DBINT columnLength      = dbcollen(dbconn, 1);
                            char *sybVarCharBind;
                            DBINT sybVarCharBindNull;
                            
                            sybVarCharBind = malloc( sizeof(char) * ( columnLength + 1 ) );
                            dbbind(dbconn, 1, NTBSTRINGBIND, columnLength, (BYTE *)sybVarCharBind);
                            dbnullbind(dbconn, 1, &sybVarCharBindNull);
                            
                            while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                                
                                if (sybVarCharBindNull != -1) {
                                    if (sybVarCharBind != nil) {
                                        NSString *tableName = [[NSString alloc] initWithCString: sybVarCharBind
                                                                                       encoding: NSStringEncodingConversionAllowLossy];
                                        MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                                        [results addObject:table];
                                    }
                                }
                            }
                            free(sybVarCharBind);
                        }
                        
                        dbclose(dbconn);
                    } else {
                        NSString *message = @"No Connection";
                        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                        error = [NSError errorWithDomain:@"MTDatabaseTds" code:24 userInfo:errorInfo];
                    }
                    
                    
                    completion(error == nil, error, results);
                } else {
                    completion(NO, connectionError, nil);
                }

            }];
            blockSelf = nil;
        });
    });
}

- (void)getFieldsForTableName: (NSString *)tableName
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {

    [self connectWithCredentals:[self databaseConnection] completion:^(MTDatabaseProcessSqlServer *process, BOOL success, NSError *connectionError) {
        
        if (success) {
            
            NSMutableArray *results = nil;
            NSError *error = nil;
            RETCODE sqlReturnCode = FAIL;
            DBPROCESS *dbconn = [process process];
            if (dbconn) {
                NSString *query = [NSString stringWithFormat:@"SELECT name, system_type_id, max_length, precision, scale FROM sys.columns WHERE object_id = OBJECT_ID('%@')", tableName];
                dbcmd(dbconn, [query cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
                
                sqlReturnCode = dbsqlexec(dbconn);
                
                if (sqlReturnCode != SUCCEED) {
                    
                    NSString *message = @"Sql Syntax Error";
                    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                    error = [NSError errorWithDomain:@"MTDatabaseTds" code:3 userInfo:errorInfo];
                    
                }
                
                
                
                NSInteger numberOfColumns = dbnumcols(dbconn);
                
                
                results = [[NSMutableArray alloc] initWithCapacity: numberOfColumns];
                
                //BOOL success = success == SUCCEED;
                //NSMutableDictionary *resultsDictionary = nil;
                
                if (sqlReturnCode == SUCCEED) {
                    
                    while (dbresults(dbconn) != NO_MORE_RESULTS) {
                        
                        //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
                        DBINT nameLenght            = dbcollen(dbconn, 1);
                        //DBINT typeLenght            = dbcollen(dbconn, 2);
                        //DBINT lengthLenght          = dbcollen(dbconn, 3);
                        //DBINT percisionLenght       = dbcollen(dbconn, 4);
                        //DBINT scaleLenght           = dbcollen(dbconn, 5);
                        
                        char *nameBind;
                        NSInteger typeBind, lengthBind, percisionBind, scaleBind;
                        
                        DBINT nameBindNull, typeBindNull, lengthBindNull, percisionBindNull, scaleBindNull;
                        NSInteger nameSize = ( nameLenght + 1 );
                        nameBind = malloc( sizeof(char) * nameSize );
                        dbbind(dbconn, 1, NTBSTRINGBIND, ( nameLenght + 1 ), (BYTE *)nameBind);
                        dbnullbind(dbconn, 1, &nameBindNull);
                        
                        dbbind(dbconn, 2, INTBIND, sizeof(NSInteger), (BYTE *)&typeBind);
                        dbnullbind(dbconn, 2, &typeBindNull);
                        
                        dbbind(dbconn, 3, INTBIND, sizeof(NSInteger), (BYTE *)&lengthBind);
                        dbnullbind(dbconn, 3, &lengthBindNull);
                        
                        dbbind(dbconn, 4, INTBIND, sizeof(NSInteger), (BYTE *)&percisionBind);
                        dbnullbind(dbconn, 4, &percisionBindNull);
                        
                        dbbind(dbconn, 5, INTBIND, sizeof(NSInteger), (BYTE *)&scaleBind);
                        dbnullbind(dbconn, 5, &scaleBindNull);
                        
                        while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                            
                            
                            NSString *name = nil;
                            
                            if (nameBindNull != -1) {
                                if (nameBind != nil) {
                                    
                                    NSString *object = [[NSString alloc] initWithCString: nameBind
                                                                                encoding: NSStringEncodingConversionAllowLossy];
                                    name = object;
                                }
                            }
                            if (name != nil) {
                                MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName:name];
                                //const char *typeDesc = dbprtype((int)typeBind);
                                //NSString *typeDescWrapper = [[NSString alloc] initWithCString: typeDesc
                                //                                                     encoding: NSStringEncodingConversionAllowLossy];
                                NSInteger fieldTypeCalculated = [MTDatabaseSqlServer dataTypeForNativeType:typeBind];
                                [databaseField setFieldTypeNative:fieldTypeCalculated];
                                [databaseField setFieldType:fieldTypeCalculated];
                                [databaseField setWidth:lengthBind];
                                [databaseField setDecimals:scaleBind];
                                [databaseField setPrimaryKey:0];
                                
                                [results addObject:databaseField];
                                
                            }
                        }
                        free(nameBind);
                    }
                }
                dbclose(dbconn);
                
            }
            
            completion(error == nil, error, results);
        } else {
            completion(NO, connectionError, nil);
        }
    }];
}

+ (MTDataType)dataTypeForNativeType:(NSInteger)nativeType {
    MTDataType result;
    switch (nativeType) {
        case SYBDATETIMN:
            result = MTDataTypeDateTime;
            break;
        case SYBDATETIME:
            result = MTDataTypeDateTime;
            break;
        case SYBDATETIME4:
            result = MTDataTypeDateTime;
            break;
        case SYBCHAR:
            result = MTDataTypeString;
            break;
        case SYBVARCHAR:
            result = MTDataTypeString;
            break;
        case SYBTEXT:
            result = MTDataTypeString;
            break;
        case SYBNTEXT:
            result = MTDataTypeString;
            break;
        case SYBNVARCHAR:
            result = MTDataTypeString;
            break;
        case SYBBIT:
            result = MTDataTypeBit;
            break;
        case SYBBITN:
            result = MTDataTypeBit;
            break;
        case SYBINT1:
            result = MTDataTypeInteger;
            break;
        case SYBINT2:
            result = MTDataTypeInteger;
            break;
        case SYBINT4:
            result = MTDataTypeInteger;
            break;
        case SYBINT8:
            result = MTDataTypeInteger;
            break;
        case SYBINTN:
            result = MTDataTypeInteger;
            break;
        case SYBMONEY:
            result = MTDataTypeFloat;
            break;
        case SYBMONEYN:
            result = MTDataTypeFloat;
            break;
        case SYBREAL:
            result = MTDataTypeFloat;
            break;
        case SYBFLT8:
            result = MTDataTypeFloat;
            break;
        case SYBFLTN:
            result = MTDataTypeFloat;
            break;
        case SYBNUMERIC:
            result = MTDataTypeDecimal;
            break;
        case SYBIMAGE:
            result = MTDataTypeBlob;
            break;
        case SYBBINARY:
            result = MTDataTypeBlob;
            break;
        case SYBVOID:
            result = MTDataTypeBlob;
            break;
        case SYBVARBINARY:
            result = MTDataTypeBlob;
            break;
        default:
            result = MTDataTypeString;
            break;
    }
    return result;
}

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion {
    [self connectWithCredentals:[self databaseConnection] completion:^(id dbconn, BOOL success, NSError *error) {
        
        if (success) {
            [self runQuery:query onProcess:dbconn];
            completion(YES, nil);
            
        } else {
            completion(NO, error);
        }
        
    }];
}

- (void)runQuery:(MTQuery *)query onProcess:(MTDatabaseProcessSqlServer *)process {
    __block MTDataTable *datatable = [self.delegate dataTableForQuery:query];
    
    dispatch_semaphore_t semaphoreRunQuery = dispatch_semaphore_create(0);
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        
        NSError *error = nil;
        NSString *sql = [query getSqlWithError:&error];
        
        if ([sql length] > 0 && error == nil) {

            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            
            NSDateComponents *janFirst1990Components = [[NSDateComponents alloc] init];
            [janFirst1990Components setYear:    1900];
            [janFirst1990Components setMonth:   1];
            [janFirst1990Components setDay:     0];
            [janFirst1990Components setHour:    0];
            [janFirst1990Components setMinute:  0];
            [janFirst1990Components setSecond:  0];
            
            NSDate *janFirst1990 = [gregorian dateFromComponents:janFirst1990Components];
            
            RETCODE success = FAIL;
            
            DBPROCESS *dbconn = [process process];
            if (dbconn) {
                
                if (error == nil) {

                    dbcmd(dbconn, [sql cStringUsingEncoding:NSUTF8StringEncoding]);
                    success = dbsqlexec(dbconn);
                    
                    if (success != SUCCEED) {
                        
                        NSString *message = @"Sql Syntax Error";
                        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                        error = [NSError errorWithDomain:@"MTDatabaseTds" code:3 userInfo:errorInfo];
                        
                    } else {
                        
                        NSString *decimalSeperator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
                        
                        BOOL tdsDecimalSeperatorMatchesCocoaDecimalSeperator = NO;
                        BOOL tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = NO;
                        
                        if (error == nil) {
                            
                            static NSString *MTDatabaseColumnTypeId         = @"MTDatabaseColumnTypeId";
                            static NSString *MTDatabaseColumnNameId         = @"MTDatabaseColumnNameId";
                            static NSString *MTDatabaseColumnNumberId       = @"MTDatabaseColumnNumberId";
                            static NSString *MTDatabaseColumnDataLenId      = @"MTDatabaseColumnDataLenId";
                            static NSString *MTDatabaseColumnLenId          = @"MTDatabaseColumnLenId";
                            static NSString *MTDatabaseColumnIndexOfType    = @"MTDatabaseColumnIndexOfType";
                            static NSString *MTDatabaseColumnPrecision      = @"MTDatabaseColumnPrecision";
                            
                            NSInteger numberOfColumns = dbnumcols(dbconn);
                            NSMutableArray *colmunHolder = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
                            
                            static int disregardedBind = -1023;
                            
                            NSMutableDictionary *counters = [[NSMutableDictionary alloc] initWithDictionary:
                                                             
                                                             @{
                                                               @(SYBDATETIMN)         : @(0),     //Assumed good
                                                               @(SYBDATETIME)         : @(0),     //Good
                                                               @(SYBDATETIME4)        : @(0),     //Good
                                                               
                                                               @(SYBCHAR)             : @(0),     //Good
                                                               @(SYBVARCHAR)          : @(0),     //Good
                                                               @(SYBTEXT)             : @(0),     //Good
                                                               @(SYBNTEXT)            : @(0),     //Good
                                                               @(SYBNVARCHAR)         : @(0),     //Good
                                                               
                                                               @(SYBBIT)              : @(0),     //Good
                                                               @(SYBBITN)             : @(0),     //Assumed good
                                                               @(SYBINT1)             : @(0),     //Good
                                                               @(SYBINT2)             : @(0),     //Good
                                                               @(SYBINT4)             : @(0),     //Good
                                                               @(SYBINT8)             : @(0),     //Good
                                                               @(SYBINTN)             : @(0),     //Assumed good
                                                               
                                                               @(SYBMONEY)            : @(0),     //Good, also handles SYBMONEY4
                                                               @(SYBMONEYN)           : @(0),     //Assumed good
                                                               
                                                               @(SYBREAL)             : @(0),     //Good
                                                               @(SYBFLT8)             : @(0),     //Good
                                                               @(SYBFLTN)             : @(0),     //Assumed good, but may overflow
                                                               
                                                               @(SYBNUMERIC)          : @(0),     //Converts to NSDecimalNumber...
                                                               //  Also handles SYBDECIMAL
                                                               
                                                               
                                                               @(SYBIMAGE)            : @(0),     //Currently not used
                                                               @(SYBBINARY)           : @(0),     //Currently not used
                                                               @(SYBVOID)             : @(0),     //Currently not used
                                                               @(SYBVARBINARY)        : @(0),     //Currently not used
                                                               
                                                               @(disregardedBind)     : @(0)
                                                               
                                                               }
                                                             
                                                             ];
                            [datatable removeAllObjects];
                            
                            for (DBINT columnCtr = 0; columnCtr < numberOfColumns; columnCtr++) {
                                
                                DBINT columnOffsetCtr = columnCtr + 1;
                                DBINT columnType = dbcoltype(dbconn, columnOffsetCtr);
                                if (columnType == SYBDECIMAL) {
                                    columnType = SYBNUMERIC;
                                } else if (columnType == SYBMONEY4) {
                                    columnType = SYBMONEY;
                                }
                                
                                /*
                                 DBINT columnTypeUser = dbcolutype(dbconn, columnOffsetCtr);
                                 const char *typeForDisplay = dbprtype(columnType);
                                 const char *typeForDisplayUser = dbprtype(columnTypeUser);
                                 */
                                
                                if (columnType >= 0) {
                                    
                                    DBINT columnNumberBytes = dbdatlen(dbconn, columnOffsetCtr);
                                    DBINT columnLength      = dbcollen(dbconn, columnOffsetCtr);
                                    
                                    /*
                                     char *columnName        = dbcolname(dbconn, columnOffsetCtr);
                                     DBCOL *ci = malloc(sizeof(DBCOL));
                                     dbcolinfo(dbconn, CI_REGULAR, columnOffsetCtr, 0, ci);
                                     //NSLog(@"\n%@\n%@\n%@", [NSString stringWithCString:ci->ActualName encoding:NSStringEncodingConversionAllowLossy],
                                     [NSString stringWithCString:ci->TableName encoding:NSStringEncodingConversionAllowLossy],
                                     [NSString stringWithCString:ci->Name encoding:NSStringEncodingConversionAllowLossy]);
                                     */
                                    
                                    NSString *fieldKey = [query fieldKeys][columnCtr];
                                    
                                    NSNumber *columnNumber = @(columnCtr);
                                    
                                    NSNumber *columnTypeNumber = @(columnType);
                                    
                                    //NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                                    //NSString *cname = [[columns objectAtIndex:columnCtr] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
                                    //NSArray *fieldSelectComponents = [cname componentsSeparatedByString:[self tableAliasConnector]];
                                    NSString *columnNameString = fieldKey; // [[[fieldSelectComponents lastObject] stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet] retain];
                                    //NSString *columnNameString = [[NSString alloc] initWithCString:columnName encoding:NSStringEncodingConversionAllowLossy];
                                    
                                    NSNumber *columnDataLen = @(columnNumberBytes);
                                    NSNumber *columTypeKey = @(columnType);
                                    NSInteger columnIndexOfType = [counters[columTypeKey] integerValue];
                                    
                                    NSNumber *columnIndexOfTypeNumber = @(columnIndexOfType);
                                    NSNumber *columnLen = @(columnLength);
                                    NSNumber *columPercision = @-1;
                                    
                                    NSDictionary *dictionary = @{
                                                                 MTDatabaseColumnTypeId : columnTypeNumber,          //Type
                                                                 MTDatabaseColumnNameId : columnNameString,          //Name
                                                                 MTDatabaseColumnNumberId : columnNumber,              //Index
                                                                 MTDatabaseColumnDataLenId : columnDataLen,             //Data length
                                                                 MTDatabaseColumnIndexOfType : columnIndexOfTypeNumber,   //Index of type
                                                                 MTDatabaseColumnLenId : columnLen,                 //Column lenght
                                                                 MTDatabaseColumnPrecision : columPercision             //Column percision
                                                                 };
                                    
                                    
                                    
                                    NSInteger fieldTypeCalculated = [MTDatabaseSqlServer dataTypeForNativeType:columnTypeNumber.intValue];
                                    
                                    MTDataColumn *dataColumn = [[MTDataColumn alloc] initWithIdentifier:columnNameString];
                                    [dataColumn setFieldName:columnNameString];
                                    [dataColumn setNativeColumnType:columnTypeNumber];
                                    [dataColumn setDataLength:columnLen];
                                    [dataColumn setDataPercision:columPercision];
                                    [dataColumn setColumnType:@(fieldTypeCalculated)];
                                    
                                    [datatable addColumn:dataColumn];
                                    
                                    [colmunHolder addObject:dictionary];
                                    
                                    
                                    
                                    columnIndexOfType++;
                                    
                                    NSNumber *n = @(columnIndexOfType);
                                    counters[columTypeKey] = n;
                                    
                                }
                            }
                            
                            [datatable beginBulkInsert];
                            
                            while (dbresults(dbconn) != NO_MORE_RESULTS) {
                                
                                //SYBREAL, SYBFLTN, and SYBFLT8
                                
                                NSInteger resultCountForType = [self numberOfItemsOfType:SYBREAL withCounters:counters];
                                double sybRealBind[resultCountForType];
                                DBINT sybRealBindNull[resultCountForType];
                                
                                
                                resultCountForType = [self numberOfItemsOfType:SYBFLTN withCounters:counters];
                                double sybFltNBind[resultCountForType];
                                DBINT sybFltNBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBFLT8 withCounters:counters];
                                double sybFlt8Bind[resultCountForType];
                                DBINT sybFlt8BindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBINT1 withCounters:counters];
                                int sybInt1Bind[resultCountForType];
                                DBINT sybInt1BindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBINT2 withCounters:counters];
                                int sybInt2Bind[resultCountForType];
                                DBINT sybInt2BindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBINTN withCounters:counters];
                                long long sybIntnBind[resultCountForType];
                                DBINT sybIntnBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBINT4 withCounters:counters];
                                int sybInt4Bind[resultCountForType];
                                DBINT sybInt4BindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBINT8 withCounters:counters];
                                long long sybInt8Bind[resultCountForType];
                                DBINT sybInt8BindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBMONEY withCounters:counters];
                                double sybMoneyBind[resultCountForType];
                                DBINT sybMoneyBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBMONEYN withCounters:counters];
                                double sybMoneyNBind[resultCountForType];
                                DBINT sybMoneyNBindNull[resultCountForType];
                                
                                NSInteger resultCountForTypeSybNumericBindChar = [self numberOfItemsOfType:SYBNUMERIC withCounters:counters];
                                char *sybNumericBindChar[resultCountForTypeSybNumericBindChar];
                                DBINT sybNumericBindNull[resultCountForTypeSybNumericBindChar];
                                for (NSInteger i=0; i<resultCountForTypeSybNumericBindChar; i++) {
                                    sybNumericBindChar[i] = '\0';
                                }
                                
                                NSInteger resultCountForTypeSybCharBind = [self numberOfItemsOfType:SYBCHAR withCounters:counters];
                                char *sybCharBind[resultCountForTypeSybCharBind];
                                DBINT sybCharBindNull[resultCountForTypeSybCharBind];
                                for (NSInteger i=0; i<resultCountForTypeSybCharBind; i++) {
                                    sybCharBind[i] = '\0';
                                }
                                
                                NSInteger resultCountForTypeSybVarCharBind = [self numberOfItemsOfType:SYBVARCHAR withCounters:counters];
                                char *sybVarCharBind[resultCountForTypeSybVarCharBind];
                                DBINT sybVarCharBindNull[resultCountForTypeSybVarCharBind];
                                for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
                                    sybVarCharBind[i] = '\0';
                                }
                                
                                NSInteger resultCountForTypeSybnVarCharBind = [self numberOfItemsOfType:SYBNVARCHAR withCounters:counters];
                                char *sybnVarCharBind[resultCountForTypeSybnVarCharBind];
                                DBINT sybnVarCharBindNull[resultCountForTypeSybnVarCharBind];
                                for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
                                    sybnVarCharBind[i] = '\0';
                                }
                                
                                NSInteger resultCountForTypeSybTextBind = [self numberOfItemsOfType:SYBTEXT withCounters:counters];
                                char *sybTextBind[resultCountForTypeSybTextBind];
                                DBINT sybTextBindNull[resultCountForTypeSybTextBind];
                                for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
                                    sybTextBind[i] = '\0';
                                }
                                
                                NSInteger resultCountForTypeSybnTextBind = [self numberOfItemsOfType:SYBNTEXT withCounters:counters];
                                char *sybnTextBind[resultCountForTypeSybnTextBind];
                                DBINT sybnTextBindNull[resultCountForTypeSybnTextBind];
                                for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
                                    sybnTextBind[i] = '\0';
                                }
                                
                                resultCountForType = [self numberOfItemsOfType:SYBDATETIME withCounters:counters];
                                DBDATETIME *sybDateTimeBind[resultCountForType];
                                DBINT sybDateTimeBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBDATETIME4 withCounters:counters];
                                DBDATETIME4 *sybDateTime4Bind[resultCountForType];
                                DBINT sybDateTime4BindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBDATETIMN withCounters:counters];
                                DBDATETIME *sybDateTimnBind[resultCountForType];
                                DBINT sybDateTimnBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBIMAGE withCounters:counters];
                                BYTE *sybImageBind[resultCountForType];
                                DBINT sybImageBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBBINARY withCounters:counters];
                                DBINT sybBinaryBind[resultCountForType];
                                DBINT sybBinaryBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBVARBINARY withCounters:counters];
                                //void *sybVarBinaryBind[resultCountForType];
                                DBINT sybVarBinaryBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBVOID withCounters:counters];
                                //void *sybVoidBind[resultCountForType];
                                DBINT sybVoidBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBBIT withCounters:counters];
                                BOOL sybBitBind[resultCountForType];
                                DBINT sybBitBindNull[resultCountForType];
                                
                                resultCountForType = [self numberOfItemsOfType:SYBBITN withCounters:counters];
                                BOOL sybBitNBind[resultCountForType];
                                DBINT sybBitNBindNull[resultCountForType];
                                
                                for (NSDictionary *columnMetaData in colmunHolder) {
                                    
                                    int columnNumber = [columnMetaData[MTDatabaseColumnNumberId] intValue];
                                    int columnLength = [columnMetaData[MTDatabaseColumnLenId] intValue];
                                    //int columnDataLength = [[columnMetaData objectForKey:MTDatabaseColumnDataLenId] intValue];
                                    int columnIndexOfType = [columnMetaData[MTDatabaseColumnIndexOfType] intValue];
                                    int columnOffsetNumber = columnNumber + 1;
                                    
                                    switch ([columnMetaData[MTDatabaseColumnTypeId] integerValue]) {
                                            
                                        case SYBCHAR:
                                        {
                                            int columnLengthPlusOne = columnLength + 1;
                                            size_t size = sizeof(char) * ( columnLengthPlusOne );
                                            sybCharBind[columnIndexOfType] = malloc( size );
                                            dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLengthPlusOne, (BYTE *)sybCharBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybCharBindNull[columnIndexOfType]);
                                            break;
                                        }
                                        case SYBVARCHAR:
                                        {
                                            int columnLengthPlusOne = columnLength + 1;
                                            size_t size = sizeof(char) * ( columnLengthPlusOne );
                                            sybVarCharBind[columnIndexOfType] = malloc( size );
                                            dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLengthPlusOne, (BYTE *)sybVarCharBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybVarCharBindNull[columnIndexOfType]);
                                            break;
                                        }
                                        case SYBTEXT:
                                        {
                                            int columnLengthPlusOne = columnLength + 1;
                                            size_t size = sizeof(char) * ( columnLengthPlusOne );
                                            sybTextBind[columnIndexOfType] = malloc( size );
                                            dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLengthPlusOne, (BYTE *)sybTextBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybTextBindNull[columnIndexOfType]);
                                            break;
                                        }
                                        case SYBNTEXT:
                                        {
                                            int columnLengthPlusOne = columnLength + 1;
                                            size_t size = sizeof(char) * ( columnLengthPlusOne );
                                            sybnTextBind[columnIndexOfType] = malloc( size );
                                            dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLengthPlusOne, (BYTE *)sybnTextBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybnTextBindNull[columnIndexOfType]);
                                            break;
                                        }
                                        case SYBNVARCHAR:
                                        {
                                            int columnLengthPlusOne = columnLength + 1;
                                            size_t size = sizeof(char) * ( columnLengthPlusOne );
                                            sybnVarCharBind[columnIndexOfType] = malloc( size );
                                            dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLengthPlusOne, (BYTE *)sybnVarCharBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybnVarCharBindNull[columnIndexOfType]);
                                            break;
                                        }
                                        case SYBINTN:
                                            dbbind(dbconn, columnOffsetNumber, BIGINTBIND, sizeof(long long), (BYTE *)&sybIntnBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybIntnBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBINT1:
                                            dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(int), (BYTE *)&sybInt1Bind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybInt1BindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBINT2:
                                            dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(int), (BYTE *)&sybInt2Bind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybInt2BindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBINT4:
                                            dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(int), (BYTE *)&sybInt4Bind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybInt4BindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBINT8:
                                            dbbind(dbconn, columnOffsetNumber, BIGINTBIND, sizeof(long long), (BYTE *)&sybInt8Bind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybInt8BindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBBIT:
                                            dbbind(dbconn, columnOffsetNumber, BITBIND, sizeof(BOOL), (BYTE *)&sybBitBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybBitBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBBITN:
                                            dbbind(dbconn, columnOffsetNumber, BITBIND, sizeof(BOOL), (BYTE *)&sybBitNBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybBitNBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBFLTN:
                                            dbbind(dbconn, columnOffsetNumber, FLT8BIND, columnLength, (BYTE *)&sybFltNBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybFltNBindNull[columnIndexOfType]);
                                            break;
                                        case SYBFLT8:
                                            dbbind(dbconn, columnOffsetNumber, FLT8BIND, columnLength, (BYTE *)&sybFlt8Bind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybFlt8BindNull[columnIndexOfType]);
                                            break;
                                        case SYBREAL:
                                            dbbind(dbconn, columnOffsetNumber, FLT8BIND, columnLength, (BYTE *)&sybRealBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybRealBindNull[columnIndexOfType]);
                                            break;
                                        case SYBDECIMAL:
                                        case SYBNUMERIC: {
                                            
                                            //Logic to bind numeric is below...  Can get percision and scale that way, but
                                            //      large numbers will crash on converting to a useable format (dbconvert).
                                            //      I bind as string and convert to numeric using cocoa.
                                            /*
                                             size_t s = sizeof(DBNUMERIC);
                                             sybNumericBind[columnIndexOfType] = (DBNUMERIC *) calloc(1, s);
                                             memset(sybNumericBind[columnIndexOfType], 0, sizeof(*sybNumericBind[columnIndexOfType]));
                                             dbbind(dbconn, columnOffsetNumber, NUMERICBIND, s, (BYTE *)sybNumericBind[columnIndexOfType]);
                                             */
                                            
                                            sybNumericBindChar[columnIndexOfType] = malloc( sizeof(char) * ( columnLength + 1 ) );
                                            dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLength, (BYTE *)sybNumericBindChar[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybNumericBindNull[columnIndexOfType]);
                                            break;
                                        }
                                        case SYBMONEYN:
                                            dbbind(dbconn, columnOffsetNumber, FLT8BIND, columnLength, (BYTE *)&sybMoneyNBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybMoneyNBindNull[columnIndexOfType]);
                                            break;
                                        case SYBMONEY:
                                            dbbind(dbconn, columnOffsetNumber, FLT8BIND, columnLength, (BYTE *)&sybMoneyBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybMoneyBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBDATETIME:
                                            sybDateTimeBind[columnIndexOfType] = malloc(sizeof(DBDATETIME));
                                            dbbind(dbconn, columnOffsetNumber, DATETIMEBIND, sizeof(DBDATETIME), (BYTE *)sybDateTimeBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybDateTimeBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBDATETIMN:
                                            sybDateTimnBind[columnIndexOfType] = malloc(sizeof(DBDATETIME));
                                            dbbind(dbconn, columnOffsetNumber, DATETIMEBIND, sizeof(DBDATETIME), (BYTE *)sybDateTimnBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybDateTimnBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBDATETIME4:
                                            sybDateTime4Bind[columnIndexOfType] = malloc(sizeof(DBDATETIME4));
                                            dbbind(dbconn, columnOffsetNumber, SMALLDATETIMEBIND, sizeof(DBDATETIME4), (BYTE *)sybDateTime4Bind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybDateTime4BindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBIMAGE:
                                            dbbind(dbconn, columnOffsetNumber, BINARYBIND, (int)sizeof(sybImageBind), (BYTE *)sybImageBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybImageBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBBINARY:
                                            dbbind(dbconn, columnOffsetNumber, BINARYBIND, (int)sizeof(sybBinaryBind), (BYTE *)&sybBinaryBind[columnIndexOfType]);
                                            dbnullbind(dbconn, columnOffsetNumber, &sybBinaryBind[columnIndexOfType]);
                                            break;
                                            
                                        case SYBVOID:
                                            dbnullbind(dbconn, columnOffsetNumber, &sybVoidBindNull[columnIndexOfType]);
                                            break;
                                            
                                        case SYBVARBINARY:
                                            dbnullbind(dbconn, columnOffsetNumber, &sybVarBinaryBindNull[columnIndexOfType]);
                                            break;
                                            
                                        default:
                                            break;
                                    }
                                    
                                }
                                
                                /* dbnextrow will be called once per row in the query before returning NO_MORE_ROWS */
                                NSMutableArray *columnPercision = [[NSMutableArray alloc] initWithCapacity:[colmunHolder count]];
                                for (NSInteger i = 0; i<[colmunHolder count]; i++) {
                                    NSNumber *negOne = @-1;
                                    [columnPercision addObject: negOne];
                                }
                                
                                
                                NSInteger rowCounter = 0;
                                while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                                    /* do RowByAgonizingRow processing */
                                    
                                    NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
                                    
                                    NSInteger columnCounter = 0;
                                    for (NSDictionary *columnMetaData in colmunHolder) {
                                        
                                        int indexOfType = [columnMetaData[MTDatabaseColumnIndexOfType] intValue];
                                        
                                        NSString *fieldName = columnMetaData[MTDatabaseColumnNameId];
                                        
                                        NSInteger columnNumber = [columnMetaData[MTDatabaseColumnNumberId] intValue];
                                        
                                        switch ([columnMetaData[MTDatabaseColumnTypeId] integerValue]) {
                                                
                                            case SYBDECIMAL:
                                            case SYBNUMERIC: {
                                                
                                                if (sybNumericBindNull[indexOfType] != -1) {
                                                    
                                                    NSString *objectStr = [[NSString alloc] initWithCString: sybNumericBindChar[indexOfType]
                                                                                                   encoding: NSStringEncodingConversionAllowLossy];
                                                    
                                                    NSInteger cp = [columnPercision[columnCounter] integerValue];;
                                                    
                                                    NSString *decimalSeperatorSqlServer2 = nil;
                                                    if (cp == -1 && tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved == NO) {
                                                        
                                                        NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
                                                        NSString *seperator = [objectStr stringByTrimmingCharactersInSet:characterSet];
                                                        switch ([seperator length]) {
                                                            case 0: {
                                                                NSNumber *zero = @0;
                                                                [columnPercision setObject:zero atIndexedSubscript:columnCounter];
                                                                
                                                                //  Integer case... no seperator yet.
                                                                tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = NO;
                                                                tdsDecimalSeperatorMatchesCocoaDecimalSeperator = YES;
                                                                break;
                                                            }
                                                            case 1:
                                                            default: {
                                                                NSNumber *one = @1;
                                                                [columnPercision setObject:one atIndexedSubscript:columnCounter];
                                                                
                                                                //Multiple decimal seperators?  This is going to end badly, lol.
                                                                decimalSeperatorSqlServer2 = seperator;
                                                                
                                                                if ([decimalSeperatorSqlServer2 isEqualToString:decimalSeperator]) {
                                                                    tdsDecimalSeperatorMatchesCocoaDecimalSeperator = YES;
                                                                } else {
                                                                    tdsDecimalSeperatorMatchesCocoaDecimalSeperator = NO;
                                                                }
                                                                
                                                                tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = YES;
                                                                
                                                                break;
                                                            }
                                                        }
                                                    }
                                                    
                                                    NSString *objectStr2 = nil;
                                                    
                                                    if (tdsDecimalSeperatorMatchesCocoaDecimalSeperator == NO) {
                                                        objectStr2 = [objectStr stringByReplacingOccurrencesOfString:decimalSeperatorSqlServer2 withString:decimalSeperator];
                                                    }
                                                    
                                                    NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithString:objectStr2];
                                                    if (decimalNumber) {
                                                        resultsForRow[fieldName] = decimalNumber;
                                                    } else {
                                                        resultsForRow[fieldName] = @"Error";
                                                    }
                                                    
                                                    
                                                    objectStr = nil; objectStr2 = nil;
                                                    
                                                }
                                                break;
                                            }
                                            case SYBREAL: {
                                                if (sybRealBindNull[indexOfType] != -1) {
                                                    NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBFLTN: {
                                                if (sybFltNBindNull[indexOfType] != -1) {
                                                    NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBFLT8: {
                                                if (sybFlt8BindNull[indexOfType] != -1) {
                                                    NSNumber *object = @(sybFlt8Bind[indexOfType]);
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                                
                                                
                                            case SYBCHAR: {
                                                if (sybCharBindNull[indexOfType] != -1) {
                                                    char *sybChar = sybCharBind[indexOfType];
                                                    if (sybChar != nil) {
                                                        NSString *object = [[NSString alloc] initWithCString: sybChar
                                                                                                    encoding: NSStringEncodingConversionAllowLossy];
                                                        resultsForRow[fieldName] = object;
                                                    }
                                                }
                                                break;
                                            }
                                                
                                            case SYBVARCHAR: {
                                                if (sybVarCharBindNull[indexOfType] != -1) {
                                                    char *sybVarChar = sybVarCharBind[indexOfType];
                                                    if (sybVarChar != nil) {
                                                        NSString *object = [[NSString alloc] initWithCString: sybVarChar
                                                                                                    encoding: NSStringEncodingConversionAllowLossy];
                                                        resultsForRow[fieldName] = object;
                                                    }
                                                }
                                                break;
                                            }
                                            case SYBNVARCHAR: {
                                                if (sybnVarCharBindNull[indexOfType] != -1) {
                                                    char *sybnVarChar = sybnVarCharBind[indexOfType];
                                                    if (sybnVarChar != nil) {
                                                        NSString *object = [[NSString alloc] initWithCString: sybnVarChar
                                                                                                    encoding: NSStringEncodingConversionAllowLossy];
                                                        resultsForRow[fieldName] = object;
                                                    }
                                                }
                                                break;
                                            }
                                            case SYBTEXT: {
                                                if (sybTextBindNull[indexOfType] != -1) {
                                                    
                                                    char *sybText = sybTextBind[indexOfType];
                                                    if (sybText != nil) {
                                                        NSString *object = [[NSString alloc] initWithCString: sybText
                                                                                                    encoding: NSStringEncodingConversionAllowLossy];
                                                        resultsForRow[fieldName] = object;
                                                    }
                                                }
                                                break;
                                            }
                                            case SYBNTEXT: {
                                                if (sybnTextBindNull[indexOfType] != -1) {
                                                    char *sybnTest = sybnVarCharBind[indexOfType];
                                                    if (sybnTest != nil) {
                                                        NSString *object = [[NSString alloc] initWithCString: sybnTest
                                                                                                    encoding: NSStringEncodingConversionAllowLossy];
                                                        resultsForRow[fieldName] = object;
                                                    }
                                                }
                                                break;
                                            }
                                                
                                            case SYBINTN: {
                                                if (sybIntnBindNull[indexOfType] != -1) {
                                                    long long integer = sybIntnBind[indexOfType];
                                                    NSNumber *object = @((NSInteger)integer);
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBINT1: {
                                                if (sybInt1BindNull[indexOfType] != -1) {
                                                    int integer = sybInt1Bind[indexOfType];
                                                    NSNumber *object = @(integer);
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBINT2: {
                                                if (sybInt2BindNull[indexOfType] != -1) {
                                                    int integer = sybInt2Bind[indexOfType];
                                                    NSNumber *object = @(integer);
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBINT4: {
                                                if (sybInt4BindNull[indexOfType] != -1) {
                                                    int integer = sybInt4Bind[indexOfType];
                                                    NSNumber *object = @(integer);
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBINT8: {
                                                if (sybInt8BindNull[indexOfType] != -1) {
                                                    NSNumber *object = @(sybInt8Bind[indexOfType]);
                                                    resultsForRow[fieldName] = object;
                                                }
                                                break;
                                            }
                                            case SYBDATETIME4: {
                                                if (sybDateTime4BindNull[indexOfType] != -1) {
                                                    DBDATETIME4 smallDate = *sybDateTime4Bind[indexOfType];
                                                    
                                                    NSDateComponents *offsetCompsDays = [[NSDateComponents alloc] init];
                                                    [offsetCompsDays setDay: smallDate.days];
                                                    
                                                    NSDate *object = [gregorian dateByAddingComponents:offsetCompsDays toDate:janFirst1990 options:0];
                                                    
                                                    
                                                    NSDateComponents *smallDaysComponentsPart1 = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit)
                                                                                                              fromDate:object];
                                                    
                                                    NSDateComponents *offsetCompsWithMinutes = [[NSDateComponents alloc] init];
                                                    
                                                    NSInteger hours = smallDate.minutes / 60;
                                                    NSInteger minutes = smallDate.minutes - (hours * 60);
                                                    [offsetCompsWithMinutes setHour:    hours];
                                                    [offsetCompsWithMinutes setMinute:  minutes];
                                                    [offsetCompsWithMinutes setYear:    smallDaysComponentsPart1.year];
                                                    [offsetCompsWithMinutes setMonth:   smallDaysComponentsPart1.month];
                                                    [offsetCompsWithMinutes setDay:     smallDaysComponentsPart1.day];
                                                    [offsetCompsWithMinutes setSecond:  0];
                                                    
                                                    NSDate *newDate = [gregorian dateFromComponents:offsetCompsWithMinutes];
                                                    
                                                    resultsForRow[fieldName] = newDate;
                                                }
                                                break;
                                            }
                                                
                                            case SYBDATETIME: {
                                                if (sybDateTimeBindNull[indexOfType] != -1) {
                                                    DBDATEREC dateinfo;
                                                    memcpy(&sybDateTimeBind[indexOfType], (DBDATETIME *) (dbdata(dbconn, (int)(columnNumber + 1))), sizeof(DBDATETIME));
                                                    dbdatecrack(dbconn, &dateinfo, (DBDATETIME *)&sybDateTimeBind[indexOfType]);
                                                    
                                                    NSDateComponents *comps = [[NSDateComponents alloc] init];
                                                    [comps setYear:     dateinfo.dateyear];
                                                    [comps setMonth:    dateinfo.datemonth + 1];
                                                    [comps setDay:      dateinfo.datedmonth];
                                                    [comps setHour:     dateinfo.datehour];
                                                    [comps setMinute:     dateinfo.dateminute];
                                                    [comps setSecond:     dateinfo.datesecond];
                                                    [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:(60*60*dateinfo.datetzone)]];
                                                    NSDate *date = [gregorian dateFromComponents:comps];
                                                    resultsForRow[fieldName] = date;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                                
                                            case SYBDATETIMN: {
                                                if (sybDateTimnBindNull[indexOfType] != -1) {
                                                    DBDATEREC dateinfo;
                                                    memcpy(&sybDateTimeBind[indexOfType], (DBDATETIME *) (dbdata(dbconn, (int)(columnNumber + 1))), sizeof(DBDATETIME));
                                                    dbdatecrack(dbconn, &dateinfo, (DBDATETIME *)&sybDateTimnBind[indexOfType]);
                                                    
                                                    NSDateComponents *comps = [[NSDateComponents alloc] init];
                                                    [comps setYear:     dateinfo.dateyear];
                                                    [comps setMonth:    dateinfo.datemonth + 1];
                                                    [comps setDay:      dateinfo.datedmonth];
                                                    [comps setHour:     dateinfo.datehour];
                                                    [comps setMinute:     dateinfo.dateminute];
                                                    [comps setSecond:     dateinfo.datesecond];
                                                    [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:(60*60*dateinfo.datetzone)]];
                                                    NSCalendar *gregorian = [[NSCalendar alloc]
                                                                             initWithCalendarIdentifier:NSGregorianCalendar];
                                                    NSDate *date = [gregorian dateFromComponents:comps];
                                                    resultsForRow[fieldName] = date;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                                
                                            case SYBBIT: {
                                                if (sybBitBindNull[indexOfType] != -1) {
                                                    NSNumber *object = @((BOOL)sybBitBind[indexOfType]);
                                                    //NSLog(@"%@\t\t(SYBBIT):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                                    resultsForRow[fieldName] = object;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                                
                                            case SYBBITN: {
                                                if (sybBitNBindNull[indexOfType] != -1) {
                                                    NSNumber *object = [[NSNumber alloc] initWithInt:(BOOL)sybBitNBind[indexOfType]];
                                                    resultsForRow[fieldName] = object;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                                
                                            case SYBIMAGE: {
                                                if (sybImageBindNull[indexOfType] != -1) {
                                                    
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                            case SYBMONEY: {
                                                if (sybMoneyBindNull[indexOfType] != -1) {
                                                    double money = sybMoneyBind[indexOfType];
                                                    NSNumber *moneyNumber = @(money);
                                                    resultsForRow[fieldName] = moneyNumber;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                            case SYBMONEYN: {
                                                if (sybMoneyNBindNull[indexOfType] != -1) {
                                                    double money = sybMoneyNBind[indexOfType];
                                                    NSNumber *moneyNumber = @(money);
                                                    resultsForRow[fieldName] = moneyNumber;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                            case SYBBINARY: {
                                                if (sybBinaryBindNull[indexOfType] != -1) {
                                                    NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                                    resultsForRow[fieldName] = notSupported;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                            case SYBVOID: {
                                                if (sybVoidBindNull[indexOfType] != -1) {
                                                    NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                                    resultsForRow[fieldName] = notSupported;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                            case SYBVARBINARY: {
                                                if (sybVarBinaryBindNull[indexOfType] != -1) {
                                                    NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                                    resultsForRow[fieldName] = notSupported;
                                                } else {
                                                    resultsForRow[fieldName] = NSLocalizedString(@"NULL", @"NULL");
                                                }
                                                break;
                                            }
                                                
                                            default:
                                                break;
                                        }
                                        
                                        columnCounter++;
                                    }
                                    
                                    [datatable addRowWithDataForFieldKeys:resultsForRow];
                                    [self readRow:rowCounter];
                                    rowCounter++;
                                }
                                
                                for (NSInteger i = 0; i < resultCountForTypeSybCharBind; i++) {
                                    free(sybCharBind[i]);
                                }
                                for (NSInteger i = 0; i < resultCountForTypeSybNumericBindChar; i++) {
                                    free(sybNumericBindChar[i]);
                                }
                                for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
                                    free(sybVarCharBind[i]);
                                }
                                for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
                                    free(sybnVarCharBind[i]);
                                }
                                for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
                                    free(sybTextBind[i]);
                                }
                                for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
                                    free(sybnTextBind[i]);
                                }
                                
                            }

                            [datatable endBulkInsert];
                        }
                    }
                }
                dbclose(dbconn);
                
            }
        
        }

        datatable = nil;

        dispatch_semaphore_signal(semaphoreRunQuery);
        
    });
    
    
    dispatch_semaphore_wait(semaphoreRunQuery, DISPATCH_TIME_FOREVER);
    
}

- (NSInteger)numberOfItemsOfType:(int)type withCounters:(NSMutableDictionary *)counters {
    NSNumber *counter = counters[@(type)];
    NSInteger resultCountForType;
    if (counter) {
        resultCountForType = [counter integerValue];
    } else {
        resultCountForType = 0;
    }
    return resultCountForType;
}

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr);
int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {

    __block int result = INT_CANCEL;

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{

    
    if (severity >= 5) {
        NSString *title = NSLocalizedString(@"Caught an Error", @"Caught an Error");
        char *osstr = (oserrstr != NULL ? oserrstr : "");
        char *dbstr = (dberrstr != NULL ? dberrstr : "");
        
        NSString *systemMessage = @(osstr);
        NSString *dbMessage = @(dbstr);
        NSString *errorMessage = [NSString stringWithFormat:@"System says: \"(%d)%@.\"\nDatabase says: \"(%d)%@.\"", oserr, systemMessage, dberr, dbMessage];
        
        //Don't want to lookup
        //NSString *sqlForErrorMessages = [NSString stringWithFormat:@"select * from sys.messages where message_id = %@", dberr];
        
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : errorMessage};
        NSError *error = [NSError errorWithDomain:@"MTDatabaseTds" code:dberr userInfo:errorInfo];
        
        __block BOOL continueToGo = YES;
        dispatch_semaphore_t showError = dispatch_semaphore_create(0);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [error presentErrorToUserWithContinue:^(BOOL success) {
                continueToGo = success;
                dispatch_semaphore_signal(showError);
            }];
        });
        dispatch_semaphore_wait(showError, DISPATCH_TIME_FOREVER);
        
        if (continueToGo) {
            result = INT_CONTINUE;
        } else {
            result = INT_CANCEL;
        }
    }
    
    });
    return result;
}

- (DBPROCESS *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError **)error {

    DBPROCESS *dbconn = NULL;
    BOOL connected = NO;
    //*error = nil;
    
    
    LOGINREC *login;
    char hostname[30];
    int max_len = 30;
    
    
    /* Init the DB library */
    if (dbinit() == FAIL) {
        NSString *message = @"Could not init db.";
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
        *error = [NSError errorWithDomain:@"MTDatabaseTds" code:1 userInfo:errorInfo];
    }
    dberrhandle(err_handler);
    
    if (*error == nil) {
        login = dblogin();
        if (login == FAIL) {
            NSString *message = @"Could not initialize dblogin() structure.";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            *error = [NSError errorWithDomain:@"MTDatabaseTds" code:2 userInfo:errorInfo];
        }
        
        if (*error == nil) {
            /* Initialize the login params in the structure */
            const char *u = [username cStringUsingEncoding:NSUTF8StringEncoding];
            const char *p = [password cStringUsingEncoding:NSUTF8StringEncoding];
            const char *a = [[[self databaseConnection] appname] cStringUsingEncoding:NSUTF8StringEncoding];
            const char *n = [[[self databaseConnection] database] cStringUsingEncoding:NSUTF8StringEncoding];
            DBSETLUSER(login, u);
            DBSETLPWD(login, p);
            DBSETLAPP(login, a);
            DBSETLDBNAME(login, n);
            
            if (gethostname(hostname, max_len) == 0) {
                DBSETLHOST(login, hostname);
            }
            
        }
        DBSETLSECURE(login);
        if (*error == nil) {
            char *s = (char *)[[[self databaseConnection] server] cStringUsingEncoding:NSUTF8StringEncoding];
            dbconn = dbopen(login, s);
            if (dbconn == NULL) {
                NSString *message = [NSString stringWithFormat:@"Could not connect to DB Server: %s\n", s];
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                *error = [NSError errorWithDomain:@"MTDatabaseTds" code:2 userInfo:errorInfo];
            }
        }
        connected = (*error == nil);
        
        dbloginfree(login);
    }
    
    return dbconn;
}

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id dbconn, BOOL success, NSError *error))completion {
    
    [self getCredentalsWithConnection:connection completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
        
        if (success) {
            
            NSError *error = nil;
            DBPROCESS *dbconn = [self connect:username andPassword:password error:&error];
            MTDatabaseProcessSqlServer *dbwrap = nil;
            
            if (error) {
                SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
                [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:error waitUntilDone:NO];
            } else {
                dbwrap = [[MTDatabaseProcessSqlServer alloc] initWithProcess:dbconn];
            }
            

            completion(dbwrap, error == nil, error);
            
        } else {
            SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
            [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:error waitUntilDone:NO];
            completion(nil, NO, error);
        }

    }];
    
}

- (NSString *)identifier {
    return [MTDatabaseSqlServer identifier];
}

+ (NSString *)identifier {
    return @"TDS";
}

- (id)connectionSettings {
    return [self databaseConnection];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"[%@].[%@]", queryTable, fieldName];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTDatabaseSqlServer safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"[%@].[%@]", queryTable, fieldName];
}

- (NSString *) safeIdentifier:(NSString *)fieldOrTableName {
    return [NSString stringWithFormat:@"[%@]", fieldOrTableName];
}

- (NSString *)sqlAggregateFunctionLength {
    return @"DATALENGTH";
}

- (NSString *)selectPart {
    return [self selectPartWithLimitedResults:NSNotFound];  // No limit by default
}

- (NSString *)selectPartWithLimitedResults:(NSInteger)limit {
    NSString *selectPart = [super selectPart];
    return limit > 0 && limit != NSNotFound ? [selectPart stringByAppendingFormat:@"TOP %ld\n", (long)limit] : selectPart;
}

- (NSString *)sqlLimitClause {
    return @"";
}

- (NSString *)sqlLimitClause:(NSInteger)limit {
    return @"";
}

- (NSString *)sqlSampleDataForField:(RptqDatabaseSchemaField *)schemaField {
    
    NSString *safeField = [self safeQuerySchemaField:schemaField];
    NSString *safeFieldAlias = [self fieldAliasForField:schemaField];
    NSString *safeTable = [self safeIdentifier:schemaField.inTable.name];
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT TOP 511 "
                     @"%@ %@ %@ "
                     @"%@ %@ ",
                     safeField, [self tableAliasConnector], safeFieldAlias,
                     MTSqlFrom, safeTable];
    return sql;
}

@end
