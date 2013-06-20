//
//  libTdsClient.m
//  libTdsClient
//
//  Created by Michael Thomason on 6/6/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTTdsClient.h"

#import "sybdb.h"

@interface MTTdsClient()

@property (nonatomic, copy) NSDictionary *credentals;

@end

@implementation MTTdsClient

NSString * const MTDatabaseKeyUsername                              = @"MTDatabaseKeyUsername";
NSString * const MTDatabaseKeyPassword                              = @"MTDatabaseKeyPassword";
NSString * const MTDatabaseKeyDatabase                              = @"MTDatabaseKeyDatabase";
NSString * const MTDatabasePortKey                                  = @"MTDatabaseKeyPort";
NSString * const MTDatabaseKeyHost                                  = @"MTDatabaseKeyHost";
NSString * const MTDatabaseKeyServer                                = @"MTDatabaseKeyServer";
NSString * const MTDatabaseKeyAppName                               = @"MTDatabaseKeyAppName";

- (void)dealloc {
    [_credentals release];
    [super dealloc];
}

- (id)initWithCredentals:(NSDictionary *)credentals {

    self = [super init];
    if (self) {

        if (credentals == nil) {
            credentals = @{MTDatabaseKeyUsername    : @"sa",
                           MTDatabaseKeyPassword    : @"1noniceguy",
                           MTDatabaseKeyDatabase    : @"master",
                           MTDatabaseKeyHost        : @"MICHAEL-PC",
                           MTDatabaseKeyServer      : @"10.0.1.3",
//                           MTDatabaseKeyServer      : @"SQLSERVERDEV",
//                           MTDatabaseHostKey        : @"MICHAEL-PC\\SQLSERVERDEV",
                           MTDatabaseKeyAppName     : @"MAD Designer"};
        }

        [self setCredentals:[credentals copy]];
        
    }
    return self;
}

- (id)runQuery:(NSString *)sql {
    
    
    DBPROCESS *dbconn;
    LOGINREC *login;
    char hostname[30];
    int max_len = 30;
    NSError *error = nil;
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    
    NSDateComponents *janFirst1990Components = [[NSDateComponents alloc] init];
    [janFirst1990Components setYear:    1900];
    [janFirst1990Components setMonth:   1];
    [janFirst1990Components setDay:     0];
    [janFirst1990Components setHour:    0];
    [janFirst1990Components setMinute:  0];
    [janFirst1990Components setSecond:  0];
    
    NSDate *janFirst1990 = [[gregorian dateFromComponents:janFirst1990Components] retain];
    

    
    /* Init the DB library */
    if (dbinit() == FAIL) {
        NSString *message = @"Could not init db.";
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
        error = [NSError errorWithDomain:@"MTDatabaseTds" code:1 userInfo:errorInfo];
    }
    
    if ((error == nil) && ((login = dblogin()) == FAIL)) {
        NSString *message = @"Could not initialize dblogin() structure.";
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
        error = [NSError errorWithDomain:@"MTDatabaseTds" code:2 userInfo:errorInfo];
    }

    char *h = (char *)[[[self credentals] objectForKey:MTDatabaseKeyHost] cStringUsingEncoding:NSUTF8StringEncoding];
    char *s = (char *)[[[self credentals] objectForKey:MTDatabaseKeyServer] cStringUsingEncoding:NSUTF8StringEncoding];

    if (error == nil) {
        /* Initialize the login params in the structure */
        DBSETLUSER(login, [[[self credentals] objectForKey:MTDatabaseKeyUsername] cStringUsingEncoding:NSUTF8StringEncoding]);
        DBSETLPWD(login, [[[self credentals] objectForKey:MTDatabaseKeyPassword] cStringUsingEncoding:NSUTF8StringEncoding]);
        DBSETLAPP(login, [[[self credentals] objectForKey:MTDatabaseKeyAppName] cStringUsingEncoding:NSUTF8StringEncoding]);
    
        //if (gethostname(h, max_len) == 0) {
        //    DBSETLHOST(login, h);
        //}

        //if (gethostname(hostname, max_len) == 0) {
        //    DBSETLHOST(login, hostname);
        //}

        //if (gethostname(hostname, max_len) == 0) {
            //DBSETLHOST(login, h);
        //}

 }
    
    if ((error == nil) && ((dbconn = dbopen(login, s)) == NULL)) {
        
        NSString *message = [NSString stringWithFormat:@"Could not connect to DB Server: %s\n", h];
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
        error = [NSError errorWithDomain:@"MTDatabaseTds" code:2 userInfo:errorInfo];

    }
    
    RETCODE success = SUCCEED;
    
    
    if (error == nil) {
        
        /*
         "SELECT TestDate, TestDateTime, TestDateTime2, TestDateTimeOffset, TestSmallDateTime, TestTime, TestTimestamp FROM food_des"
         */
        
        dbcmd(dbconn,
              "SELECT TestSmallMoney, TestMoney FROM food_des");
        
        /*
         , TestBigInt, TestBinary50, TestBit, TestChar, TestDate, TestDateTime, TestDateTime2, TestDateTimeOffset, TestDecimal, TestFloat, TestHierarchyId, TestImage, TestInt, TestMoney, TestNChar, TestNText, TestNumeric2, TestNVarChar50, TestNVarCharMax, TestReal, TestSmallDateTime, TestSmallInt, TestSmallMoney, TestSqlVariant, TestText, TestTime, TestTimestamp, TestTinyInt, TestXml
         */
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
                
            DBINT columnTypeUser = dbcolutype(dbconn, columnOffsetCtr);
            const char *typeForDisplay = dbprtype(columnType);
            const char *typeForDisplayUser = dbprtype(columnTypeUser);

            if (columnType >= 0) {
                                
                DBINT columnNumberBytes = dbdatlen(dbconn, columnOffsetCtr);
                DBINT columnLength      = dbcollen(dbconn, columnOffsetCtr);
                char *columnName        = dbcolname(dbconn, columnOffsetCtr);
                
                NSNumber *columnNumber = [[NSNumber alloc] initWithInt:columnCtr];
                
                NSNumber *columnTypeNumber = [[NSNumber alloc] initWithInt:columnType];
                NSString *columnNameString = [[NSString alloc] initWithCString:columnName
                                                                      encoding:NSStringEncodingConversionAllowLossy];
                
                
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
        
        NSMutableArray *results = [[NSMutableArray alloc] init];
        
        while (dbresults(dbconn) != NO_MORE_RESULTS) {
            
            NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
            
            //NSInteger resultCountForType = [[counters objectForKey:@(CHARBIND)] integerValue];
            //char *charBind[resultCountForType];
            
            
            //for (NSInteger i=0; i<resultCountForType; i++) {
            //    charBind[i] = '\0';
            //}
            
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

            //SYBNUMERIC and SYBDECIMAL
            resultCountForType = [[counters objectForKey:@(SYBNUMERIC)] integerValue];
            //DBNUMERIC *sybNumericBind[resultCountForType];
            char *sybNumericBindChar[resultCountForType];
            DBINT sybNumericBindNull[resultCountForType];

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

            resultCountForType = [[counters objectForKey:@(SYBCHAR)] integerValue];
            char *sybCharBind[resultCountForType];
            DBINT sybCharBindNull[resultCountForType];
            
            resultCountForType = [[counters objectForKey:@(SYBVARCHAR)] integerValue];
            char *sybVarCharBind[resultCountForType];
            DBINT sybVarCharBindNull[resultCountForType];

            resultCountForType = [[counters objectForKey:@(SYBNVARCHAR)] integerValue];
            char *sybnVarCharBind[resultCountForType];
            DBINT sybnVarCharBindNull[resultCountForType];
            
            resultCountForType = [[counters objectForKey:@(SYBTEXT)] integerValue];
            char *sybTextBind[resultCountForType];
            DBINT sybTextBindNull[resultCountForType];

            resultCountForType = [[counters objectForKey:@(SYBNTEXT)] integerValue];
            char *sybnTextBind[resultCountForType];
            DBINT sybnTextBindNull[resultCountForType];

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
            void *sybVarBinaryBind[resultCountForType];
            DBINT sybVarBinaryBindNull[resultCountForType];

            resultCountForType = [[counters objectForKey:@(SYBVOID)] integerValue];
            void *sybVoidBind[resultCountForType];
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
                int columnDataLength = [[columnMetaData objectForKey:MTDatabaseColumnDataLenId] intValue];
                int columnIndexOfType = [[columnMetaData objectForKey:MTDatabaseColumnIndexOfType] intValue];
                int columnOffsetNumber = columnNumber + 1;
                
                switch ([[columnMetaData objectForKey:MTDatabaseColumnTypeId] integerValue]) {

                    case SYBCHAR:
                        sybCharBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLength + 1 ) );
                        dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLength, (BYTE *)sybCharBind[columnIndexOfType]);
                        dbnullbind(dbconn, columnOffsetNumber, &sybCharBindNull[columnIndexOfType]);
                        break;
                        
                    case SYBVARCHAR:
                        sybVarCharBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLength + 1 ) );
                        dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLength, (BYTE *)sybVarCharBind[columnIndexOfType]);
                        dbnullbind(dbconn, columnOffsetNumber, &sybVarCharBindNull[columnIndexOfType]);
                        break;
                        
                    case SYBTEXT:
                        sybTextBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLength + 1 ) );
                        dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLength, (BYTE *)sybTextBind[columnIndexOfType]);
                        dbnullbind(dbconn, columnOffsetNumber, &sybTextBindNull[columnIndexOfType]);
                        break;
                        
                    case SYBNTEXT:
                        sybnTextBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLength + 1 ) );
                        dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLength, (BYTE *)sybnTextBind[columnIndexOfType]);
                        dbnullbind(dbconn, columnOffsetNumber, &sybnTextBindNull[columnIndexOfType]);
                        break;
                        
                    case SYBNVARCHAR:
                        sybnVarCharBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLength + 1 ) );
                        dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, columnLength, (BYTE *)sybnVarCharBind[columnIndexOfType]);
                        dbnullbind(dbconn, columnOffsetNumber, &sybnVarCharBindNull[columnIndexOfType]);
                        break;
                        
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
                
                NSInteger columnCounter = 0;
                for (NSDictionary *columnMetaData in colmunHolder) {
                    [columnMetaData retain];
                    
                    int indexOfType = [[columnMetaData objectForKey:MTDatabaseColumnIndexOfType] intValue];
                    
                    NSString *fieldName = [[columnMetaData objectForKey:MTDatabaseColumnNameId] retain];
                    
                    NSInteger columnNumber = [[columnMetaData objectForKey:MTDatabaseColumnNumberId] intValue];
                    NSInteger columnLength = [[columnMetaData objectForKey:MTDatabaseColumnLenId] intValue];
                    
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
                                    [resultsForRow setObject:decimalNumber forKey:fieldName];
                                    NSLog(@"%@\t\t(SYBNUMERIC):\t\t(%@)", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], decimalNumber);
                                } else {
                                    [resultsForRow setObject:@"Error" forKey:fieldName];
                                }
                                
                                [decimalNumber release];
                                
                                [objectStr release];
                                
                            } else {
                                [resultsForRow setObject:@"NULL" forKey:fieldName];
                            }
                            break;
                        }
                        case SYBREAL: {
                            if (sybRealBindNull[indexOfType] != -1) {
                                NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
                                NSLog(@"%@\t\t(SYBREAL):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:@"NULL" forKey:fieldName];
                            }
                            break;
                        }
                        case SYBFLTN: {
                            if (sybFltNBindNull[indexOfType] != -1) {
                                NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
                                NSLog(@"%@\t\t(SYBFLTN):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:@"NULL" forKey:fieldName];
                            }
                            break;
                        }
                        case SYBFLT8: {
                            if (sybFlt8BindNull[indexOfType] != -1) {
                                NSNumber *object = [[NSNumber alloc] initWithDouble:sybFlt8Bind[indexOfType]];
                                NSLog(@"%@\t\t(SYBFLT8):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:@"NULL" forKey:fieldName];
                            }
                            break;
                        }
                        
                            
                        case SYBCHAR: {
                            if (sybCharBindNull[indexOfType] != -1) {
                                char *sybChar = sybCharBind[indexOfType];
                                if (sybChar != nil) {
                                    NSString *object = [[NSString alloc] initWithCString: sybChar
                                                                                encoding: NSStringEncodingConversionAllowLossy];
                                    
                                    NSLog(@"%@\t\t(SYBCHAR):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                    [resultsForRow setObject:object forKey:fieldName];
                                    [object release];
                                }
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                            
                        case SYBVARCHAR: {
                            if (sybVarCharBindNull[indexOfType] != -1) {
                                char *sybVarChar = sybVarCharBind[indexOfType];
                                if (sybVarChar != nil) {
                                    NSString *object = [[NSString alloc] initWithCString: sybVarChar
                                                                                encoding: NSStringEncodingConversionAllowLossy];
                                    NSLog(@"%@\t\t(SYBVARCHAR):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                    [resultsForRow setObject:object forKey:fieldName];
                                    [object release];
                                }
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBNVARCHAR: {
                            if (sybnVarCharBindNull[indexOfType] != -1) {
                                char *sybnVarChar = sybnVarCharBind[indexOfType];
                                if (sybnVarChar != nil) {
                                    NSString *object = [[NSString alloc] initWithCString: sybnVarChar
                                                                                encoding: NSStringEncodingConversionAllowLossy];
                                    NSLog(@"%@\t\t(SYBNVARCHAR):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                    [resultsForRow setObject:object forKey:fieldName];
                                    [object release];
                                }
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBTEXT: {
                            if (sybTextBindNull[indexOfType] != -1) {
                                char *sybText = sybnVarCharBind[indexOfType];
                                if (sybText != nil) {
                                    NSString *object = [[NSString alloc] initWithCString: sybText
                                                                                encoding: NSStringEncodingConversionAllowLossy];
                                    NSLog(@"%@\t\t(SYBTEXT):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                    [resultsForRow setObject:object forKey:fieldName];
                                    [object release];
                                }
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBNTEXT: {
                            if (sybnTextBindNull[indexOfType] != -1) {
                                char *sybnTest = sybnVarCharBind[indexOfType];
                                if (sybnTest != nil) {
                                    NSString *object = [[NSString alloc] initWithCString: sybnTest
                                                                                encoding: NSStringEncodingConversionAllowLossy];
                                    NSLog(@"%@\t\t(SYBNTEXT):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                    [resultsForRow setObject:object forKey:fieldName];
                                    [object release];
                                }
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }

                        case SYBINTN: {
                            if (sybIntnBindNull[indexOfType] != -1) {
                                long long integer = sybIntnBind[indexOfType];
                                NSNumber *object = [[NSNumber alloc] initWithInteger:(NSInteger)integer];
                                NSLog(@"%@\t\t(SYBCHAR):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBINT1: {
                            if (sybInt1BindNull[indexOfType] != -1) {
                                int integer = sybInt1Bind[indexOfType];
                                NSNumber *object = [[NSNumber alloc] initWithInt:sybInt1Bind[indexOfType]];
                                NSLog(@"%@\t\t(SYBINT1):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBINT2: {
                            if (sybInt2BindNull[indexOfType] != -1) {
                                int i = sybInt2Bind[indexOfType];
                                NSNumber *object = [[NSNumber alloc] initWithInt:i];
                                NSLog(@"%@\t\t(SYBINT2):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBINT4: {
                            if (sybInt4BindNull[indexOfType] != -1) {
                                NSNumber *object = [[NSNumber alloc] initWithInteger:sybInt4Bind[indexOfType]];
                                NSLog(@"%@\t\t(SYBINT4):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBINT8: {
                            if (sybInt8BindNull[indexOfType] != -1) {
                                NSNumber *object = [[NSNumber alloc] initWithLongLong:sybInt8Bind[indexOfType]];
                                NSLog(@"%@\t\t(SYBINT8):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
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
                                
                                NSLog(@"%@\t\t(SYBDATETIME4):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], newDate);
                                [resultsForRow setObject:newDate forKey:fieldName];
                                [newDate release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
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
                                NSCalendar *gregorian = [[NSCalendar alloc]
                                                         initWithCalendarIdentifier:NSGregorianCalendar];
                                NSDate *date = [[gregorian dateFromComponents:comps] retain];
                                NSLog(@"%@\t\t(SYBDATETIME):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], date);
                                [resultsForRow setObject:date forKey:fieldName];
                                [date release];
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
                                NSLog(@"%@\t\t(SYBDATETIMN):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], date);
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
                                NSLog(@"%@\t\t(SYBBIT):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
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
                                NSLog(@"%@\t\t(SYBBITN):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], object);
                                [resultsForRow setObject:object forKey:fieldName];
                                [object release];
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }

                        case SYBIMAGE: {
                            if (sybImageBindNull[indexOfType] != -1) {
                                NSLog(@"%@\t\t(SYBMONEY): Not supported", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0]);
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBMONEY: {
                            if (sybMoneyBindNull[indexOfType] != -1) {
                                double money = sybMoneyBind[indexOfType];
                                NSLog(@"%@\t\t(SYBMONEY):\t\t%f", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], money);
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
                                NSLog(@"%@\t\t(SYBMONEYN):\t\t%f", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], money);
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
                                NSLog(@"%@\t\t(SYBBINARY):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], notSupported);
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBVOID: {
                            if (sybVoidBindNull[indexOfType] != -1) {
                                NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                [resultsForRow setObject:notSupported forKey:fieldName];
                                NSLog(@"%@\t\t(SYBVOID):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], notSupported);
                            } else {
                                [resultsForRow setObject:NSLocalizedString(@"NULL", @"NULL") forKey:fieldName];
                            }
                            break;
                        }
                        case SYBVARBINARY: {
                            if (sybVarBinaryBindNull[indexOfType] != -1) {
                                NSString *notSupported = NSLocalizedString(@"Binary and time stamps are not yet supported.", @"Binary and time stamps are not yet supported.");
                                [resultsForRow setObject:notSupported forKey:fieldName];
                                NSLog(@"%@\t\t(SYBVARBINARY):\t\t%@", [[fieldName substringWithRange:NSMakeRange(0, MIN([fieldName length], 9))] stringByPaddingToLength:9 withString:@" " startingAtIndex:0], notSupported);
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
            }
            
            resultCountForType = [[counters objectForKey:@(SYBCHAR)] integerValue];
            for (NSInteger i=0; i<resultCountForType; i++) {
                free(sybCharBind[i]);
            }
            
            [results addObject: resultsForRow];
            [resultsForRow release];
            
        }
        
        
    }
    
    dbclose(dbconn);
	
    [janFirst1990 release];
    [janFirst1990Components release];
    
    return 0;
    
}

@end
