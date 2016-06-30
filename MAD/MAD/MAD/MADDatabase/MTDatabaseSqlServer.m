//
//  MTDatabaseSqlServer.m
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSqlServer.h"

#import <Foundation/NSException.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNULL.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSError.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSTimeZone.h>

#import <string.h>
#import <stdlib.h>
#import <unistd.h>

#import <dispatch/time.h>
#import <dispatch/queue.h>
#import <dispatch/semaphore.h>

#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MADDataColumn.h>

#import <MADTdsClient/sybdb.h>

#import "MTDatabaseConnectionSqlServer.h"

#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"

#import "MTQuery.h"
#import "MTKeyChain.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqDatabaseSchemaField.h"

#import "RptqQueryTable.H"
#import "RptqQueryTable+Extras.h"

#import "RptqQueryField.h"

#import "MTDatabaseProcessSqlServer.h"

#import "MADCredential.h"

#import "MADDatabaseProtocol.h"

NSString * const MTDatabaseConnectionUsername   = @"MTDatabaseConnectionUsername";
NSString * const MTDatabaseConnectionPassword   = @"MTDatabaseConnectionPassword";
NSString * const MTDatabaseConnectionDatabase   = @"MTDatabaseConnectionDatabase";
NSString * const MTDatabaseConnectionPort       = @"MTDatabaseConnectionPort";
NSString * const MTDatabaseConnectionHost       = @"MTDatabaseConnectionHost";
NSString * const MTDatabaseConnectionServer     = @"MTDatabaseConnectionServer";
NSString * const MTDatabaseConnectionAppName    = @"MTDatabaseConnectionAppName";
NSString * const MADNotificationError           = @"MADNotificationError";


static NSString * const MTDatabaseColumnTypeId         = @"MTDatabaseColumnTypeId";
static NSString * const MTDatabaseColumnNameId         = @"MTDatabaseColumnNameId";
static NSString * const MTDatabaseColumnNumberId       = @"MTDatabaseColumnNumberId";
static NSString * const MTDatabaseColumnDataLenId      = @"MTDatabaseColumnDataLenId";
static NSString * const MTDatabaseColumnLenId          = @"MTDatabaseColumnLenId";
static NSString * const MTDatabaseColumnIndexOfType    = @"MTDatabaseColumnIndexOfType";
static NSString * const MTDatabaseColumnPrecision      = @"MTDatabaseColumnPrecision";

static NSString * const MADDomainTDS = @"MTDatabaseTds";

@interface MTDatabaseSqlServer ()

    @property (nonatomic, strong) MTDatabaseConnectionSqlServer *databaseConnection;

@end

@implementation MTDatabaseSqlServer

@dynamic databaseConnection;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleError:)
                                                     name: MADNotificationError object: nil];
    }
    return self;
}

- (void)handleError:(NSNotification *)notification {
    [self.errors addObject:notification.object];
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
            
            MTDatabaseConnection *databaseConnection = blockSelf.databaseConnection;
            DBPROCESS *dbconn = (__bridge DBPROCESS *)([blockSelf connectWithConnection:databaseConnection credentals:nil]);

            if (dbconn) {
                
                id results = nil;
                NSError *error = nil;

                dbcmd(dbconn, "SELECT name FROM sys.tables");
                
                RETCODE success = dbsqlexec(dbconn);
                
                if (success != SUCCEED) {
                    
                    NSString *message = @"Sql Syntax Error";
                    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                    error = [NSError errorWithDomain:MADDomainTDS code:33534 userInfo:errorInfo];
                    
                }
                
                int numberOfColumns = dbnumcols(dbconn);
                
                results = [[NSMutableArray alloc] initWithCapacity: (NSUInteger)numberOfColumns];
                
                while (dbresults(dbconn) != NO_MORE_RESULTS) {
                    
                    //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
                    DBINT columnLength      = dbcollen(dbconn, 1);
                    char *sybVarCharBind;
                    DBINT sybVarCharBindNull;
                    
                    sybVarCharBind = malloc( sizeof(char) * (unsigned long)( columnLength + 1 ) );
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
                
                completion(error == nil, error, results);
            } else {
                NSString *message = @"No Connection";
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                NSError *error = [NSError errorWithDomain: MADDomainTDS
                                                     code: 24244
                                                 userInfo: errorInfo];
                completion(NO, error, nil);
            }

            blockSelf = nil;
        });
    });
}

+ (MADDataType)dataTypeForNativeType:(NSInteger)nativeType {
    MADDataType result;
    switch (nativeType) {
        case SYBDATETIMN:
            result = MADDataTypeDateTime;
            break;
        case SYBDATETIME:
            result = MADDataTypeDateTime;
            break;
        case SYBDATETIME4:
            result = MADDataTypeDateTime;
            break;
        case SYBCHAR:
            result = MADDataTypeString;
            break;
        case SYBVARCHAR:
            result = MADDataTypeString;
            break;
        case SYBTEXT:
            result = MADDataTypeString;
            break;
        case SYBNTEXT:
            result = MADDataTypeString;
            break;
        case SYBNVARCHAR:
            result = MADDataTypeString;
            break;
        case SYBBIT:
            result = MADDataTypeBit;
            break;
        case SYBBITN:
            result = MADDataTypeBit;
            break;
        case SYBINT1:
            result = MADDataTypeInteger;
            break;
        case SYBINT2:
            result = MADDataTypeInteger;
            break;
        case SYBINT4:
            result = MADDataTypeInteger;
            break;
        case SYBINT8:
            result = MADDataTypeInteger;
            break;
        case SYBINTN:
            result = MADDataTypeInteger;
            break;
        case SYBMONEY:
            result = MADDataTypeFloat;
            break;
        case SYBMONEYN:
            result = MADDataTypeFloat;
            break;
        case SYBREAL:
            result = MADDataTypeFloat;
            break;
        case SYBFLT8:
            result = MADDataTypeFloat;
            break;
        case SYBFLTN:
            result = MADDataTypeFloat;
            break;
        case SYBNUMERIC:
            result = MADDataTypeDecimal;
            break;
        case SYBIMAGE:
            result = MADDataTypeBlob;
            break;
        case SYBBINARY:
            result = MADDataTypeBlob;
            break;
        case SYBVOID:
            result = MADDataTypeBlob;
            break;
        case SYBVARBINARY:
            result = MADDataTypeBlob;
            break;
        default:
            result = MADDataTypeString;
            break;
    }
    return result;
}

- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error {
    BOOL success = NO;
    MTDatabaseProcessSqlServer *dbconn = [self connectWithConnection:self.databaseConnection credentals:nil];
    if (dbconn) {
        success = [self runQuery:query onProcess:dbconn withError: NULL];
    }
    return success;
}

- (BOOL)runQuery:(MTQuery *)query onProcess:(MTDatabaseProcessSqlServer *)process withError:(NSError * __autoreleasing *)error {
    BOOL success = NO;
    MTDataTable *dataTable;
    if (query.dataTable) {
        dataTable = query.dataTable;
    } else {
        dataTable = [self.delegate dataTableForQuery:query];
    }

    NSError *sqlError = nil;
    NSString *sql = [query getSqlWithError:&sqlError];
    if (sqlError == nil) {
        success = [self runSQL:sql onDataTable:dataTable fieldKeys:query.fieldKeys process:process];
    }
    return success;
}

- (BOOL)executeSql:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn intoResultTable:(MTDataTable *)dataTable withError:(NSError * __autoreleasing *)error {
    return [self runSQL:sql onDataTable:dataTable fieldKeys:fieldKeys process:dbconn];
}

- (BOOL)runSQL:(NSString *)sql onDataTable:(MTDataTable *)datatable fieldKeys:(NSArray *)fieldKeys process:(MTDatabaseProcessSqlServer *)process {

    BOOL rsuccess = NO;
    NSError *error = nil;
    if (sql.length > 0) {
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        NSDateComponents *janFirst1990Components = [[NSDateComponents alloc] init];
        janFirst1990Components.year =    1900;
        janFirst1990Components.month =   1;
        janFirst1990Components.day =     0;
        janFirst1990Components.hour =    0;
        janFirst1990Components.minute =  0;
        janFirst1990Components.second =  0;
        
        NSDate *janFirst1990 = [gregorian dateFromComponents:janFirst1990Components];
        
        RETCODE success = FAIL;
        
        DBPROCESS *dbconn = [process process];
        if (dbconn) {
            
            dbcmd(dbconn, [sql cStringUsingEncoding:NSUTF8StringEncoding]);
            success = dbsqlexec(dbconn);
            
            if (success == SUCCEED) {
                
                NSString *decimalSeperator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
                
                BOOL tdsDecimalSeperatorMatchesCocoaDecimalSeperator = NO;
                BOOL tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = NO;
                
                int numberOfColumns = dbnumcols(dbconn);
                NSMutableArray *colmunHolder = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)numberOfColumns];
                static int disregardedBind = -1023;
                
                NSNumber *keySYBDATETIMN = [[NSNumber alloc] initWithInt: SYBDATETIMN];
                NSNumber *keySYBDATETIME = [[NSNumber alloc] initWithInt: SYBDATETIME];
                NSNumber *keySYBDATETIME4 = [[NSNumber alloc] initWithInt: SYBDATETIME4];
                NSNumber *keySYBCHAR = [[NSNumber alloc] initWithInt: SYBCHAR];
                NSNumber *keySYBVARCHAR = [[NSNumber alloc] initWithInt: SYBVARCHAR];
                NSNumber *keySYBTEXT = [[NSNumber alloc] initWithInt: SYBTEXT];
                NSNumber *keySYBNTEXT = [[NSNumber alloc] initWithInt: SYBNTEXT];
                NSNumber *keySYBNVARCHAR = [[NSNumber alloc] initWithInt: SYBNVARCHAR];
                NSNumber *keySYBBIT = [[NSNumber alloc] initWithInt: SYBBIT];
                NSNumber *keySYBBITN = [[NSNumber alloc] initWithInt: SYBBITN];
                NSNumber *keySYBINT1 = [[NSNumber alloc] initWithInt: SYBINT1];
                NSNumber *keySYBINT2 = [[NSNumber alloc] initWithInt: SYBINT2];
                NSNumber *keySYBINT4 = [[NSNumber alloc] initWithInt: SYBINT4];
                NSNumber *keySYBINT8 = [[NSNumber alloc] initWithInt: SYBINT8];
                NSNumber *keySYBINTN = [[NSNumber alloc] initWithInt: SYBINTN];
                NSNumber *keySYBMONEY = [[NSNumber alloc] initWithInt: SYBMONEY];
                NSNumber *keySYBMONEYN = [[NSNumber alloc] initWithInt: SYBMONEYN];
                NSNumber *keySYBREAL = [[NSNumber alloc] initWithInt: SYBREAL];
                NSNumber *keySYBFLT8 = [[NSNumber alloc] initWithInt: SYBFLT8];
                NSNumber *keySYBFLTN = [[NSNumber alloc] initWithInt: SYBFLTN];
                NSNumber *keySYBNUMERIC = [[NSNumber alloc] initWithInt: SYBNUMERIC];
                NSNumber *keySYBIMAGE = [[NSNumber alloc] initWithInt: SYBIMAGE];
                NSNumber *keySYBBINARY = [[NSNumber alloc] initWithInt: SYBBINARY];
                NSNumber *keySYBVOID = [[NSNumber alloc] initWithInt: SYBVOID];
                NSNumber *keySYBVARBINARY = [[NSNumber alloc] initWithInt: SYBVARBINARY];
                NSNumber *keyDisregardedBind = [[NSNumber alloc] initWithInt: disregardedBind];
                
                NSDictionary *countersStart = @{
                                                keySYBDATETIMN         : @0,     //Assumed good
                                                keySYBDATETIME         : @0,     //Good
                                                keySYBDATETIME4        : @0,     //Good
                                                
                                                keySYBCHAR             : @0,     //Good
                                                keySYBVARCHAR          : @0,     //Good
                                                keySYBTEXT             : @0,     //Good
                                                keySYBNTEXT            : @0,     //Good
                                                keySYBNVARCHAR         : @0,     //Good
                                                
                                                keySYBBIT              : @0,     //Good
                                                keySYBBITN             : @0,     //Assumed good
                                                keySYBINT1             : @0,     //Good
                                                keySYBINT2             : @0,     //Good
                                                keySYBINT4             : @0,     //Good
                                                keySYBINT8             : @0,     //Good
                                                keySYBINTN             : @0,     //Assumed good
                                                
                                                keySYBMONEY            : @0,     //Good, also handles SYBMONEY4
                                                keySYBMONEYN           : @0,     //Assumed good
                                                
                                                keySYBREAL             : @0,     //Good
                                                keySYBFLT8             : @0,     //Good
                                                keySYBFLTN             : @0,     //Assumed good, but may overflow
                                                
                                                keySYBNUMERIC          : @0,     //Converts to NSDecimalNumber...
                                                                                 //  Also handles SYBDECIMAL
                                                
                                                keySYBIMAGE            : @0,     //Currently not used
                                                keySYBBINARY           : @0,     //Currently not used
                                                keySYBVOID             : @0,     //Currently not used
                                                keySYBVARBINARY        : @0,     //Currently not used
                                                
                                                keyDisregardedBind     : @0
                                                
                                                };
                NSMutableDictionary *counters = [[NSMutableDictionary alloc] initWithDictionary:countersStart];
                
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
                        
                        NSString *fieldKey = fieldKeys[(NSUInteger)columnCtr];
                        
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
                        
                        MADDataColumn *dataColumn = [[MADDataColumn alloc] initWithIdentifier:columnNameString];
                        dataColumn.fieldName = columnNameString;
                        dataColumn.nativeType = columnType;
                        dataColumn.type = [MTDatabaseSqlServer dataTypeForNativeType:columnType];
                        dataColumn.dataLength = columnLength;
                        dataColumn.dataPercision = -1;
                        
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
                    
                    NSInteger resultCountForType = numberOfItemsOfType(SYBREAL, counters);
                    double sybRealBind[resultCountForType];
                    DBINT sybRealBindNull[resultCountForType];
                    
                    
                    resultCountForType = numberOfItemsOfType(SYBFLTN, counters);
                    double sybFltNBind[resultCountForType];
                    DBINT sybFltNBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBFLT8, counters);
                    double sybFlt8Bind[resultCountForType];
                    DBINT sybFlt8BindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBINT1, counters);
                    int sybInt1Bind[resultCountForType];
                    DBINT sybInt1BindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBINT2, counters);
                    int sybInt2Bind[resultCountForType];
                    DBINT sybInt2BindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBINTN, counters);
                    long long sybIntnBind[resultCountForType];
                    DBINT sybIntnBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBINT4, counters);
                    int sybInt4Bind[resultCountForType];
                    DBINT sybInt4BindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBINT8, counters);
                    long long sybInt8Bind[resultCountForType];
                    DBINT sybInt8BindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBMONEY, counters);
                    double sybMoneyBind[resultCountForType];
                    DBINT sybMoneyBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBMONEYN, counters);
                    double sybMoneyNBind[resultCountForType];
                    DBINT sybMoneyNBindNull[resultCountForType];
                    
                    NSInteger resultCountForTypeSybNumericBindChar = numberOfItemsOfType(SYBNUMERIC, counters);
                    char *sybNumericBindChar[resultCountForTypeSybNumericBindChar];
                    DBINT sybNumericBindNull[resultCountForTypeSybNumericBindChar];
                    for (NSInteger i=0; i<resultCountForTypeSybNumericBindChar; i++) {
                        sybNumericBindChar[i] = '\0';
                    }
                    
                    NSInteger resultCountForTypeSybCharBind = numberOfItemsOfType(SYBCHAR, counters);
                    char *sybCharBind[resultCountForTypeSybCharBind];
                    DBINT sybCharBindNull[resultCountForTypeSybCharBind];
                    for (NSInteger i=0; i<resultCountForTypeSybCharBind; i++) {
                        sybCharBind[i] = '\0';
                    }
                    
                    NSInteger resultCountForTypeSybVarCharBind = numberOfItemsOfType(SYBVARCHAR, counters);
                    char *sybVarCharBind[resultCountForTypeSybVarCharBind];
                    DBINT sybVarCharBindNull[resultCountForTypeSybVarCharBind];
                    for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
                        sybVarCharBind[i] = '\0';
                    }
                    
                    NSInteger resultCountForTypeSybnVarCharBind = numberOfItemsOfType(SYBNVARCHAR, counters);
                    char *sybnVarCharBind[resultCountForTypeSybnVarCharBind];
                    DBINT sybnVarCharBindNull[resultCountForTypeSybnVarCharBind];
                    for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
                        sybnVarCharBind[i] = '\0';
                    }
                    
                    NSInteger resultCountForTypeSybTextBind = numberOfItemsOfType(SYBTEXT, counters);
                    char *sybTextBind[resultCountForTypeSybTextBind];
                    DBINT sybTextBindNull[resultCountForTypeSybTextBind];
                    for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
                        sybTextBind[i] = '\0';
                    }
                    
                    NSInteger resultCountForTypeSybnTextBind = numberOfItemsOfType(SYBNTEXT, counters);
                    char *sybnTextBind[resultCountForTypeSybnTextBind];
                    DBINT sybnTextBindNull[resultCountForTypeSybnTextBind];
                    for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
                        sybnTextBind[i] = '\0';
                    }
                    
                    resultCountForType = numberOfItemsOfType(SYBDATETIME, counters);
                    DBDATETIME *sybDateTimeBind[resultCountForType];
                    DBINT sybDateTimeBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBDATETIME4, counters);
                    DBDATETIME4 *sybDateTime4Bind[resultCountForType];
                    DBINT sybDateTime4BindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBDATETIMN, counters);
                    DBDATETIME *sybDateTimnBind[resultCountForType];
                    DBINT sybDateTimnBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBIMAGE, counters);
                    BYTE *sybImageBind[resultCountForType];
                    DBINT sybImageBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBBINARY, counters);
                    DBINT sybBinaryBind[resultCountForType];
                    DBINT sybBinaryBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBVARBINARY, counters);
                    //void *sybVarBinaryBind[resultCountForType];
                    DBINT sybVarBinaryBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBVOID, counters);
                    //void *sybVoidBind[resultCountForType];
                    DBINT sybVoidBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBBIT, counters);
                    BOOL sybBitBind[resultCountForType];
                    DBINT sybBitBindNull[resultCountForType];
                    
                    resultCountForType = numberOfItemsOfType(SYBBITN, counters);
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
                    NSMutableArray *columnPercision = [[NSMutableArray alloc] initWithCapacity:colmunHolder.count];
                    for (NSInteger i = 0; i<colmunHolder.count; i++) {
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
                                            switch (seperator.length) {
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
                                        offsetCompsDays.day = smallDate.days;
                                        
                                        NSDate *object = [gregorian dateByAddingComponents:offsetCompsDays toDate:janFirst1990 options:0];
                                        
                                        
                                        NSDateComponents *smallDaysComponentsPart1 = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay)
                                                                                                  fromDate:object];
                                        
                                        NSDateComponents *offsetCompsWithMinutes = [[NSDateComponents alloc] init];
                                        
                                        NSInteger hours = smallDate.minutes / 60;
                                        NSInteger minutes = smallDate.minutes - (hours * 60);
                                        offsetCompsWithMinutes.hour =    hours;
                                        offsetCompsWithMinutes.minute =  minutes;
                                        offsetCompsWithMinutes.year =    smallDaysComponentsPart1.year;
                                        offsetCompsWithMinutes.month =   smallDaysComponentsPart1.month;
                                        offsetCompsWithMinutes.day =     smallDaysComponentsPart1.day;
                                        offsetCompsWithMinutes.second =  0;
                                        
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
                                        comps.year = dateinfo.dateyear;
                                        comps.month = dateinfo.datemonth + 1;
                                        comps.day = dateinfo.datedmonth;
                                        comps.hour = dateinfo.datehour;
                                        comps.minute = dateinfo.dateminute;
                                        comps.second = dateinfo.datesecond;
                                        comps.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(60*60*dateinfo.datetzone)];
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
                                        comps.year = dateinfo.dateyear;
                                        comps.month = dateinfo.datemonth + 1;
                                        comps.day = dateinfo.datedmonth;
                                        comps.hour = dateinfo.datehour;
                                        comps.minute = dateinfo.dateminute;
                                        comps.second = dateinfo.datesecond;
                                        comps.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(60*60*dateinfo.datetzone)];
                                        NSCalendar *gregorian = [[NSCalendar alloc]
                                                                 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
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
                
                rsuccess = YES;
                
            } else {
                NSString *message = @"Sql Syntax Error";
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                error = [NSError errorWithDomain:MADDomainTDS code:87635 userInfo:errorInfo];
                rsuccess = NO;
            }
            dbclose(dbconn);
            
        } else {
            NSString *title = NSLocalizedString(@"Bad Process", @"Bad Process");
            NSString *message = NSLocalizedString(@"Could not run this query.", @"Could not run this query.");
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : message};
            NSError *error = [NSError errorWithDomain:MADDomainTDS code:4379 userInfo:errorInfo];
            rsuccess = NO;
        }
        
    } else {
        NSString *title = NSLocalizedString(@"Bad Query", @"Bad Query");
        NSString *message = NSLocalizedString(@"Could not run this query.", @"Could not run this query.");
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : message};
        NSError *error = [NSError errorWithDomain:MADDomainTDS code:4378 userInfo:errorInfo];
        rsuccess = NO;
    }
    return rsuccess;
}

static inline NSInteger numberOfItemsOfType(int type, NSMutableDictionary *counters);
static inline NSInteger numberOfItemsOfType(int type, NSMutableDictionary *counters) {
    NSNumber *key = @(type);
    NSNumber * __autoreleasing counter = counters[key];
    return counter ? counter.integerValue : 0;
}

- (NSInteger)numberOfItemsOfType:(int)type withCounters:(NSMutableDictionary *)counters {
    NSNumber *key = @(type);
    NSNumber *counter = counters[key];
    return counter ? counter.integerValue : 0;
}

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr);
int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {

    int result = INT_CANCEL;

    
        if (severity >= 5 || dberr == SYBEINTF) {
            NSString *title = NSLocalizedString(@"Caught an Error", @"Caught an Error");
            char *osstr = (oserrstr != NULL ? oserrstr : "");
            char *dbstr = (dberrstr != NULL ? dberrstr : "");
            
            NSString *systemMessage = @(osstr);
            NSString *dbMessage = @(dbstr);
            NSString *errorMessage = [NSString stringWithFormat:@"System says: \"(%d)%@.\"\nDatabase says: \"(%d)%@.\"", oserr, systemMessage, dberr, dbMessage];
            
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : errorMessage};
            NSError *error = [NSError errorWithDomain:MADDomainTDS code:dberr userInfo:errorInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:MADNotificationError object:error];
            
                result = INT_CANCEL;
        }
    
    return result;
}

- (DBPROCESS *)connect:(NSString *)username andPassword:(NSString *)password error:(NSError * __autoreleasing *)error {

    DBPROCESS *dbconn = NULL;
    BOOL connected = NO;
    
    LOGINREC *login;
    char hostname[30];
    size_t max_len = 30;
    
    
    /* Init the DB library */
    if (dbinit() == FAIL) {
        NSString *message = @"Could not init db.";
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
        NSError *e = [NSError errorWithDomain:MADDomainTDS code:1 userInfo:errorInfo];
        if (e != nil) {
            *error = e;
        }
    }
    dberrhandle(err_handler);
    
    if (*error == nil) {
        login = dblogin();
        if (login == FAIL) {
            NSString *message = @"Could not initialize dblogin() structure.";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            *error = [NSError errorWithDomain:MADDomainTDS code:2 userInfo:errorInfo];
        }
        
        if (*error == nil) {
            /* Initialize the login params in the structure */
            const char *u = [username cStringUsingEncoding:NSUTF8StringEncoding];
            const char *p = [password cStringUsingEncoding:NSUTF8StringEncoding];
            NSString *appName = [self.databaseConnection appname];
            const char *a = [appName cStringUsingEncoding:NSUTF8StringEncoding];
            NSString *connection = (self.databaseConnection).database;
            const char *n = [connection cStringUsingEncoding:NSUTF8StringEncoding];
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
        
            NSString *IPAddress = [MTDatabaseConnection IPAddressForServer:self.databaseConnection.server];
            char *s = (char *)[IPAddress cStringUsingEncoding:NSUTF8StringEncoding];
            dbconn = dbopen(login, s);
            if (dbconn == NULL) {
                NSString *message = [NSString stringWithFormat:@"Could not connect to DB Server: %s\n", s];
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
                *error = [NSError errorWithDomain:MADDomainTDS code:2 userInfo:errorInfo];
            }
            
        }
        connected = (*error == nil);
        
        dbloginfree(login);
    }
    
    return dbconn;
}

- (id)connectWithConnection:(MTDatabaseConnection *)connection credentals:(MADCredential *)credentals {
    
    if (credentals == nil) {
        credentals = [self copyCredentalsWithConnection:connection];
    }
    
    DBPROCESS *dbconn = NULL;
    if (credentals != nil) {
        
        NSError *error = nil;
        dbconn = [self connect:credentals.username andPassword:credentals.password error:&error];
        MTDatabaseProcessSqlServer *dbwrap = nil;
        
        if (error) {
            [self.errors insertObject:error atIndex:0];
        } else {
            dbwrap = [[MTDatabaseProcessSqlServer alloc] initWithProcess:dbconn];
        }
        
    }

    return (__bridge id)(dbconn);
}

- (NSString *)identifier {
    return MADIdentifierDatabaseTDS;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseTDS;
}

- (id)connectionSettings {
    return self.databaseConnection;
}

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    MADSafeQueryField *safeQueryField = [[MADSafeQueryField alloc] initWithFormat:@"[%@].[%@]", tableName, fieldName];
    return safeQueryField;
}
- (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [MTDatabaseSqlServer newSafeQueryField:fieldName andTable:tableName];
}

- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
    return [NSString stringWithFormat:@"[%@]", fieldOrTableName];
}

- (NSString *)sqlAggregateFunctionLength {
    return @"DATALENGTH";
}

- (NSString *)selectPart {
    return [self selectPartWithLimitedResults:NSUIntegerMax];  // No limit by default
}

- (NSString *)selectPartWithLimitedResults:(NSUInteger)limit {
    NSString *selectPart = [super selectPart];
    return limit > 0 && limit != NSUIntegerMax ?
                [selectPart stringByAppendingFormat:@"TOP %ld\n", (long)limit] : selectPart;
}

- (NSString *)sqlLimitClause {
    return @"";
}

- (NSString *)sqlLimitClause:(NSUInteger)limit {
    return @"";
}

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName {
    
    MADSafeQueryField *safeField = [self newSafeQueryField: fieldName
                                      andTable: tableName];
    NSString *safeFieldAlias = [self fieldAliasForField: fieldName
                                      withSafeTableName: tableName];
    MADSafeQueryField *safeTable = [self newSafeIdentifier: tableName];
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT TOP 511 "
                     @"%@ %@ %@ "
                     @"%@ %@ ",
                     safeField, [self tableAliasConnector], safeFieldAlias,
                     MADSqlTextFromPart, safeTable];
    return sql;
}

#pragma mark - Reading Tables

- (NSArray <MTDatabaseTable *> *)getTablesFromConnection:(id)process error:(NSError * __autoreleasing *)outError {
    id results = nil;
//    NSError *error = nil;
    DBPROCESS *dbconn = [process process];
    if (dbconn) {
        
        dbcmd(dbconn, "SELECT name FROM sys.tables");
        
        RETCODE success = dbsqlexec(dbconn);
        
        if (success != SUCCEED) {
            
            NSString *message = @"Sql Syntax Error";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            *outError = [NSError errorWithDomain:MADDomainTDS code:534 userInfo:errorInfo];
            
        }
        
        int numberOfColumns = dbnumcols(dbconn);
        
        results = [[NSMutableArray alloc] initWithCapacity: (NSUInteger)numberOfColumns];
        
        while (dbresults(dbconn) != NO_MORE_RESULTS) {
            
            //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
            DBINT columnLength      = dbcollen(dbconn, 1);
            char *sybVarCharBind;
            DBINT sybVarCharBindNull;
            
            sybVarCharBind = malloc((size_t) sizeof(char) * (unsigned long)( columnLength + 1 ) );
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
    return results;
}

- (void)enumerateTablesFromConnection:(id)process
                           usingBlock:(void (^)(MTDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion {
    id results = nil;
    NSError *error = nil;
    DBPROCESS *dbconn = [process process];
    if (dbconn) {
        
        dbcmd(dbconn, "SELECT name FROM sys.tables");
        
        RETCODE success = dbsqlexec(dbconn);
        
        if (success != SUCCEED) {
            
            NSString *message = @"Sql Syntax Error";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            error = [NSError errorWithDomain:MADDomainTDS code:534 userInfo:errorInfo];
            
        }
        
        int numberOfColumns = dbnumcols(dbconn);
        
        results = [[NSMutableArray alloc] initWithCapacity: (NSUInteger)numberOfColumns];
        
        while (dbresults(dbconn) != NO_MORE_RESULTS) {
            
            //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
            DBINT columnLength      = dbcollen(dbconn, 1);
            char *sybVarCharBind;
            DBINT sybVarCharBindNull;
            
            sybVarCharBind = malloc((size_t) sizeof(char) * (unsigned long)( columnLength + 1 ) );
            dbbind(dbconn, 1, NTBSTRINGBIND, columnLength, (BYTE *)sybVarCharBind);
            dbnullbind(dbconn, 1, &sybVarCharBindNull);
            
            NSUInteger counter = 0;
            BOOL stop = NO;
            while (dbnextrow(dbconn) != NO_MORE_ROWS) {
                
                if (sybVarCharBindNull != -1 && sybVarCharBind != NULL) {
                    
                    NSString *tableName = [[NSString alloc] initWithCString: sybVarCharBind
                                                                   encoding: NSStringEncodingConversionAllowLossy];
                    
                    MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                    [results addObject:table];
                    
                    block(table, counter, &stop);
                    if (stop) break;
                    counter++;
                }
            }
            free(sybVarCharBind);
        }
    }
    completion(error == nil, error, results);
}

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
            error = [NSError errorWithDomain:MADDomainTDS code:534 userInfo:errorInfo];
            
        }
        
        int numberOfColumns = dbnumcols(dbconn);
        
        results = [[NSMutableArray alloc] initWithCapacity: (NSUInteger)numberOfColumns];
        
        while (dbresults(dbconn) != NO_MORE_RESULTS) {
            
            //DBINT columnNumberBytes = dbdatlen(dbconn, 1);
            DBINT columnLength      = dbcollen(dbconn, 1);
            char *sybVarCharBind;
            DBINT sybVarCharBindNull;
            
            sybVarCharBind = malloc((size_t) sizeof(char) * (unsigned long)( columnLength + 1 ) );
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

#pragma mark - Reading Fields

- (NSArray *)fieldsForTable: (NSString *)tableName connection:(id)process error:(NSError * __autoreleasing *)error {
    NSMutableArray *results = nil;
    RETCODE sqlReturnCode = FAIL;
    DBPROCESS *dbconn = [process process];
    if (dbconn) {
        NSString *query = [NSString stringWithFormat:@"SELECT name, system_type_id, max_length, precision, scale FROM sys.columns WHERE object_id = OBJECT_ID('%@')", tableName];
        dbcmd(dbconn, [query cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
        
        sqlReturnCode = dbsqlexec(dbconn);
        
        if (sqlReturnCode != SUCCEED && error == NULL) {
            NSString * const message = @"Sql Syntax Error";
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
            *error = [NSError errorWithDomain:MADDomainTDS code:3456 userInfo:errorInfo];
            NSAssert(error == NULL, @"Syntax error fields for table: %@", *error);
        }
        
        int numberOfColumns = dbnumcols(dbconn);
        
        results = [[NSMutableArray alloc] initWithCapacity: (NSUInteger)numberOfColumns];
        
        //BOOL success = success == SUCCEED;
        //NSMutableDictionary *resultsDictionary = nil;
        
        if (sqlReturnCode == SUCCEED) {
            
            while (dbresults(dbconn) != NO_MORE_RESULTS) {
                
                //DBINT columnNumberBytes     = dbdatlen(dbconn, 1);
                DBINT nameLenght            = dbcollen(dbconn, 1);
                //DBINT typeLenght            = dbcollen(dbconn, 2);
                //DBINT lengthLenght          = dbcollen(dbconn, 3);
                //DBINT percisionLenght       = dbcollen(dbconn, 4);
                //DBINT scaleLenght           = dbcollen(dbconn, 5);
                
                //int columnType1 = dbcoltype(dbconn, 1);
                //int columnType2 = dbcoltype(dbconn, 2);
                //int columnType3 = dbcoltype(dbconn, 3);
                //int columnType4 = dbcoltype(dbconn, 4);
                //int columnType5 = dbcoltype(dbconn, 5);
                
                char *nameBind;
                int typeBind, lengthBind, percisionBind, scaleBind;
                
                DBINT nameBindNull, typeBindNull, lengthBindNull, percisionBindNull, scaleBindNull;
                NSInteger nameSize = ( nameLenght + 1 );
                nameBind = malloc( sizeof(char) * (unsigned long)nameSize );
                dbbind(dbconn, 1, NTBSTRINGBIND, ( nameLenght + 1 ), (BYTE *)nameBind);
                dbnullbind(dbconn, 1, &nameBindNull);
                
                dbbind(dbconn, 2, INTBIND, sizeof(int), (BYTE *)&typeBind);
                dbnullbind(dbconn, 2, &typeBindNull);
                
                dbbind(dbconn, 3, INTBIND, sizeof(int), (BYTE *)&lengthBind);
                dbnullbind(dbconn, 3, &lengthBindNull);
                
                dbbind(dbconn, 4, INTBIND, sizeof(int), (BYTE *)&percisionBind);
                dbnullbind(dbconn, 4, &percisionBindNull);
                
                dbbind(dbconn, 5, INTBIND, sizeof(int), (BYTE *)&scaleBind);
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
                        databaseField.fieldTypeNative = [MTDatabaseSqlServer dataTypeForNativeType:typeBind];
                        databaseField.fieldType = databaseField.fieldTypeNative;
                        databaseField.width = (NSUInteger)lengthBind;
                        databaseField.decimals = (NSUInteger)scaleBind;
                        databaseField.primaryKey = 0;
                        
                        [results addObject:databaseField];
                        
                    }
                }
                free(nameBind);
            }
        }
    }
    return results;
}

@end
