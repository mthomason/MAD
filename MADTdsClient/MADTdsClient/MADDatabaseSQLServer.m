//
//  MADDatabaseSQLServer.m
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseSQLServer.h"

#import <string.h>
#import <stdlib.h>
#import <unistd.h>

#import <dispatch/time.h>
#import <dispatch/queue.h>
#import <dispatch/semaphore.h>

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

#import <MADFoundation/BDHost.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADCredential.h>

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

//#import "sybdb.h"
#import <MADTds/tds_sysdep_public.h>
#import <MADTds/sybdb.h>

#import "MADDatabaseProcessSQLServer.h"

NSString * const MTDatabaseConnectionUsername   = @"MTDatabaseConnectionUsername";
NSString * const MTDatabaseConnectionPassword   = @"MTDatabaseConnectionPassword";
NSString * const MTDatabaseConnectionDatabase   = @"MTDatabaseConnectionDatabase";
NSString * const MTDatabaseConnectionPort       = @"MTDatabaseConnectionPort";
NSString * const MTDatabaseConnectionHost       = @"MTDatabaseConnectionHost";
NSString * const MTDatabaseConnectionServer     = @"MTDatabaseConnectionServer";
NSString * const MTDatabaseConnectionAppName    = @"MTDatabaseConnectionAppName";
NSString * const MADNotificationError           = @"MADNotificationError";

static NSString * const MADDomainTDS = @"MTDatabaseTds";

static inline NSUInteger numberOfItemsOfType(int, NSMutableDictionary <NSNumber *, NSNumber *> *);
int err_handler(DBPROCESS *, int, int, int, char *, char *);

static inline NSUInteger numberOfItemsOfType(int type, NSMutableDictionary <NSNumber *, NSNumber *> *counters) {
	NSNumber *key = @(type);
	NSNumber *counter = counters[key];
	return counter ? counters[key].unsignedIntegerValue : 0;
}

int err_handler(DBPROCESS *dbproc, int severity, int dberr, int oserr, char *dberrstr, char *oserrstr) {

	int result = INT_CANCEL;

	
		if (severity >= 5 || dberr == SYBEINTF) {
			NSString *title = NSLocalizedString(@"Caught an Error", @"Caught an Error");
			char *osstr = (oserrstr != NULL ? oserrstr : "");
			char *dbstr = (dberrstr != NULL ? dberrstr : "");
			
			NSString *systemMessage = [[NSString alloc] initWithCString: osstr encoding:NSUTF8StringEncoding];
			NSString *dbMessage = [[NSString alloc] initWithCString: dbstr encoding:NSUTF8StringEncoding];
			NSString *errorMessage = [[NSString alloc] initWithFormat:@"System says: \"(%d)%@.\"\nDatabase says: \"(%d)%@.\"", oserr, systemMessage, dberr, dbMessage];
			
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : errorMessage};
			NSError *error = [NSError errorWithDomain:MADDomainTDS code:dberr userInfo:errorInfo];
			[[NSNotificationCenter defaultCenter] postNotificationName:MADNotificationError object:error];
			
			result = INT_CANCEL;
		}
	
	return result;
}

@interface MADDatabaseSQLServer ()

	@property (nonatomic, strong) MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection;

@end

@implementation MADDatabaseSQLServer

@dynamic databaseConnection;

+ (NSString *)imageIconName { return @"UIImageExportTypeSqlServer"; }
+ (NSString *)driverName { return @"SQL Server / TDS"; }

+ (NSString *)IPAddressForServer:(NSString *)server {
	NSString *address = [BDHost addressForHostname:server];
	return address == nil ? server : [NSString stringWithString:address];
}

/*
// Add this to MADTdsDb.m
+ (MADDataType)dataTypeForNativeTypeInternal:(NSInteger)nativeType {
	// Map nativeType values to MADDataType.
	switch (nativeType) {
		case 111: // SYBDATETIMN
		case 61:  // SYBDATETIME
		case 58:  // SYBDATETIME4
			return MADDataTypeDateTime;
		case 47:  // SYBCHAR
		case 39:  // SYBVARCHAR
		case 35:  // SYBTEXT
		case 99:  // SYBNTEXT
		case 103: // SYBNVARCHAR
			return MADDataTypeString;
		case 50:  // SYBBIT
		case 104: // SYBBITN
			return MADDataTypeBit;
		case 48:  // SYBINT1
		case 52:  // SYBINT2
		case 56:  // SYBINT4
		case 127: // SYBINT8
		case 38:  // SYBINTN
			return MADDataTypeInteger;
		case 60:  // SYBMONEY
		case 110: // SYBMONEYN
		case 59:  // SYBREAL
		case 62:  // SYBFLT8
		case 109: // SYBFLTN
			return MADDataTypeFloat;
		case 108: // SYBNUMERIC
			return MADDataTypeDecimal;
		case 34:  // SYBIMAGE
		case 45:  // SYBBINARY
		case 31:  // SYBVOID
		case 37:  // SYBVARBINARY
			return MADDataTypeBlob;
		default:
			return MADDataTypeUnknown; // Use Unknown as a fallback.
	}
}
*/

+ (MADDataType)dataTypeForNativeType:(NSInteger)nativeType {
	MADDataType result;
	switch (nativeType) {
		case SYBDATETIMN:
		case SYBDATETIME:
		case SYBDATETIME4:
			result = MADDataTypeDateTime;
			break;
		case SYBCHAR:
		case SYBVARCHAR:
		case SYBTEXT:
		case SYBNTEXT:
		case SYBNVARCHAR:
			result = MADDataTypeString;
			break;
		case SYBBIT:
		case SYBBITN:
			result = MADDataTypeBit;
			break;
		case SYBINT1:
		case SYBINT2:
		case SYBINT4:
		case SYBINT8:
		case SYBINTN:
			result = MADDataTypeInteger;
			break;
		case SYBMONEY:
		case SYBMONEYN:
		case SYBREAL:
		case SYBFLT8:
		case SYBFLTN:
			result = MADDataTypeFloat;
			break;
		case SYBNUMERIC:
			result = MADDataTypeDecimal;
			break;
		case SYBIMAGE:
		case SYBBINARY:
		case SYBVOID:
		case SYBVARBINARY:
			result = MADDataTypeBlob;
			break;
		default:
			result = MADDataTypeString;
			break;
	}
	return result;
}

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
	if (notification.object) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
		[self.errors addObject:notification.object];
#pragma clang diagnostic pop
	}
}

- (void)closeConnection:(id)process {
	DBPROCESS *dbconn = [process process];
	dbclose(dbconn);
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion {
	
	__block MADDatabaseSQLServer *blockSelf = self;
	
	dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	
	dispatch_async(queuePriorityBackground, ^{
		dispatch_queue_t queue = dispatch_get_main_queue();
		dispatch_sync(queue, ^{
			
			MADDatabaseConnection *databaseConnection = blockSelf.databaseConnection;
			NSError * __autoreleasing dberror = nil;
			DBPROCESS *dbconn = (__bridge DBPROCESS *)([blockSelf connectWithConnection:databaseConnection
																			 credentals:nil
																		connectionError:&dberror]);

			if (dbconn && dberror == nil) {
				
				NSMutableArray  <MADDatabaseTable *> *results = nil;
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
								MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
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

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError * __autoreleasing *)error {
	MADDataTable *dataTable;
	if ([query conformsToProtocol:@protocol(MADQueryDataTableProtocol)] &&
		((MADQuery <MADQueryDataTableProtocol> *)query).dataTable != nil) {
		dataTable = ((MADQuery <MADQueryDataTableProtocol> *)query).dataTable;
	} else {
		dataTable = [self.delegate dataTableForQuery:query];
	}
	return [self executeQuery:query withDataTable:dataTable andError:error];
}

- (BOOL)executeQuery:(MADQuery *)query withDataTable:(MADDataTable *)dataTable
			andError:(NSError * __autoreleasing *)error {
	BOOL success = NO;
	NSError * __autoreleasing dberror = nil;
	MADDatabaseProcessSQLServer *dbconn = [self connectWithConnection:self.databaseConnection credentals:nil connectionError:&dberror];
	if (dbconn) {
		success = [self runQuery:query onProcess:dbconn withDataTable:dataTable withError: NULL];
	}
	return success;
}

- (BOOL)runQuery:(MADQuery *)query onProcess:(MADDatabaseProcessSQLServer *)process
   withDataTable:(MADDataTable *)dataTable withError:(NSError * __autoreleasing *)error {
	BOOL success = NO;
	NSError * __autoreleasing sqlError = nil;
	NSString *sql = [query getSql:self error:&sqlError];
	if (sqlError == nil) {
		success = [self runSQL: sql
				   onDataTable: dataTable
					 fieldKeys: [query conformsToProtocol:@protocol(MADQueryFieldKeysProtocol)] ?
									((MADQuery <MADQueryFieldKeysProtocol> *)query).fieldKeys : nil
					   process: process];
	}
	return success;
}

- (BOOL)executeSQL:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
   intoResultTable:(MADDataTable *)dataTable withError:(NSError * __autoreleasing *)error {
	return [self runSQL:sql onDataTable:dataTable fieldKeys:fieldKeys process:dbconn];
}

- (BOOL)runSQL:(NSString *)sql onDataTable:(MADDataTable *)datatable fieldKeys:(NSArray *)fieldKeys
	   process:(MADDatabaseProcessSQLServer *)process {

	BOOL rsuccess = NO;
	NSError *error = nil;
	if (sql.length > 0) {
		
		NSCalendar *gregorian = [[NSCalendar alloc]
								 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

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

				static NSString * const MTDatabaseColumnTypeId         = @"MTDatabaseColumnTypeId";
				static NSString * const MTDatabaseColumnNameId         = @"MTDatabaseColumnNameId";
				static NSString * const MTDatabaseColumnNumberId       = @"MTDatabaseColumnNumberId";
				static NSString * const MTDatabaseColumnDataLenId      = @"MTDatabaseColumnDataLenId";
				static NSString * const MTDatabaseColumnLenId          = @"MTDatabaseColumnLenId";
				static NSString * const MTDatabaseColumnIndexOfType    = @"MTDatabaseColumnIndexOfType";
				static NSString * const MTDatabaseColumnPrecision      = @"MTDatabaseColumnPrecision";

				NSString *decimalSeperator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];

				BOOL tdsDecimalSeperatorMatchesCocoaDecimalSeperator = NO;
				BOOL tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved = NO;
				
				NSUInteger numberOfColumns = (NSUInteger)dbnumcols(dbconn);
				NSMutableArray <NSDictionary *> *colmunHolder =
					[[NSMutableArray alloc] initWithCapacity:(NSUInteger)numberOfColumns];
				static int disregardedBind = -1023;
				
				NSArray <NSNumber *> *keys = @[
					@(SYBDATETIMN), @(SYBDATETIME), @(SYBDATETIME4),
					@(SYBCHAR), @(SYBVARCHAR), @(SYBTEXT), @(SYBNTEXT), @(SYBNVARCHAR),
					@(SYBBIT), @(SYBBITN), @(SYBINT1), @(SYBINT2), @(SYBINT4), @(SYBINT8),
					@(SYBINTN), @(SYBMONEY), @(SYBMONEYN), @(SYBREAL), @(SYBFLT8), @(SYBFLTN),
					@(SYBNUMERIC), @(SYBIMAGE), @(SYBBINARY), @(SYBVOID), @(SYBVARBINARY),
					@(disregardedBind)
				];
				
				NSMutableDictionary<NSNumber *, NSNumber *> *counters =
					[[NSMutableDictionary alloc] initWithCapacity:keys.count];
				for (NSNumber *key in keys) {
					counters[key] = @0;
				}
				
				[datatable removeAllObjects];

				int index;
				DBINT columnCtr, columnType, columnNumberBytes, columnLength;
				NSNumber *n;
				NSNumber *columnNumberWrapper,
						 *columnTypeNumber,
						 *columnDataLen,
						 *columTypeKey,
						 *columnIndexOfTypeNumber,
						 *columnLen,
						 *columPercision;
				NSString *columnNameString;
				MADDataColumn *dataColumn;

				for (columnCtr = 0; columnCtr < numberOfColumns; columnCtr++) {
					
					columnType = dbcoltype(dbconn, columnCtr + 1);
					if (columnType == SYBDECIMAL) {
						columnType = SYBNUMERIC;
					} else if (columnType == SYBMONEY4) {
						columnType = SYBMONEY;
					}
					
					if (columnType >= 0) {
						columnNumberBytes = dbdatlen(dbconn, columnCtr + 1);
						columnLength      = dbcollen(dbconn, columnCtr + 1);
					
						columnNameString = nil;
						columnNumberWrapper = [[NSNumber alloc] initWithInt: columnCtr];
						columnTypeNumber = [[NSNumber alloc] initWithInt: columnType];
						
						if (![fieldKeys count]) {
							char * columnNameCString = dbcolname(dbconn, columnCtr + 1);
							columnNameString = [[NSString alloc] initWithCString:columnNameCString
																		encoding:NSUTF8StringEncoding];
							columnNameCString = NULL;
						} else {
							columnNameString = fieldKeys[(NSUInteger)columnCtr];
						}
						columnDataLen = [[NSNumber alloc] initWithInt:columnNumberBytes];
						columTypeKey = @(columnType);
						index = [counters[columTypeKey] intValue];
						
						columnIndexOfTypeNumber = [[NSNumber alloc] initWithInt: index];
						columnLen = [[NSNumber alloc] initWithInt: columnLength];
						columPercision = [[NSNumber alloc] initWithInt: -1];
						
						NSMutableDictionary *columnDictionary = [[NSMutableDictionary alloc] initWithCapacity: 7];
						[columnDictionary setObject:columnTypeNumber forKey:MTDatabaseColumnTypeId];
						[columnDictionary setObject:columnNameString forKey:MTDatabaseColumnNameId];
						[columnDictionary setObject:columnNumberWrapper forKey:MTDatabaseColumnNumberId];
						[columnDictionary setObject:columnDataLen forKey:MTDatabaseColumnDataLenId];
						[columnDictionary setObject:columnIndexOfTypeNumber forKey:MTDatabaseColumnIndexOfType];
						[columnDictionary setObject:columnLen forKey:MTDatabaseColumnLenId];
						[columnDictionary setObject:columPercision forKey:MTDatabaseColumnPrecision];

						/*dictionary = @{
									   MTDatabaseColumnTypeId : columnTypeNumber,             //Type
									   MTDatabaseColumnNameId : columnNameString,             //Name
									   MTDatabaseColumnNumberId : columnNumberWrapper,        //Index
									   MTDatabaseColumnDataLenId : columnDataLen,             //Data length
									   MTDatabaseColumnIndexOfType : columnIndexOfTypeNumber, //Index of type
									   MTDatabaseColumnLenId : columnLen,                     //Column lenght
									   MTDatabaseColumnPrecision : columPercision             //Column percision
									   };*/
						
						dataColumn = [[MADDataColumn alloc] initWithType: [MADDatabaseSQLServer dataTypeForNativeType:columnType]
																	name: columnNameString
																  number: columnCtr
																 dataLen: columnNumberBytes
															 indexOfType: index
																  length: columnLength
															   percision: -1
															  nativeType: (int16_t)columnType];
						[datatable addColumn:dataColumn];
						[colmunHolder addObject:columnDictionary];

						index++;
						
						n = [[NSNumber alloc] initWithInt: index];
						counters[columTypeKey] = n;
						
					}
				}
				
				[datatable beginBulkInsert];
				
				while (dbresults(dbconn) != NO_MORE_RESULTS) {
					
					//SYBREAL, SYBFLTN, and SYBFLT8
					
					NSUInteger resultCountForType = numberOfItemsOfType(SYBREAL, counters);
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
					
					NSUInteger resultCountForTypeSybNumericBindChar = numberOfItemsOfType(SYBNUMERIC, counters);
					char *sybNumericBindChar[resultCountForTypeSybNumericBindChar];
					DBINT sybNumericBindNull[resultCountForTypeSybNumericBindChar];
					for (NSInteger i=0; i<resultCountForTypeSybNumericBindChar; i++) {
						sybNumericBindChar[i] = "\0";
					}
					
					NSUInteger resultCountForTypeSybCharBind = numberOfItemsOfType(SYBCHAR, counters);
					char *sybCharBind[resultCountForTypeSybCharBind];
					DBINT sybCharBindNull[resultCountForTypeSybCharBind];
					for (NSInteger i=0; i<resultCountForTypeSybCharBind; i++) {
						sybCharBind[i] = "\0";
					}
					
					NSUInteger resultCountForTypeSybVarCharBind = numberOfItemsOfType(SYBVARCHAR, counters);
					char *sybVarCharBind[resultCountForTypeSybVarCharBind];
					DBINT sybVarCharBindNull[resultCountForTypeSybVarCharBind];
					for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
						sybVarCharBind[i] = "\0";
					}
					
					NSUInteger resultCountForTypeSybnVarCharBind = numberOfItemsOfType(SYBNVARCHAR, counters);
					char *sybnVarCharBind[resultCountForTypeSybnVarCharBind];
					DBINT sybnVarCharBindNull[resultCountForTypeSybnVarCharBind];
					for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
						sybnVarCharBind[i] = "\0";
					}
					
					NSUInteger resultCountForTypeSybTextBind = numberOfItemsOfType(SYBTEXT, counters);
					char *sybTextBind[resultCountForTypeSybTextBind];
					DBINT sybTextBindNull[resultCountForTypeSybTextBind];
					for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
						sybTextBind[i] = "\0";
					}
					
					NSUInteger resultCountForTypeSybnTextBind = numberOfItemsOfType(SYBNTEXT, counters);
					char *sybnTextBind[resultCountForTypeSybnTextBind];
					DBINT sybnTextBindNull[resultCountForTypeSybnTextBind];
					for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
						sybnTextBind[i] = "\0";
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
						unsigned long columnLengthMeta = [columnMetaData[MTDatabaseColumnLenId] unsignedLongValue];
						//int columnDataLength = [[columnMetaData objectForKey:MTDatabaseColumnDataLenId] intValue];
						int columnIndexOfType = [columnMetaData[MTDatabaseColumnIndexOfType] intValue];
						int columnOffsetNumber = columnNumber + 1;
						
						switch ([columnMetaData[MTDatabaseColumnTypeId] integerValue]) {
								
							case SYBCHAR: {
								size_t size = sizeof(char) * ( columnLengthMeta + 1 );
								sybCharBind[columnIndexOfType] = malloc( size );
								dbbind(dbconn,
									   columnOffsetNumber,
									   NTBSTRINGBIND,
									   (DBINT)columnLengthMeta + 1,
									   (BYTE *)sybCharBind[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybCharBindNull[columnIndexOfType]);
								break;
							}
							case SYBVARCHAR: {
								sybVarCharBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLengthMeta + 1 ) );
								dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, (DBINT)columnLengthMeta + 1, (BYTE *)sybVarCharBind[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybVarCharBindNull[columnIndexOfType]);
								break;
							}
							case SYBTEXT: {
								sybTextBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLengthMeta + 1 ) );
								dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, (DBINT)columnLengthMeta + 1, (BYTE *)sybTextBind[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybTextBindNull[columnIndexOfType]);
								break;
							}
							case SYBNTEXT: {
								size_t size = sizeof(char) * ( columnLengthMeta + 1 );
								sybnTextBind[columnIndexOfType] = malloc( size );
								dbbind(dbconn,
									   columnOffsetNumber,
									   NTBSTRINGBIND,
									   (DBINT)columnLengthMeta + 1,
									   (BYTE *)sybnTextBind[columnIndexOfType]);
								dbnullbind(dbconn,
										   columnOffsetNumber,
										   &sybnTextBindNull[columnIndexOfType]);
								break;
							}
							case SYBNVARCHAR: {
								size_t size = sizeof(char) * ( columnLengthMeta + 1 );
								sybnVarCharBind[columnIndexOfType] = malloc( size );
								dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, (DBINT)columnLengthMeta + 1, (BYTE *)sybnVarCharBind[columnIndexOfType]);
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
								dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybFltNBind[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybFltNBindNull[columnIndexOfType]);
								break;
							case SYBFLT8:
								dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybFlt8Bind[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybFlt8BindNull[columnIndexOfType]);
								break;
							case SYBREAL:
								dbbind(dbconn,
									   columnOffsetNumber,
									   FLT8BIND,
									   (DBINT)columnLengthMeta,
									   (BYTE *)&sybRealBind[columnIndexOfType]);
								dbnullbind(dbconn,
										   columnOffsetNumber,
										   &sybRealBindNull[columnIndexOfType]);
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
								
								sybNumericBindChar[columnIndexOfType] = malloc( sizeof(char) * ( columnLengthMeta + 1 ) );
								dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, (DBINT)columnLengthMeta, (BYTE *)sybNumericBindChar[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybNumericBindNull[columnIndexOfType]);
								break;
							}
							case SYBMONEYN:
								dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybMoneyNBind[columnIndexOfType]);
								dbnullbind(dbconn, columnOffsetNumber, &sybMoneyNBindNull[columnIndexOfType]);
								break;
							case SYBMONEY:
								dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybMoneyBind[columnIndexOfType]);
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
					NSMutableArray <NSNumber *> *columnPercision = [[NSMutableArray alloc] initWithCapacity:colmunHolder.count];
					for (NSUInteger i = 0; i<colmunHolder.count; i++) {
						NSNumber *negOne = [NSNumber numberWithInteger: -1];
						[columnPercision addObject: negOne];
					}
					
					
					NSUInteger rowCounter = 0;
					while (dbnextrow(dbconn) != NO_MORE_ROWS) {
						/* do RowByAgonizingRow processing */
						
						NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
						
						NSUInteger columnCounter = 0;
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
										
										NSInteger cp = [columnPercision[columnCounter] integerValue];
										
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
										struct tds_sybase_dbdaterec dateinfo;
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
										struct tds_sybase_dbdaterec dateinfo;
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
			NSError *error1 = [NSError errorWithDomain:MADDomainTDS code:4379 userInfo:errorInfo];
			rsuccess = NO;
		}
		
	} else {
		NSString *title = NSLocalizedString(@"Bad Query", @"Bad Query");
		NSString *message = NSLocalizedString(@"Could not run this query.", @"Could not run this query.");
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : message};
		NSError *error2 = [NSError errorWithDomain:MADDomainTDS code:4378 userInfo:errorInfo];
		rsuccess = NO;
	}
	return rsuccess;
}

- (NSInteger)numberOfItemsOfType:(int)type withCounters:(NSMutableDictionary *)counters {
	NSNumber *key = @(type);
	NSNumber *counter = counters[key];
	return counter ? counter.integerValue : 0;
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
		if (*error != NULL) {
			NSError *e = [NSError errorWithDomain:MADDomainTDS code:1 userInfo:errorInfo];
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
			NSString *appName = @"mad";
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
		
		//Call this if using Windows Login Authentation
		//DBSETLSECURE(login);
		
		if (*error == nil) {
		
			NSString *IPAddress = [MADDatabaseSQLServer IPAddressForServer:self.databaseConnection.server];
			char *s = (char *)[IPAddress cStringUsingEncoding:NSUTF8StringEncoding];
			dbconn = dbopen(login, s);
			if (dbconn == NULL) {
				NSString *message;
				NSDictionary *errorInfo;

				message = [[NSString alloc] initWithFormat:@"Could not connect to DB Server: %s\n", s];
				errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys: message, NSLocalizedDescriptionKey, nil];
				*error = [NSError errorWithDomain:MADDomainTDS code:2 userInfo:errorInfo];
				
			}
			
		}
		connected = (*error == nil);
		
		dbloginfree(login);
	}
	
	return dbconn;
}

- (id)connectWithConnection:(MADDatabaseConnection *)connection credentals:(MADCredential *)credentals
			connectionError:(NSError *__autoreleasing *)error {
	
	if (credentals == nil) {
		credentals = [self credentalsWithConnection:connection];
	}
	MADDatabaseProcessSQLServer *dbwrap = nil;
	DBPROCESS *dbconn = NULL;
	if (credentals != nil) {
		
		NSError * __autoreleasing dberror = nil;
		dbconn = [self connect:credentals.username andPassword:credentals.password error:&dberror];
		error = &dberror;
		if (error && dberror) {
			[self.errors insertObject:dberror atIndex:0];
		} else {
			dbwrap = [[MADDatabaseProcessSQLServer alloc] initWithProcess:dbconn];
		}
		
	}
	
	return dbwrap; //(__bridge id)(dbconn);
}

- (NSString *)identifier { return self.databaseConnection.identifier; }

- (id)connectionSettings { return self.databaseConnection; }

+ (NSString *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
	MADSafeQueryField *safeQueryField = [[MADSafeQueryField alloc] initWithFormat:@"[%@].[%@]", tableName, fieldName];
	return safeQueryField;
}
- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [MADDatabaseSQLServer newSafeQueryField:fieldName andTable:tableName];
}

+ (NSString *)newSafeIdentifier:(NSString *)fieldOrTableName {
	id result = [[NSString alloc] initWithFormat:@"[%@]", fieldOrTableName];
	return result;
}

- (NSString *)newSafeIdentifier:(NSString *)fieldOrTableName {
	id result = [[NSString alloc] initWithFormat:@"[%@]", fieldOrTableName];
	return result;
}

- (NSString *)sqlAggregateFunctionLength { return @"DATALENGTH"; }

- (NSString *)selectPart {
	return [self selectPartWithLimitedResults:NSUIntegerMax];  // No limit by default
}

- (NSString *)selectPartWithLimitedResults:(NSUInteger)limit {
	NSString *selectPart = [super selectPart];
	return limit > 0 && limit != NSUIntegerMax ?
				[selectPart stringByAppendingFormat:@"TOP %ld\n", (long)limit] : selectPart;
}

- (NSString *)sqlLimitClause { return @""; }

- (NSString *)sqlLimitClause:(NSUInteger)limit { return @""; }

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName {
	
	MADSafeQueryField *safeField = [self queryKey: fieldName table: tableName];
	NSString *safeFieldAlias = [self fieldAliasForField: fieldName
									  withSafeTableName: tableName];
	MADSafeQueryField *safeTable = [self newSafeIdentifier: tableName];
	NSString *sql = [[NSString alloc] initWithFormat:@"SELECT DISTINCT TOP 511 "
					 @"%@ %@ %@ "
					 @"%@ %@ ",
					 safeField, [self tableAliasConnector], safeFieldAlias,
					 MADSqlTextFromPart, safeTable];
	return sql;
}

#pragma mark - Reading Tables

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)process
													error:(NSError * __autoreleasing *)outError {
	id results = nil;
	DBPROCESS *dbconn = [process process];
	if (dbconn) {
		
		dbcmd(dbconn, "SELECT name FROM sys.tables");
		
		RETCODE success = dbsqlexec(dbconn);
		
		if (success != SUCCEED) {
			
			NSString *message = @"Sql Syntax Error";
			if (*outError != NULL) {
				NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
				*outError = [NSError errorWithDomain:MADDomainTDS code:534 userInfo:errorInfo];
			}
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
						MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
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
						   usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
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
					
					MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
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

- (void)getTablesFromConnection:(id)process
					 completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	
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
						MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
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

- (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName connection:(id)process error:(NSError * __autoreleasing *)error {
	NSMutableArray *results = nil;
	RETCODE sqlReturnCode = FAIL;
	DBPROCESS *dbconn = [process process];
	if (dbconn) {
		NSString *query, *queryFormat;
		queryFormat = @"SELECT name, system_type_id, max_length, precision, scale FROM "
					  @"sys.columns WHERE object_id = OBJECT_ID('%@')";
		query = [[NSString alloc] initWithFormat:queryFormat, tableName];
		dbcmd(dbconn, [query cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
		
		sqlReturnCode = dbsqlexec(dbconn);
		
		if (sqlReturnCode != SUCCEED && error == NULL) {
			NSString *message = @"Sql Syntax Error";
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
			if (error != NULL) {
				*error = [NSError errorWithDomain:MADDomainTDS code:3456 userInfo:errorInfo];
			}
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
						MADDatabaseField *databaseField = [[MADDatabaseField alloc] initWithName:name];
						databaseField.fieldTypeNative = [MADDatabaseSQLServer dataTypeForNativeType:typeBind];
						databaseField.fieldType = databaseField.fieldTypeNative;
						databaseField.width = (int64_t)lengthBind;
						databaseField.decimals = (int16_t)scaleBind;
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
