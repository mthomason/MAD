//
//  MTDatabaseSqlServer.m
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSqlServer.h"

NSString * const MTDatabaseConnectionUsername   = @"MTDatabaseConnectionUsername";
NSString * const MTDatabaseConnectionPassword   = @"MTDatabaseConnectionPassword";
NSString * const MTDatabaseConnectionDatabase   = @"MTDatabaseConnectionDatabase";
NSString * const MTDatabaseConnectionPort       = @"MTDatabaseConnectionPort";
NSString * const MTDatabaseConnectionHost       = @"MTDatabaseConnectionHost";
NSString * const MTDatabaseConnectionServer     = @"MTDatabaseConnectionServer";
NSString * const MTDatabaseConnectionAppName    = @"MTDatabaseConnectionAppName";

@interface MTDatabaseSqlServer ()

@property (readwrite, nonatomic, retain) MTDatabaseConnection *databaseConnection;

@end

@implementation MTDatabaseSqlServer

- (void)dealloc {
    [_databaseConnection release];
    [super dealloc];
}

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings {
    self = [super init];
    if (self) {
        [self setDatabaseConnection:connectionSettings];
    }
    return self;
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    //dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    //dispatch_async(queuePriorityBackground, ^{
    //    dispatch_async(dispatch_get_main_queue(), ^{
            

            [self connectWithCredentals:[self databaseConnection] completion:^(DBPROCESS *dbconn, BOOL success, NSError *connectionError) {
                
                if (success) {

                    id results = nil;
                    NSError *error = nil;
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
                                        //NSLog(@"%@", table);
                                        [results addObject:table];
                                        [table release];
                                        [tableName release];
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
                    
                    
                    completion(error == nil, error, [results autorelease]);
                } else {
                    completion(NO, connectionError, nil);
                }

            }];

        //});
    //});
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    [self connectWithCredentals:[self databaseConnection] completion:^(DBPROCESS *dbconn, BOOL success, NSError *connectionError) {
        
        if (success) {
            
            NSMutableArray *results = nil;
            NSError *error = nil;
            RETCODE sqlReturnCode = FAIL;
            
            if (dbconn) {
                NSString *query = [NSString stringWithFormat:@"SELECT name, system_type_id, max_length, precision, scale FROM sys.columns WHERE object_id = OBJECT_ID('%@')", [table name]];
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
                                    name = [object retain];
                                    [object release];
                                }
                            }
                            if (name != nil) {
                                MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName:name];
                                const char *typeDesc = dbprtype(typeBind);
                                NSString *typeDescWrapper = [[NSString alloc] initWithCString: typeDesc
                                                                                     encoding: NSStringEncodingConversionAllowLossy];
                                NSInteger fieldTypeCalculated = [self dataTypeForNativeType:typeBind];
                                [databaseField setFieldTypeNative:fieldTypeCalculated];
                                [databaseField setFieldType:fieldTypeCalculated];
                                [databaseField setWidth:lengthBind];
                                [databaseField setDecimals:scaleBind];
                                [databaseField setPrimaryKey:0];
                                
                                [results addObject:databaseField];
                                
                                [databaseField release];
                                [typeDescWrapper release];
                                
                            }
                            [name release];
                        }
                        free(nameBind);
                    }
                }
                dbclose(dbconn);
                
            }
            
            completion(error == nil, error, [results autorelease]);
        } else {
            completion(NO, connectionError, nil);
        }
    }];
}

- (MTDataType)dataTypeForNativeType:(NSInteger)nativeType {
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

NSString * const MTSqlSelectTop100 = @"SELECT TOP 100";

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        
        NSString *sql = [NSString stringWithFormat:@"%@ %@ "
                         @"%@"
                         @" %@;",
                         MTSqlSelectTop100, schemaField.name, MTSqlFrom, schemaField.inTable.name];
        NSArray *resultStrings = [[self runQuery:sql] retain];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, nil, resultStrings);
            
        });
        [resultStrings release];
    });
    
}

- (NSString *)selectPart {
    return [self isLicensedUser] ? @"SELECT\n" : @"SELECT TOP 50\n";
}

- (void)cacheReportQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                     completion:(void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *queryString = [mnsDatabase getSqlForQuery:rquery];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqQueryCache *queryCache = [[RptqQueryCache initObjectForManagedObjectContext:managedObjectContext] retain];

    id queryResult = [self runQuery:queryString];
    
    //for (NSDictionary *result in queryResult) {
        //NSLog(@"%@", result);
        //id r = result[@"ABBREV_0.Calcium"];
        //const char *type = [r objCType];
    //}

    NSError *error = nil;
    NSData *cachedData = [NSPropertyListSerialization dataWithPropertyList:queryResult format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];

    NSString *name = [[[MTActiveDocument sharedDocument] activeDocument] name];
    NSURL *url = [[NSFileManager  localTemporaryDirectory] URLByAppendingPathComponent:name isDirectory:NO];
    [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (error) {
        error = nil;
        [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    }

    [queryCache setCacheDate:[NSDate date]];
    [query setHasQueryCache:queryCache];
    [queryCache release];
    completion(self, [query hasQueryCache]);
}

- (id)runQuery:(NSString *)sql {

    __block NSMutableArray *results = [[NSMutableArray alloc] init];

    dispatch_semaphore_t semaphoreRunQuery = dispatch_semaphore_create(0);
    
    [self connectWithCredentals:[self databaseConnection] completion:^(DBPROCESS *dbconn, BOOL success, NSError *connectionError) {
        
        if (success) {
            
            
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            
            NSDateComponents *janFirst1990Components = [[NSDateComponents alloc] init];
            [janFirst1990Components setYear:    1900];
            [janFirst1990Components setMonth:   1];
            [janFirst1990Components setDay:     0];
            [janFirst1990Components setHour:    0];
            [janFirst1990Components setMinute:  0];
            [janFirst1990Components setSecond:  0];
            
            NSDate *janFirst1990 = [[gregorian dateFromComponents:janFirst1990Components] retain];
            
            NSString *begining = [sql substringToIndex:[sql rangeOfString:MTSqlFrom].location];
            NSRange rangeOfSelectPart = [begining rangeOfString:[self selectPart]];
            if (rangeOfSelectPart.location == NSNotFound) {
                rangeOfSelectPart = [begining rangeOfString:MTSqlSelectTop100];
            }
            NSString *selectColumns = [begining substringFromIndex:rangeOfSelectPart.location + rangeOfSelectPart.length];
            NSArray *columns = [selectColumns componentsSeparatedByString:@","];
            
            NSError *error = nil;
            RETCODE success = FAIL;

            if (dbconn) {
                
                if (error == nil) {
                    
                    dbcmd(dbconn, [sql cStringUsingEncoding:NSUTF8StringEncoding]);
                    success = dbsqlexec(dbconn);
                    
                    if (success != SUCCEED) {
                        
                        NSString *message = @"Sql Syntax Error";
                        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                        error = [NSError errorWithDomain:@"MTDatabaseTds" code:3 userInfo:errorInfo];
                        
                    }
                    
                }
                
                NSString *decimalSeperator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
                NSString *decimalSeperatorSqlServer = nil;
                
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
                    
                    for (NSInteger columnCtr = 0; columnCtr < numberOfColumns; columnCtr++) {
                        
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
                             NSLog(@"\n%@\n%@\n%@", [NSString stringWithCString:ci->ActualName encoding:NSStringEncodingConversionAllowLossy],
                             [NSString stringWithCString:ci->TableName encoding:NSStringEncodingConversionAllowLossy],
                             [NSString stringWithCString:ci->Name encoding:NSStringEncodingConversionAllowLossy]);
                             */
                            
                            
                            NSNumber *columnNumber = [[NSNumber alloc] initWithInt:columnCtr];
                            
                            NSNumber *columnTypeNumber = [[NSNumber alloc] initWithInt:columnType];
                            NSString *columnNameString = [[[columns objectAtIndex:columnCtr] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
                            //NSString *columnNameString = [[NSString alloc] initWithCString:columnName encoding:NSStringEncodingConversionAllowLossy];
                            
                            
                            NSNumber *columnDataLen = [[NSNumber alloc] initWithInteger:columnNumberBytes];
                            NSNumber *columTypeKey = [@(columnType) retain];
                            NSInteger columnIndexOfType = [[counters objectForKey:columTypeKey] integerValue];
                            
                            NSNumber *columnIndexOfTypeNumber = [[NSNumber alloc] initWithInteger:columnIndexOfType];
                            NSNumber *columnLen = [[NSNumber alloc] initWithInteger: columnLength];
                            NSNumber *columPercision = [[NSNumber alloc] initWithInteger: -1];
                            
                            NSDictionary *dictionary = [[NSDictionary alloc] initWithDictionary:@{
                                                                        MTDatabaseColumnTypeId : columnTypeNumber,          //Type
                                                                        MTDatabaseColumnNameId : columnNameString,          //Name
                                                                      MTDatabaseColumnNumberId : columnNumber,              //Index
                                                                     MTDatabaseColumnDataLenId : columnDataLen,             //Data length
                                                                   MTDatabaseColumnIndexOfType : columnIndexOfTypeNumber,   //Index of type
                                                                         MTDatabaseColumnLenId : columnLen,                 //Column lenght
                                                                     MTDatabaseColumnPrecision : columPercision             //Column percision
                                                        }];
                            
                            [columPercision release];
                            [colmunHolder addObject:dictionary];
                            
                            [dictionary release];
                            
                            
                            columnIndexOfType++;
                            
                            NSNumber *n = [@(columnIndexOfType) retain];
                            [counters setObject:n forKey:columTypeKey];
                            [n release];
                            
                            [columnLen release];
                            [columnIndexOfTypeNumber release];
                            [columnNameString release];
                            [columnTypeNumber release];
                            
                            [columnNumber release];
                            
                            [columnDataLen release];
                            
                            [columTypeKey release];
                        }
                    }
                    
                    while (dbresults(dbconn) != NO_MORE_RESULTS) {
                        
                        //SYBREAL, SYBFLTN, and SYBFLT8
                        NSInteger resultCountForType = [[counters objectForKey:@(SYBREAL)] integerValue];
                        double sybRealBind[resultCountForType];
                        DBINT sybRealBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBFLTN)] integerValue];
                        double sybFltNBind[resultCountForType];
                        DBINT sybFltNBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBFLT8)] integerValue];
                        double sybFlt8Bind[resultCountForType];
                        DBINT sybFlt8BindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBINT1)] integerValue];
                        NSInteger sybInt1Bind[resultCountForType];
                        DBINT sybInt1BindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBINT2)] integerValue];
                        NSInteger sybInt2Bind[resultCountForType];
                        DBINT sybInt2BindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBINTN)] integerValue];
                        long long sybIntnBind[resultCountForType];
                        DBINT sybIntnBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBINT4)] integerValue];
                        NSInteger sybInt4Bind[resultCountForType];
                        DBINT sybInt4BindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBINT8)] integerValue];
                        long long sybInt8Bind[resultCountForType];
                        DBINT sybInt8BindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBMONEY)] integerValue];
                        double sybMoneyBind[resultCountForType];
                        DBINT sybMoneyBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBMONEYN)] integerValue];
                        double sybMoneyNBind[resultCountForType];
                        DBINT sybMoneyNBindNull[resultCountForType];
                        
                        NSInteger resultCountForTypeSybNumericBindChar = [[counters objectForKey:@(SYBNUMERIC)] integerValue];
                        char *sybNumericBindChar[resultCountForTypeSybNumericBindChar];
                        DBINT sybNumericBindNull[resultCountForTypeSybNumericBindChar];
                        for (NSInteger i=0; i<resultCountForTypeSybNumericBindChar; i++) {
                            sybNumericBindChar[i] = '\0';
                        }
                        
                        NSInteger resultCountForTypeSybCharBind = [[counters objectForKey:@(SYBCHAR)] integerValue];
                        char *sybCharBind[resultCountForTypeSybCharBind];
                        DBINT sybCharBindNull[resultCountForTypeSybCharBind];
                        for (NSInteger i=0; i<resultCountForTypeSybCharBind; i++) {
                            sybCharBind[i] = '\0';
                        }
                        
                        
                        
                        
                        NSInteger resultCountForTypeSybVarCharBind = [[counters objectForKey:@(SYBVARCHAR)] integerValue];
                        char *sybVarCharBind[resultCountForTypeSybVarCharBind];
                        DBINT sybVarCharBindNull[resultCountForTypeSybVarCharBind];
                        for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
                            sybVarCharBind[i] = '\0';
                        }
                        
                        NSInteger resultCountForTypeSybnVarCharBind = [[counters objectForKey:@(SYBNVARCHAR)] integerValue];
                        char *sybnVarCharBind[resultCountForTypeSybnVarCharBind];
                        DBINT sybnVarCharBindNull[resultCountForTypeSybnVarCharBind];
                        for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
                            sybnVarCharBind[i] = '\0';
                        }
                        
                        NSInteger resultCountForTypeSybTextBind = [[counters objectForKey:@(SYBTEXT)] integerValue];
                        char *sybTextBind[resultCountForTypeSybTextBind];
                        DBINT sybTextBindNull[resultCountForTypeSybTextBind];
                        for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
                            sybTextBind[i] = '\0';
                        }
                        
                        NSInteger resultCountForTypeSybnTextBind = [[counters objectForKey:@(SYBNTEXT)] integerValue];
                        char *sybnTextBind[resultCountForTypeSybnTextBind];
                        DBINT sybnTextBindNull[resultCountForTypeSybnTextBind];
                        for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
                            sybnTextBind[i] = '\0';
                        }
                        
                        
                        
                        
                        resultCountForType = [[counters objectForKey:@(SYBDATETIME)] integerValue];
                        DBDATETIME *sybDateTimeBind[resultCountForType];
                        DBINT sybDateTimeBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBDATETIME4)] integerValue];
                        DBDATETIME4 *sybDateTime4Bind[resultCountForType];
                        DBINT sybDateTime4BindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBDATETIMN)] integerValue];
                        DBDATETIME *sybDateTimnBind[resultCountForType];
                        DBINT sybDateTimnBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBIMAGE)] integerValue];
                        DBINT sybImageBind[resultCountForType];
                        DBINT sybImageBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBBINARY)] integerValue];
                        DBINT sybBinaryBind[resultCountForType];
                        DBINT sybBinaryBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBVARBINARY)] integerValue];
                        //void *sybVarBinaryBind[resultCountForType];
                        DBINT sybVarBinaryBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBVOID)] integerValue];
                        //void *sybVoidBind[resultCountForType];
                        DBINT sybVoidBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBBIT)] integerValue];
                        BOOL sybBitBind[resultCountForType];
                        DBINT sybBitBindNull[resultCountForType];
                        
                        resultCountForType = [[counters objectForKey:@(SYBBITN)] integerValue];
                        BOOL sybBitNBind[resultCountForType];
                        DBINT sybBitNBindNull[resultCountForType];
                        
                        for (NSDictionary *columnMetaData in colmunHolder) {
                            
                            int columnNumber = [[columnMetaData objectForKey:MTDatabaseColumnNumberId] intValue];
                            int columnLength = [[columnMetaData objectForKey:MTDatabaseColumnLenId] intValue];
                            //int columnDataLength = [[columnMetaData objectForKey:MTDatabaseColumnDataLenId] intValue];
                            int columnIndexOfType = [[columnMetaData objectForKey:MTDatabaseColumnIndexOfType] intValue];
                            int columnOffsetNumber = columnNumber + 1;
                            
                            switch ([[columnMetaData objectForKey:MTDatabaseColumnTypeId] integerValue]) {
                                    
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
                                    dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(NSInteger), (BYTE *)&sybInt1Bind[columnIndexOfType]);
                                    dbnullbind(dbconn, columnOffsetNumber, &sybInt1BindNull[columnIndexOfType]);
                                    break;
                                    
                                case SYBINT2:
                                    dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(NSInteger), (BYTE *)&sybInt2Bind[columnIndexOfType]);
                                    dbnullbind(dbconn, columnOffsetNumber, &sybInt2BindNull[columnIndexOfType]);
                                    break;
                                    
                                case SYBINT4:
                                    dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(NSInteger), (BYTE *)&sybInt4Bind[columnIndexOfType]);
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
                                    dbbind(dbconn, columnOffsetNumber, BINARYBIND, sizeof(sybImageBind), (BYTE *)sybImageBind[columnIndexOfType]);
                                    dbnullbind(dbconn, columnOffsetNumber, &sybImageBindNull[columnIndexOfType]);
                                    break;
                                    
                                case SYBBINARY:
                                    dbbind(dbconn, columnOffsetNumber, BINARYBIND, sizeof(sybBinaryBind), (BYTE *)&sybBinaryBind[columnIndexOfType]);
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
                            NSNumber *negOne = [[NSNumber alloc] initWithInteger:-1];
                            [columnPercision addObject: negOne];
                            [negOne release];
                        }
                        
                        while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                            /* do RowByAgonizingRow processing */
                            
                            NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
                            
                            NSInteger columnCounter = 0;
                            for (NSDictionary *columnMetaData in colmunHolder) {
                                [columnMetaData retain];
                                
                                int indexOfType = [[columnMetaData objectForKey:MTDatabaseColumnIndexOfType] intValue];
                                
                                NSString *fieldName = [[columnMetaData objectForKey:MTDatabaseColumnNameId] retain];
                                
                                NSInteger columnNumber = [[columnMetaData objectForKey:MTDatabaseColumnNumberId] intValue];
                                //NSInteger columnLength = [[columnMetaData objectForKey:MTDatabaseColumnLenId] intValue];
                                
                                switch ([[columnMetaData objectForKey:MTDatabaseColumnTypeId] integerValue]) {
                                        
                                    case SYBDECIMAL:
                                    case SYBNUMERIC: {
                                        
                                        if (sybNumericBindNull[indexOfType] != -1) {
                                            
                                            NSString *objectStr = [[NSString alloc] initWithCString: sybNumericBindChar[indexOfType]
                                                                                           encoding: NSStringEncodingConversionAllowLossy];
                                            
                                            NSInteger cp = [[columnPercision objectAtIndex:columnCounter] integerValue];;
                                            
                                            if (cp == -1 && tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved == NO) {
                                                //NSArray *seperators = [objectStr componentsSeparatedByCharactersInSet :[NSCharacterSet decimalDigitCharacterSet]];
                                                NSString *seperator = [objectStr stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
                                                switch ([seperator length]) {
                                                    case 0: {
                                                        NSNumber *zero = [[NSNumber alloc] initWithInteger:0];
                                                        [columnPercision setObject:zero atIndexedSubscript:columnCounter];
                                                        [zero release];
                                                        //  Integer case... no seperator yet.
                                                        tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = NO;
                                                        tdsDecimalSeperatorMatchesCocoaDecimalSeperator = YES;
                                                        break;
                                                    }
                                                    case 1:
                                                    default: {
                                                        NSNumber *one = [[NSNumber alloc] initWithInteger:1];
                                                        [columnPercision setObject:one atIndexedSubscript:columnCounter];
                                                        [one release];
                                                        
                                                        //Multiple decimal seperators?  This is going to end badly, lol.
                                                        decimalSeperatorSqlServer = [seperator retain];
                                                        
                                                        if ([decimalSeperatorSqlServer isEqualToString:decimalSeperator]) {
                                                            tdsDecimalSeperatorMatchesCocoaDecimalSeperator = YES;
                                                        } else {
                                                            tdsDecimalSeperatorMatchesCocoaDecimalSeperator = NO;
                                                        }
                                                        
                                                        tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = YES;
                                                        
                                                        break;
                                                    }
                                                }
                                            }
                                            
                                            if (tdsDecimalSeperatorMatchesCocoaDecimalSeperator == NO) {
                                                NSString *obj = [[objectStr stringByReplacingOccurrencesOfString:decimalSeperatorSqlServer withString:decimalSeperator] retain];
                                                [objectStr release]; objectStr = nil;
                                                objectStr = [obj retain];
                                            }
                                            
                                            NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithString:objectStr];
                                            if (decimalNumber) {
                                                resultsForRow[fieldName] = decimalNumber;
                                            } else {
                                                resultsForRow[fieldName] = @"Error";
                                            }
                                            
                                            [decimalNumber release];
                                            
                                            [objectStr release];
                                            
                                        } else {
                                            //[resultsForRow setObject:@"NULL" forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBREAL: {
                                        if (sybRealBindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
                                            resultsForRow[fieldName] = object;
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:@"NULL" forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBFLTN: {
                                        if (sybFltNBindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
                                            resultsForRow[fieldName] = object;
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:@"NULL" forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBFLT8: {
                                        if (sybFlt8BindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithDouble:sybFlt8Bind[indexOfType]];
                                            resultsForRow[fieldName] = object;
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:@"NULL" forKey:fieldName];
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
                                                [object release];
                                            }
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBVARCHAR: {
                                        if (sybVarCharBindNull[indexOfType] != -1) {
                                            char *sybVarChar = sybVarCharBind[indexOfType];
                                            if (sybVarChar != nil) {
                                                NSString *object = [[NSString alloc] initWithCString: sybVarChar
                                                                                            encoding: NSStringEncodingConversionAllowLossy];
                                                [resultsForRow setObject:object forKey:fieldName];
                                                [object release];
                                            }
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBNVARCHAR: {
                                        if (sybnVarCharBindNull[indexOfType] != -1) {
                                            char *sybnVarChar = sybnVarCharBind[indexOfType];
                                            if (sybnVarChar != nil) {
                                                NSString *object = [[NSString alloc] initWithCString: sybnVarChar
                                                                                            encoding: NSStringEncodingConversionAllowLossy];
                                                [resultsForRow setObject:object forKey:fieldName];
                                                [object release];
                                            }
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBTEXT: {
                                        if (sybTextBindNull[indexOfType] != -1) {
                                            
                                            char *sybText = sybTextBind[indexOfType];
                                            if (sybText != nil) {
                                                NSString *object = [[NSString alloc] initWithCString: sybText
                                                                                            encoding: NSStringEncodingConversionAllowLossy];
                                                [resultsForRow setObject:object forKey:fieldName];
                                                [object release];
                                            }
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBNTEXT: {
                                        if (sybnTextBindNull[indexOfType] != -1) {
                                            char *sybnTest = sybnVarCharBind[indexOfType];
                                            if (sybnTest != nil) {
                                                NSString *object = [[NSString alloc] initWithCString: sybnTest
                                                                                            encoding: NSStringEncodingConversionAllowLossy];
                                                [resultsForRow setObject:object forKey:fieldName];
                                                [object release];
                                            }
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBINTN: {
                                        if (sybIntnBindNull[indexOfType] != -1) {
                                            long long integer = sybIntnBind[indexOfType];
                                            NSNumber *object = [[NSNumber alloc] initWithInteger:(NSInteger)integer];
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBINT1: {
                                        if (sybInt1BindNull[indexOfType] != -1) {
                                            int integer = sybInt1Bind[indexOfType];
                                            NSNumber *object = [[NSNumber alloc] initWithInt:integer];
                                            //NSLog(@"%@\t\t(SYBINT1):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBINT2: {
                                        if (sybInt2BindNull[indexOfType] != -1) {
                                            int integer = sybInt2Bind[indexOfType];
                                            NSNumber *object = [[NSNumber alloc] initWithInt:integer];
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBINT4: {
                                        if (sybInt4BindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithInteger:sybInt4Bind[indexOfType]];
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:@"NULL" forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBINT8: {
                                        if (sybInt8BindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithLongLong:sybInt8Bind[indexOfType]];
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
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
                                            
                                            NSDate *newDate = [[gregorian dateFromComponents:offsetCompsWithMinutes] retain];
                                            
                                            //NSLog(@"%@\t\t(SYBDATETIME4):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], newDate);
                                            [resultsForRow setObject:newDate forKey:fieldName];
                                            [newDate release];
                                        } else {
                                            //[resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBDATETIME: {
                                        if (sybDateTimeBindNull[indexOfType] != -1) {
                                            DBDATEREC dateinfo;
                                            memcpy(&sybDateTimeBind[indexOfType], (DBDATETIME *) (dbdata(dbconn, (columnNumber + 1))), sizeof(DBDATETIME));
                                            dbdatecrack(dbconn, &dateinfo, (DBDATETIME *)&sybDateTimeBind[indexOfType]);
                                            
                                            NSDateComponents *comps = [[NSDateComponents alloc] init];
                                            [comps setYear:     dateinfo.dateyear];
                                            [comps setMonth:    dateinfo.datemonth + 1];
                                            [comps setDay:      dateinfo.datedmonth];
                                            [comps setHour:     dateinfo.datehour];
                                            [comps setMinute:     dateinfo.dateminute];
                                            [comps setSecond:     dateinfo.datesecond];
                                            [comps setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:(60*60*dateinfo.datetzone)]];
                                            NSDate *date = [[gregorian dateFromComponents:comps] retain];
                                            //NSLog(@"%@\t\t(SYBDATETIME):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], date);
                                            [resultsForRow setObject:date forKey:fieldName];
                                            [date release];
                                            [comps release];
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBDATETIMN: {
                                        if (sybDateTimnBindNull[indexOfType] != -1) {
                                            DBDATEREC dateinfo;
                                            memcpy(&sybDateTimeBind[indexOfType], (DBDATETIME *) (dbdata(dbconn, (columnNumber + 1))), sizeof(DBDATETIME));
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
                                            NSDate *date = [[gregorian dateFromComponents:comps] retain];
                                            //NSLog(@"%@\t\t(SYBDATETIMN):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], date);
                                            [resultsForRow setObject:date forKey:fieldName];
                                            [date release];
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBBIT: {
                                        if (sybBitBindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithBool:(BOOL)sybBitBind[indexOfType]];
                                            //NSLog(@"%@\t\t(SYBBIT):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBBITN: {
                                        if (sybBitNBindNull[indexOfType] != -1) {
                                            NSNumber *object = [[NSNumber alloc] initWithInt:(BOOL)sybBitNBind[indexOfType]];
                                            //NSLog(@"%@\t\t(SYBBITN):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                            [resultsForRow setObject:object forKey:fieldName];
                                            [object release];
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    case SYBIMAGE: {
                                        if (sybImageBindNull[indexOfType] != -1) {
                                            //NSLog(@"%@\t\t(SYBMONEY): Not supported", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0]);
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBMONEY: {
                                        if (sybMoneyBindNull[indexOfType] != -1) {
                                            double money = sybMoneyBind[indexOfType];
                                            //NSLog(@"%@\t\t(SYBMONEY):\t\t%f", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], money);
                                            NSNumber *moneyNumber = [[NSNumber alloc] initWithDouble:money];
                                            [resultsForRow setObject:moneyNumber forKey:fieldName];
                                            [moneyNumber release];
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBMONEYN: {
                                        if (sybMoneyNBindNull[indexOfType] != -1) {
                                            double money = sybMoneyNBind[indexOfType];
                                            //NSLog(@"%@\t\t(SYBMONEYN):\t\t%f", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], money);
                                            NSNumber *moneyNumber = [[NSNumber alloc] initWithDouble:money];
                                            [resultsForRow setObject:moneyNumber forKey:fieldName];
                                            [moneyNumber release];
                                            
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBBINARY: {
                                        if (sybBinaryBindNull[indexOfType] != -1) {
                                            NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                            [resultsForRow setObject:notSupported forKey:fieldName];
                                            //NSLog(@"%@\t\t(SYBBINARY):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], notSupported);
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBVOID: {
                                        if (sybVoidBindNull[indexOfType] != -1) {
                                            NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                            [resultsForRow setObject:notSupported forKey:fieldName];
                                            //NSLog(@"%@\t\t(SYBVOID):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], notSupported);
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                    case SYBVARBINARY: {
                                        if (sybVarBinaryBindNull[indexOfType] != -1) {
                                            NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                            [resultsForRow setObject:notSupported forKey:fieldName];
                                            //NSLog(@"%@\t\t(SYBVARBINARY):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], notSupported);
                                        } else {
                                            [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                                        }
                                        break;
                                    }
                                        
                                    default:
                                        break;
                                }
                                
                                [fieldName release];
                                [columnMetaData release];
                                columnCounter++;
                            }
                            
                            [results addObject: resultsForRow];
                            [resultsForRow release];
                            
                        }
                        
                        [columnPercision release];
                        
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
                    
                    [colmunHolder release];
                    [counters release];
                    
                }
                
                dbclose(dbconn);
                
            }
            
            
            
            
            [janFirst1990 release];
            [janFirst1990Components release];
            [gregorian release];
        }
        dispatch_semaphore_signal(semaphoreRunQuery);
    }];
    
    dispatch_semaphore_wait(semaphoreRunQuery, DISPATCH_TIME_FOREVER);
    dispatch_release(semaphoreRunQuery);

     
    return [results autorelease];
    
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
        
        NSString *systemMessage = [NSString stringWithCString:osstr encoding:NSUTF8StringEncoding];
        NSString *dbMessage = [NSString stringWithCString:dbstr encoding:NSUTF8StringEncoding];
        NSString *errorMessage = [NSString stringWithFormat:@"System says: \"(%d)%@.\"\nDatabase says: \"(%d)%@.\"", oserr, systemMessage, dberr, dbMessage];
        
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : errorMessage};
        NSError *error = [NSError errorWithDomain:@"MTDatabaseTds" code:565 userInfo:errorInfo];
        
        __block BOOL continueToGo = YES;
        dispatch_semaphore_t showError = dispatch_semaphore_create(0);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [error presentErrorToUserWithContinue:^(BOOL success) {
                continueToGo = success;
                dispatch_semaphore_signal(showError);
            }];
        });
        dispatch_semaphore_wait(showError, DISPATCH_TIME_FOREVER);
        dispatch_release(showError);
        
        if (continueToGo) {
            result = INT_CONTINUE;
        } else {
            result = INT_CANCEL;
        }
    }
    
    });
    return result;
}

- (void)connectWithCredentals:(MTDatabaseConnection *)credentals completion:(void (^)(DBPROCESS *dbconn, BOOL success, NSError *error))completion {
    
    NSString *key = [NSString stringWithFormat:@"[%@:%d]%@", [credentals server],  [credentals port], [credentals database]];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *connectionError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queuePriorityBackground, ^{
            
            if (success) {
                
                DBPROCESS *dbconn = NULL;
                BOOL connected;
                NSError *error = nil;
                
                
                LOGINREC *login;
                char hostname[30];
                int max_len = 30;
                
                
                /* Init the DB library */
                if (dbinit() == FAIL) {
                    NSString *message = @"Could not init db.";
                    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                    error = [NSError errorWithDomain:@"MTDatabaseTds" code:1 userInfo:errorInfo];
                }
                dberrhandle(err_handler);
                
                if ((error == nil) && ((login = dblogin()) == FAIL)) {
                    NSString *message = @"Could not initialize dblogin() structure.";
                    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                    error = [NSError errorWithDomain:@"MTDatabaseTds" code:2 userInfo:errorInfo];
                }
                
                //char *h = (char *)[[credentals objectForKey:MTDatabaseConnectionHost] cStringUsingEncoding:NSUTF8StringEncoding];
                char *s = (char *)[[credentals server] cStringUsingEncoding:NSUTF8StringEncoding];
                
                if (error == nil) {
                    /* Initialize the login params in the structure */
                    DBSETLUSER(login, [username cStringUsingEncoding:NSUTF8StringEncoding]);
                    DBSETLPWD(login, [password cStringUsingEncoding:NSUTF8StringEncoding]);
                    DBSETLAPP(login, [[credentals appname] cStringUsingEncoding:NSUTF8StringEncoding]);
                    DBSETLDBNAME(login, [[credentals database] cStringUsingEncoding:NSUTF8StringEncoding]);
                    
                    
                    if (gethostname(hostname, max_len) == 0) {
                        DBSETLHOST(login, hostname);
                    }
                    
                }
                
                if (error == nil) {
                    if ((dbconn = dbopen(login, s)) == NULL) {
                        NSString *message = [NSString stringWithFormat:@"Could not connect to DB Server: %s\n", s];
                        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                        error = [NSError errorWithDomain:@"MTDatabaseTds" code:2 userInfo:errorInfo];
                    }
                }
                
                
                connected = (error == nil);
                if (!fromKeyChain && connected) {
                    dispatch_semaphore_t semaphoreSaveCredentials = dispatch_semaphore_create(0);
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key completion:^(BOOL success, NSError *error) {
                            dispatch_semaphore_signal(semaphoreSaveCredentials);
                        }];
                    });
                    dispatch_semaphore_wait(semaphoreSaveCredentials, DISPATCH_TIME_FOREVER);
                    dispatch_release(semaphoreSaveCredentials);
                    
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(dbconn, connected, error);
                });
                
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(nil, NO, connectionError);
                });
            }
            
        });
        
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

@end
