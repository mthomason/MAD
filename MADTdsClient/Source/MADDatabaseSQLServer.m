//
//  MADDatabaseSQLServer.m
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseSQLServer.h"
#import "MADDatabaseProcessSQLServer.h"

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

#import <MADTds/tds_sysdep_public.h>
#import <MADTds/sybdb.h>

#import <dispatch/time.h>
#import <dispatch/queue.h>
#import <dispatch/semaphore.h>

//#import <sybdb.h>
#import <string.h>
#import <stdlib.h>
#import <unistd.h>

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
			char *osstr = (oserrstr != NULL ? oserrstr : "");
			char *dbstr = (dberrstr != NULL ? dberrstr : "");
			
			NSString *systemMessage = [[NSString alloc] initWithCString: osstr encoding:NSUTF8StringEncoding];
			NSString *dbMessage = [[NSString alloc] initWithCString: dbstr encoding:NSUTF8StringEncoding];
			NSString *errorMessage = [[NSString alloc] initWithFormat:@"System says: \"(%d)%@.\"\nDatabase says: \"(%d)%@.\"", oserr, systemMessage, dberr, dbMessage];
			
			NSError *error = [NSError errorWithDomain:MADDomainTDS code:dberr userInfo:@{
				NSLocalizedDescriptionKey : NSLocalizedString(@"Caught an Error", @"Caught an Error"),
				NSLocalizedFailureReasonErrorKey : errorMessage
			}];
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
		case SYBBIGDATETIME:
		case SYBMSDATETIME2:
		case SYBMSDATETIMEOFFSET:
			result = MADDataTypeDateTime;
			break;
		case SYBDATE:
		case SYBMSDATE:
			result = MADDataTypeDate;
			break;
		case SYBTIME:
		case SYBMSTIME:
		case SYBBIGTIME:
			result = MADDataTypeTime;
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
		case SYBMONEY4:
		case SYBREAL:
		case SYBFLT8:
		case SYBFLTN:
			result = MADDataTypeFloat;
			break;
		case SYBDECIMAL:
		case SYBNUMERIC:
			// DECIMAL and NUMERIC are the same type in SQL Server; only the latter
			// used to be mapped, so the more common DECIMAL spelling became a string.
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

// Maps sys.columns.system_type_id -- SQL Server's built-in type ids -- onto MADDataType.
// These ids are NOT the sybdb SYB* codes that +dataTypeForNativeType: takes. Several
// coincide (48/52/56/61/62/127/34/35/99), which is why feeding a system_type_id to that
// method appeared to work for some columns, but varchar/char/nvarchar/binary/varbinary
// and the modern date types map to unrelated numbers and came out as strings.
+ (MADDataType)dataTypeForSystemTypeId:(NSInteger)systemTypeId {
	switch (systemTypeId) {
		case 48:  // tinyint
		case 52:  // smallint
		case 56:  // int
		case 127: // bigint
			return MADDataTypeInteger;
		case 104: // bit
			return MADDataTypeBit;
		case 106: // decimal
		case 108: // numeric
			return MADDataTypeDecimal;
		case 59:  // real
		case 62:  // float
		case 60:  // money
		case 122: // smallmoney
			return MADDataTypeFloat;
		case 58:  // smalldatetime
		case 61:  // datetime
		case 42:  // datetime2
		case 43:  // datetimeoffset
			return MADDataTypeDateTime;
		case 40:  // date
			return MADDataTypeDate;
		case 41:  // time
			return MADDataTypeTime;
		case 34:  // image
		case 173: // binary
		case 165: // varbinary
		case 189: // timestamp / rowversion
			return MADDataTypeBlob;
		default:  // text, ntext, varchar, char, nvarchar, nchar, xml, sql_variant, ...
			return MADDataTypeString;
	}
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
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

		dispatch_sync(dispatch_get_main_queue(), ^{
			
			MADDatabaseConnection *databaseConnection = blockSelf.databaseConnection;
			NSError * __autoreleasing dberror = nil;
			// -connectWithConnection:... hands back a MADDatabaseProcessSQLServer wrapping the
			// DBPROCESS, not the DBPROCESS itself. The wrapper has to be unwrapped before any
			// freetds call: dbcmd() on the wrapper reallocs an offset inside the object rather
			// than the command buffer, which aborts the process inside tds_realloc.
			MADDatabaseProcessSQLServer *dbwrapper =
				[blockSelf connectWithConnection:databaseConnection
									   credentals:nil
								  connectionError:&dberror];
			DBPROCESS *dbconn = [dbwrapper process];

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
	MADDataTable *dataTable = nil;
	if ([query conformsToProtocol:@protocol(MADQueryDataTableProtocol)] &&
		((MADQuery <MADQueryDataTableProtocol> *)query).dataTable != nil) {
		dataTable = ((MADQuery <MADQueryDataTableProtocol> *)query).dataTable;
	} else if ([self.delegate respondsToSelector:@selector(dataTableForQuery:)]) {
		dataTable = [self.delegate dataTableForQuery:query];
	}
	return [self executeQuery:query withDataTable:dataTable andError:error];
}

// Narrowed to the write port: this driver hands the caller's table to -runSQL:,
// which only ever fills it, and never reads a row or a count back.  The
// MADDatabaseDataSource protocol still declares MADDataTable because
// MADDatabaseMySQL cannot honour the narrower promise -- see that class.
- (BOOL)executeQuery:(MADQuery *)query withDataTable:(id <MADDataTableWriting>)dataTable
			andError:(NSError * __autoreleasing *)error {
	BOOL success = NO;
	NSError * __autoreleasing dberror = nil;
	MADDatabaseProcessSQLServer *dbconn = [self connectWithConnection:self.databaseConnection credentals:nil connectionError:&dberror];
	if (dbconn) {
		success = [self runQuery:query onProcess:dbconn withDataTable:dataTable withError:error];
	} else if (error != NULL) {
		// A nil process means the connection failed; surface that rather than
		// returning NO with the caller's error untouched.
		*error = dberror;
	}
	return success;
}

- (BOOL)runQuery:(MADQuery *)query onProcess:(MADDatabaseProcessSQLServer *)process
   withDataTable:(id <MADDataTableWriting>)dataTable withError:(NSError * __autoreleasing *)error {
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
   intoResultTable:(id <MADDataTableWriting>)dataTable withError:(NSError * __autoreleasing *)error {
	return [self runSQL:sql onDataTable:dataTable fieldKeys:fieldKeys process:dbconn];
}

- (BOOL)runSQL:(NSString *)sql onDataTable:(id <MADDataTableWriting>)datatable fieldKeys:(NSArray *)fieldKeys
	   process:(MADDatabaseProcessSQLServer *)process {
	
	BOOL rsuccess = NO;
	// Use a local error variable, then assign to outError if provided
	NSError * __autoreleasing localError = nil;
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
					
					NSUInteger resultCountForType_SYBREAL = numberOfItemsOfType(SYBREAL, counters);
					double *sybRealBind = NULL;
					DBINT *sybRealBindNull = NULL;
					if (resultCountForType_SYBREAL > 0) {
						sybRealBind = (double *)malloc(sizeof(double) * resultCountForType_SYBREAL);
						sybRealBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBREAL);
					}
					
					NSUInteger resultCountForType_SYBFLTN = numberOfItemsOfType(SYBFLTN, counters);
					double *sybFltNBind = NULL;
					DBINT *sybFltNBindNull = NULL;
					if (resultCountForType_SYBFLTN > 0) {
						sybFltNBind = (double *)malloc(sizeof(double) * resultCountForType_SYBFLTN);
						sybFltNBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBFLTN);
					}
					
					NSUInteger resultCountForType_SYBFLT8 = numberOfItemsOfType(SYBFLT8, counters);
					double *sybFlt8Bind = NULL;
					DBINT *sybFlt8BindNull = NULL;
					if (resultCountForType_SYBFLT8 > 0) {
						sybFlt8Bind = (double *)malloc(sizeof(double) * resultCountForType_SYBFLT8);
						sybFlt8BindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBFLT8);
					}
					
					NSUInteger resultCountForType_SYBINT1 = numberOfItemsOfType(SYBINT1, counters);
					int *sybInt1Bind = NULL;
					DBINT *sybInt1BindNull = NULL;
					if (resultCountForType_SYBINT1 > 0) {
						sybInt1Bind = (int *)malloc(sizeof(int) * resultCountForType_SYBINT1);
						sybInt1BindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBINT1);
					}
					
					NSUInteger resultCountForType_SYBINT2 = numberOfItemsOfType(SYBINT2, counters);
					int *sybInt2Bind = NULL;
					DBINT *sybInt2BindNull = NULL;
					if (resultCountForType_SYBINT2 > 0) {
						sybInt2Bind = (int *)malloc(sizeof(int) * resultCountForType_SYBINT2);
						sybInt2BindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBINT2);
					}
					
					NSUInteger resultCountForType_SYBINTN = numberOfItemsOfType(SYBINTN, counters);
					long long *sybIntnBind = NULL;
					DBINT *sybIntnBindNull = NULL;
					if (resultCountForType_SYBINTN > 0) {
						sybIntnBind = (long long *)malloc(sizeof(long long) * resultCountForType_SYBINTN);
						sybIntnBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBINTN);
					}
					
					NSUInteger resultCountForType_SYBINT4 = numberOfItemsOfType(SYBINT4, counters);
					int *sybInt4Bind = NULL;
					DBINT *sybInt4BindNull = NULL;
					if (resultCountForType_SYBINT4 > 0) {
						sybInt4Bind = (int *)malloc(sizeof(int) * resultCountForType_SYBINT4);
						sybInt4BindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBINT4);
					}
					
					NSUInteger resultCountForType_SYBINT8 = numberOfItemsOfType(SYBINT8, counters);
					long long *sybInt8Bind = NULL;
					DBINT *sybInt8BindNull = NULL;
					if (resultCountForType_SYBINT8 > 0) {
						sybInt8Bind = (long long *)malloc(sizeof(long long) * resultCountForType_SYBINT8);
						sybInt8BindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBINT8);
					}
					
					NSUInteger resultCountForType_SYBMONEY = numberOfItemsOfType(SYBMONEY, counters);
					double *sybMoneyBind = NULL;
					DBINT *sybMoneyBindNull = NULL;
					if (resultCountForType_SYBMONEY > 0) {
						sybMoneyBind = (double *)malloc(sizeof(double) * resultCountForType_SYBMONEY);
						sybMoneyBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBMONEY);
					}
					
					NSUInteger resultCountForType_SYBMONEYN = numberOfItemsOfType(SYBMONEYN, counters);
					double *sybMoneyNBind = NULL;
					DBINT *sybMoneyNBindNull = NULL;
					if (resultCountForType_SYBMONEYN > 0) {
						sybMoneyNBind = (double *)malloc(sizeof(double) * resultCountForType_SYBMONEYN);
						sybMoneyNBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBMONEYN);
					}
					
					
					NSUInteger resultCountForTypeSybNumericBindChar = numberOfItemsOfType(SYBNUMERIC, counters);
					char **sybNumericBindChar = NULL;
					DBINT *sybNumericBindNull = NULL;
					if (resultCountForTypeSybNumericBindChar > 0) {
						sybNumericBindChar = (char **)malloc(sizeof(char *) * resultCountForTypeSybNumericBindChar);
						sybNumericBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForTypeSybNumericBindChar);
						for (NSInteger i=0; i<resultCountForTypeSybNumericBindChar; i++) {
							sybNumericBindChar[i] = NULL; // Initialize pointers to NULL
						}
					}
					
					NSUInteger resultCountForTypeSybCharBind = numberOfItemsOfType(SYBCHAR, counters);
					char **sybCharBind = NULL;
					DBINT *sybCharBindNull = NULL;
					if (resultCountForTypeSybCharBind > 0) {
						sybCharBind = (char **)malloc(sizeof(char *) * resultCountForTypeSybCharBind);
						sybCharBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForTypeSybCharBind);
						for (NSInteger i=0; i<resultCountForTypeSybCharBind; i++) {
							sybCharBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForTypeSybVarCharBind = numberOfItemsOfType(SYBVARCHAR, counters);
					char **sybVarCharBind = NULL;
					DBINT *sybVarCharBindNull = NULL;
					if (resultCountForTypeSybVarCharBind > 0) {
						sybVarCharBind = (char **)malloc(sizeof(char *) * resultCountForTypeSybVarCharBind);
						sybVarCharBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForTypeSybVarCharBind);
						for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
							sybVarCharBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForTypeSybnVarCharBind = numberOfItemsOfType(SYBNVARCHAR, counters);
					char **sybnVarCharBind = NULL;
					DBINT *sybnVarCharBindNull = NULL;
					if (resultCountForTypeSybnVarCharBind > 0) {
						sybnVarCharBind = (char **)malloc(sizeof(char *) * resultCountForTypeSybnVarCharBind);
						sybnVarCharBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForTypeSybnVarCharBind);
						for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
							sybnVarCharBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForTypeSybTextBind = numberOfItemsOfType(SYBTEXT, counters);
					char **sybTextBind = NULL;
					DBINT *sybTextBindNull = NULL;
					if (resultCountForTypeSybTextBind > 0) {
						sybTextBind = (char **)malloc(sizeof(char *) * resultCountForTypeSybTextBind);
						sybTextBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForTypeSybTextBind);
						for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
							sybTextBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForTypeSybnTextBind = numberOfItemsOfType(SYBNTEXT, counters);
					char **sybnTextBind = NULL;
					DBINT *sybnTextBindNull = NULL;
					if (resultCountForTypeSybnTextBind > 0) {
						sybnTextBind = (char **)malloc(sizeof(char *) * resultCountForTypeSybnTextBind);
						sybnTextBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForTypeSybnTextBind);
						for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
							sybnTextBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForType_SYBDATETIME = numberOfItemsOfType(SYBDATETIME, counters);
					DBDATETIME **sybDateTimeBind = NULL;
					DBINT *sybDateTimeBindNull = NULL;
					if (resultCountForType_SYBDATETIME > 0) {
						sybDateTimeBind = (DBDATETIME **)malloc(sizeof(DBDATETIME *) * resultCountForType_SYBDATETIME);
						sybDateTimeBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBDATETIME);
						for (NSInteger i = 0; i < resultCountForType_SYBDATETIME; i++) {
							sybDateTimeBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForType_SYBDATETIME4 = numberOfItemsOfType(SYBDATETIME4, counters);
					DBDATETIME4 **sybDateTime4Bind = NULL;
					DBINT *sybDateTime4BindNull = NULL;
					if (resultCountForType_SYBDATETIME4 > 0) {
						sybDateTime4Bind = (DBDATETIME4 **)malloc(sizeof(DBDATETIME4 *) * resultCountForType_SYBDATETIME4);
						sybDateTime4BindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBDATETIME4);
						for (NSInteger i = 0; i < resultCountForType_SYBDATETIME4; i++) {
							sybDateTime4Bind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForType_SYBDATETIMN = numberOfItemsOfType(SYBDATETIMN, counters);
					DBDATETIME **sybDateTimnBind = NULL;
					DBINT *sybDateTimnBindNull = NULL;
					if (resultCountForType_SYBDATETIMN > 0) {
						sybDateTimnBind = (DBDATETIME **)malloc(sizeof(DBDATETIME *) * resultCountForType_SYBDATETIMN);
						sybDateTimnBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBDATETIMN);
						for (NSInteger i = 0; i < resultCountForType_SYBDATETIMN; i++) {
							sybDateTimnBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForType_SYBIMAGE = numberOfItemsOfType(SYBIMAGE, counters);
					BYTE **sybImageBind = NULL;
					DBINT *sybImageBindNull = NULL;
					if (resultCountForType_SYBIMAGE > 0) {
						sybImageBind = (BYTE **)malloc(sizeof(BYTE *) * resultCountForType_SYBIMAGE);
						sybImageBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBIMAGE);
						for (NSInteger i = 0; i < resultCountForType_SYBIMAGE; i++) {
							sybImageBind[i] = NULL;
						}
					}
					
					NSUInteger resultCountForType_SYBBINARY = numberOfItemsOfType(SYBBINARY, counters);
					DBINT *sybBinaryBind = NULL;
					DBINT *sybBinaryBindNull = NULL;
					if (resultCountForType_SYBBINARY > 0) {
						sybBinaryBind = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBBINARY);
						sybBinaryBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBBINARY);
					}
					
					NSUInteger resultCountForType_SYBVARBINARY = numberOfItemsOfType(SYBVARBINARY, counters);
					DBINT *sybVarBinaryBindNull = NULL;
					if (resultCountForType_SYBVARBINARY > 0) {
						sybVarBinaryBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBVARBINARY);
					}
					
					NSUInteger resultCountForType_SYBVOID = numberOfItemsOfType(SYBVOID, counters);
					DBINT *sybVoidBindNull = NULL;
					if (resultCountForType_SYBVOID > 0) {
						sybVoidBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBVOID);
					}
					
					NSUInteger resultCountForType_SYBBIT = numberOfItemsOfType(SYBBIT, counters);
					BOOL *sybBitBind = NULL;
					DBINT *sybBitBindNull = NULL;
					if (resultCountForType_SYBBIT > 0) {
						sybBitBind = (BOOL *)malloc(sizeof(BOOL) * resultCountForType_SYBBIT);
						sybBitBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBBIT);
					}
					
					NSUInteger resultCountForType_SYBBITN = numberOfItemsOfType(SYBBITN, counters);
					BOOL *sybBitNBind = NULL;
					DBINT *sybBitNBindNull = NULL;
					if (resultCountForType_SYBBITN > 0) {
						sybBitNBind = (BOOL *)malloc(sizeof(BOOL) * resultCountForType_SYBBITN);
						sybBitNBindNull = (DBINT *)malloc(sizeof(DBINT) * resultCountForType_SYBBITN);
					}
					
					for (NSDictionary *columnMetaData in colmunHolder) {
						
						int columnNumber = [columnMetaData[MTDatabaseColumnNumberId] intValue];
						unsigned long columnLengthMeta = [columnMetaData[MTDatabaseColumnLenId] unsignedLongValue];
						DBINT bindLength = columnLengthMeta > INT_MAX ? INT_MAX : (DBINT)columnLengthMeta + 1;
						int columnIndexOfType = [columnMetaData[MTDatabaseColumnIndexOfType] intValue];
						int columnOffsetNumber = columnNumber + 1;
						
						switch ([columnMetaData[MTDatabaseColumnTypeId] integerValue]) {
								
							case SYBCHAR: {
								size_t size = sizeof(char) * ( columnLengthMeta + 1 );
								// Add safety checks for allocated bind arrays before dereferencing
								if (sybCharBind && sybCharBindNull && columnIndexOfType < resultCountForTypeSybCharBind) {
									sybCharBind[columnIndexOfType] = malloc( size );
									dbbind(dbconn,
										   columnOffsetNumber,
										   NTBSTRINGBIND,
										   bindLength,
										   (BYTE *)sybCharBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybCharBindNull[columnIndexOfType]);
								}
								break;
							}
							case SYBVARCHAR: {
								if (sybVarCharBind && sybVarCharBindNull && columnIndexOfType < resultCountForTypeSybVarCharBind) {
									sybVarCharBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLengthMeta + 1 ) );
									dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, bindLength, (BYTE *)sybVarCharBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybVarCharBindNull[columnIndexOfType]);
								}
								break;
							}
							case SYBTEXT: {
								if (sybTextBind && sybTextBindNull && columnIndexOfType < resultCountForTypeSybTextBind) {
									sybTextBind[columnIndexOfType] = malloc( sizeof(char) * ( columnLengthMeta + 1 ) );
									dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, bindLength, (BYTE *)sybTextBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybTextBindNull[columnIndexOfType]);
								}
								break;
							}
							case SYBNTEXT: {
								size_t size = sizeof(char) * ( columnLengthMeta + 1 );
								if (sybnTextBind && sybnTextBindNull && columnIndexOfType < resultCountForTypeSybnTextBind) {
									sybnTextBind[columnIndexOfType] = malloc( size );
									dbbind(dbconn,
										   columnOffsetNumber,
										   NTBSTRINGBIND,
										   (DBINT)columnLengthMeta + 1,
										   (BYTE *)sybnTextBind[columnIndexOfType]);
									dbnullbind(dbconn,
											   columnOffsetNumber,
											   &sybnTextBindNull[columnIndexOfType]);
								}
								break;
							}
							case SYBNVARCHAR: {
								size_t size = sizeof(char) * ( columnLengthMeta + 1 );
								if (sybnVarCharBind && sybnVarCharBindNull && columnIndexOfType < resultCountForTypeSybnVarCharBind) {
									sybnVarCharBind[columnIndexOfType] = malloc( size );
									dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, bindLength, (BYTE *)sybnVarCharBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybnVarCharBindNull[columnIndexOfType]);
								}
								break;
							}
							case SYBINTN:
								if (sybIntnBind && sybIntnBindNull && columnIndexOfType < resultCountForType_SYBINTN) {
									dbbind(dbconn, columnOffsetNumber, BIGINTBIND, sizeof(long long), (BYTE *)&sybIntnBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybIntnBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBINT1:
								if (sybInt1Bind && sybInt1BindNull && columnIndexOfType < resultCountForType_SYBINT1) {
									dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(int), (BYTE *)&sybInt1Bind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybInt1BindNull[columnIndexOfType]);
								}
								break;
								
							case SYBINT2:
								if (sybInt2Bind && sybInt2BindNull && columnIndexOfType < resultCountForType_SYBINT2) {
									dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(int), (BYTE *)&sybInt2Bind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybInt2BindNull[columnIndexOfType]);
								}
								break;
								
							case SYBINT4:
								if (sybInt4Bind && sybInt4BindNull && columnIndexOfType < resultCountForType_SYBINT4) {
									dbbind(dbconn, columnOffsetNumber, INTBIND, sizeof(int), (BYTE *)&sybInt4Bind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybInt4BindNull[columnIndexOfType]);
								}
								break;
								
							case SYBINT8:
								if (sybInt8Bind && sybInt8BindNull && columnIndexOfType < resultCountForType_SYBINT8) {
									dbbind(dbconn, columnOffsetNumber, BIGINTBIND, sizeof(long long), (BYTE *)&sybInt8Bind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybInt8BindNull[columnIndexOfType]);
								}
								break;
								
							case SYBBIT:
								if (sybBitBind && sybBitBindNull && columnIndexOfType < resultCountForType_SYBBIT) {
									dbbind(dbconn, columnOffsetNumber, BITBIND, sizeof(BOOL), (BYTE *)&sybBitBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybBitBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBBITN:
								if (sybBitNBind && sybBitNBindNull && columnIndexOfType < resultCountForType_SYBBITN) {
									dbbind(dbconn, columnOffsetNumber, BITBIND, sizeof(BOOL), (BYTE *)&sybBitNBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybBitNBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBFLTN:
								if (sybFltNBind && sybFltNBindNull && columnIndexOfType < resultCountForType_SYBFLTN) {
									dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybFltNBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybFltNBindNull[columnIndexOfType]);
								}
								break;
							case SYBFLT8:
								if (sybFlt8Bind && sybFlt8BindNull && columnIndexOfType < resultCountForType_SYBFLT8) {
									dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybFlt8Bind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybFlt8BindNull[columnIndexOfType]);
								}
								break;
							case SYBREAL:
								if (sybRealBind && sybRealBindNull && columnIndexOfType < resultCountForType_SYBREAL) {
									dbbind(dbconn,
										   columnOffsetNumber,
										   FLT8BIND,
										   (DBINT)columnLengthMeta,
										   (BYTE *)&sybRealBind[columnIndexOfType]);
									dbnullbind(dbconn,
											   columnOffsetNumber,
											   &sybRealBindNull[columnIndexOfType]);
								}
								break;
							case SYBDECIMAL:
							case SYBNUMERIC: {
								if (sybNumericBindChar && sybNumericBindNull && columnIndexOfType < resultCountForTypeSybNumericBindChar) {
									sybNumericBindChar[columnIndexOfType] = malloc( sizeof(char) * ( columnLengthMeta + 1 ) );
									dbbind(dbconn, columnOffsetNumber, NTBSTRINGBIND, (DBINT)columnLengthMeta, (BYTE *)sybNumericBindChar[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybNumericBindNull[columnIndexOfType]);
								}
								break;
							}
							case SYBMONEYN:
								if (sybMoneyNBind && sybMoneyNBindNull && columnIndexOfType < resultCountForType_SYBMONEYN) {
									dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybMoneyNBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybMoneyNBindNull[columnIndexOfType]);
								}
								break;
							case SYBMONEY:
								if (sybMoneyBind && sybMoneyBindNull && columnIndexOfType < resultCountForType_SYBMONEY) {
									dbbind(dbconn, columnOffsetNumber, FLT8BIND, (DBINT)columnLengthMeta, (BYTE *)&sybMoneyBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybMoneyBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBDATETIME:
								if (sybDateTimeBind && sybDateTimeBindNull && columnIndexOfType < resultCountForType_SYBDATETIME) {
									sybDateTimeBind[columnIndexOfType] = malloc(sizeof(DBDATETIME));
									dbbind(dbconn, columnOffsetNumber, DATETIMEBIND, sizeof(DBDATETIME), (BYTE *)sybDateTimeBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybDateTimeBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBDATETIMN:
								if (sybDateTimnBind && sybDateTimnBindNull && columnIndexOfType < resultCountForType_SYBDATETIMN) {
									sybDateTimnBind[columnIndexOfType] = malloc(sizeof(DBDATETIME));
									dbbind(dbconn, columnOffsetNumber, DATETIMEBIND, sizeof(DBDATETIME), (BYTE *)sybDateTimnBind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybDateTimnBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBDATETIME4:
								if (sybDateTime4Bind && sybDateTime4BindNull && columnIndexOfType < resultCountForType_SYBDATETIME4) {
									sybDateTime4Bind[columnIndexOfType] = malloc(sizeof(DBDATETIME4));
									dbbind(dbconn, columnOffsetNumber, SMALLDATETIMEBIND, sizeof(DBDATETIME4), (BYTE *)sybDateTime4Bind[columnIndexOfType]);
									dbnullbind(dbconn, columnOffsetNumber, &sybDateTime4BindNull[columnIndexOfType]);
								}
								break;
								
							case SYBIMAGE:
								if (sybImageBind && sybImageBindNull && columnIndexOfType < resultCountForType_SYBIMAGE) {
									// The size parameter here in dbbind should be the max possible length of the image data, not sizeof(BYTE*).
									// For very large objects, dbbind might not be the most appropriate method; often dbbind with a NULL pointer and
									// then dbreadtext/dbwritetext is used. Retaining original approach but correcting sizeof.
									dbbind(dbconn, columnOffsetNumber, BINARYBIND, (int)dbcollen(dbconn, columnOffsetNumber), (BYTE *)sybImageBind[columnIndexOfType]); // Use actual column length
									dbnullbind(dbconn, columnOffsetNumber, &sybImageBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBBINARY:
								if (sybBinaryBind && sybBinaryBindNull && columnIndexOfType < resultCountForType_SYBBINARY) {
									dbbind(dbconn, columnOffsetNumber, BINARYBIND, (int)dbcollen(dbconn, columnOffsetNumber), (BYTE *)&sybBinaryBind[columnIndexOfType]); // Use actual column length
									dbnullbind(dbconn, columnOffsetNumber, &sybBinaryBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBVOID:
								if (sybVoidBindNull && columnIndexOfType < resultCountForType_SYBVOID) {
									dbnullbind(dbconn, columnOffsetNumber, &sybVoidBindNull[columnIndexOfType]);
								}
								break;
								
							case SYBVARBINARY:
								if (sybVarBinaryBindNull && columnIndexOfType < resultCountForType_SYBVARBINARY) {
									dbnullbind(dbconn, columnOffsetNumber, &sybVarBinaryBindNull[columnIndexOfType]);
								}
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
						int indexOfType; // Declare indexOfType here for proper scope
						for (NSDictionary *columnMetaData in colmunHolder) {
							
							indexOfType = [columnMetaData[MTDatabaseColumnIndexOfType] intValue]; // Assign value here
							
							NSString *fieldName = columnMetaData[MTDatabaseColumnNameId];
							
							NSInteger columnNumber = [columnMetaData[MTDatabaseColumnNumberId] intValue]; // columnNumber is not used here
							
							switch ([columnMetaData[MTDatabaseColumnTypeId] integerValue]) {
									
								case SYBDECIMAL:
								case SYBNUMERIC: {
									// Add robust null and bounds checks
									if (sybNumericBindNull && indexOfType < resultCountForTypeSybNumericBindChar && sybNumericBindNull[indexOfType] != -1) {
										
										NSString *objectStr = [[NSString alloc] initWithCString: sybNumericBindChar[indexOfType]
																					   encoding: NSStringEncodingConversionAllowLossy];
										
										// The columnPercision logic is maintained as per original intent.
										NSInteger cp = [columnPercision[columnCounter] integerValue];
										
										NSString *decimalSeperatorSqlServer2 = nil;
										if (cp == -1 && tdsDecimalSeperatorMatchesCocoaDecimalSeperatorResolved == NO) {

											// Find the decimal separator: the first character that is
											// neither a digit nor a leading sign.  Trimming the digit set
											// off both ends (the old approach) turned "-2.5" into "-.", so
											// the replacement below rewrote -2.5 as .5.
											NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
											NSString *seperator = @"";
											for (NSUInteger i = 0; i < objectStr.length; i++) {
												unichar c = [objectStr characterAtIndex:i];
												if ((c == '-' || c == '+') && i == 0) continue;
												if (![characterSet characterIsMember:c]) {
													seperator = [NSString stringWithCharacters:&c length:1];
													break;
												}
											}
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
										
										// Default to the string as returned.  It used to stay nil unless a
										// separator substitution happened, so every integer-valued DECIMAL
										// and every numeric whose separator already matched the locale was
										// fed to NSDecimalNumber as nil (NaN).
										NSString *objectStr2 = objectStr;

										if (tdsDecimalSeperatorMatchesCocoaDecimalSeperator == NO &&
											decimalSeperatorSqlServer2.length > 0) {
											objectStr2 = [objectStr stringByReplacingOccurrencesOfString:decimalSeperatorSqlServer2 withString:decimalSeperator];
										}

										NSDecimalNumber *decimalNumber = objectStr2 ? [[NSDecimalNumber alloc] initWithString:objectStr2] : nil;
										if (decimalNumber) {
											resultsForRow[fieldName] = decimalNumber;
										} else {
											resultsForRow[fieldName] = [NSNull null]; // Use NSNull for error conversion instead of "Error" string
										}
										
										objectStr = nil; objectStr2 = nil;
										
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Numeric NULL
									}
									break;
								}
								case SYBREAL: {
									if (sybRealBindNull && indexOfType < resultCountForType_SYBREAL && sybRealBindNull[indexOfType] != -1) {
										NSNumber *object = [[NSNumber alloc] initWithFloat:sybRealBind[indexOfType]];
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Real NULL
									}
									break;
								}
								case SYBFLTN: {
									if (sybFltNBindNull && indexOfType < resultCountForType_SYBFLTN && sybFltNBindNull[indexOfType] != -1) {
										// FIXED: Used sybFltNBind instead of sybRealBind
										NSNumber *object = [[NSNumber alloc] initWithFloat:sybFltNBind[indexOfType]];
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Float N NULL
									}
									break;
								}
								case SYBFLT8: {
									if (sybFlt8BindNull && indexOfType < resultCountForType_SYBFLT8 && sybFlt8BindNull[indexOfType] != -1) {
										NSNumber *object = @(sybFlt8Bind[indexOfType]);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Float 8 NULL
									}
									break;
								}
									
								case SYBCHAR: {
									if (sybCharBindNull && indexOfType < resultCountForTypeSybCharBind && sybCharBindNull[indexOfType] != -1) {
										char *sybChar = sybCharBind[indexOfType];
										if (sybChar != nil) { // Check if pointer is valid (not null)
											NSString *object = [[NSString alloc] initWithCString: sybChar
																						encoding: NSStringEncodingConversionAllowLossy];
											resultsForRow[fieldName] = object;
										} else { // Handle empty string vs nil char*
											resultsForRow[fieldName] = [NSNull null]; // Assign NSNull if char* is nil despite not being DB NULL
										}
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Char NULL
									}
									break;
								}
									
								case SYBVARCHAR: {
									if (sybVarCharBindNull && indexOfType < resultCountForTypeSybVarCharBind && sybVarCharBindNull[indexOfType] != -1) {
										char *sybVarChar = sybVarCharBind[indexOfType];
										if (sybVarChar != nil) {
											NSString *object = [[NSString alloc] initWithCString: sybVarChar
																						encoding: NSStringEncodingConversionAllowLossy];
											resultsForRow[fieldName] = object;
										} else {
											resultsForRow[fieldName] = [NSNull null];
										}
									} else {
										resultsForRow[fieldName] = [NSNull null]; // VarChar NULL
									}
									break;
								}
								case SYBNVARCHAR: {
									if (sybnVarCharBindNull && indexOfType < resultCountForTypeSybnVarCharBind && sybnVarCharBindNull[indexOfType] != -1) {
										char *sybnVarChar = sybnVarCharBind[indexOfType];
										if (sybnVarChar != nil) {
											NSString *object = [[NSString alloc] initWithCString: sybnVarChar
																						encoding: NSStringEncodingConversionAllowLossy];
											resultsForRow[fieldName] = object;
										} else {
											resultsForRow[fieldName] = [NSNull null];
										}
									} else {
										resultsForRow[fieldName] = [NSNull null]; // NVarChar NULL
									}
									break;
								}
								case SYBTEXT: {
									if (sybTextBindNull && indexOfType < resultCountForTypeSybTextBind && sybTextBindNull[indexOfType] != -1) {
										
										char *sybText = sybTextBind[indexOfType];
										if (sybText != nil) {
											NSString *object = [[NSString alloc] initWithCString: sybText
																						encoding: NSStringEncodingConversionAllowLossy];
											resultsForRow[fieldName] = object;
										} else {
											resultsForRow[fieldName] = [NSNull null];
										}
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Text NULL
									}
									break;
								}
								case SYBNTEXT: {
									if (sybnTextBindNull && indexOfType < resultCountForTypeSybnTextBind && sybnTextBindNull[indexOfType] != -1) {
										// FIXED: Used sybnTextBind instead of sybnVarCharBind
										char *sybnTest = sybnTextBind[indexOfType];
										if (sybnTest != nil) {
											NSString *object = [[NSString alloc] initWithCString: sybnTest
																						encoding: NSStringEncodingConversionAllowLossy];
											resultsForRow[fieldName] = object;
										} else {
											resultsForRow[fieldName] = [NSNull null];
										}
									} else {
										resultsForRow[fieldName] = [NSNull null]; // NText NULL
									}
									break;
								}
									
								case SYBINTN: {
									if (sybIntnBindNull && indexOfType < resultCountForType_SYBINTN && sybIntnBindNull[indexOfType] != -1) {
										long long integer = sybIntnBind[indexOfType];
										NSNumber *object = @((NSInteger)integer);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Integer N NULL
									}
									break;
								}
								case SYBINT1: {
									if (sybInt1BindNull && indexOfType < resultCountForType_SYBINT1 && sybInt1BindNull[indexOfType] != -1) {
										int integer = sybInt1Bind[indexOfType];
										NSNumber *object = @(integer);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Integer 1 NULL
									}
									break;
								}
								case SYBINT2: {
									if (sybInt2BindNull && indexOfType < resultCountForType_SYBINT2 && sybInt2BindNull[indexOfType] != -1) {
										int integer = sybInt2Bind[indexOfType];
										NSNumber *object = @(integer);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Integer 2 NULL
									}
									break;
								}
								case SYBINT4: {
									if (sybInt4BindNull && indexOfType < resultCountForType_SYBINT4 && sybInt4BindNull[indexOfType] != -1) {
										int integer = sybInt4Bind[indexOfType];
										NSNumber *object = @(integer);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Integer 4 NULL
									}
									break;
								}
								case SYBINT8: {
									if (sybInt8BindNull && indexOfType < resultCountForType_SYBINT8 && sybInt8BindNull[indexOfType] != -1) {
										NSNumber *object = @(sybInt8Bind[indexOfType]);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Integer 8 NULL
									}
									break;
								}
								case SYBDATETIME4: {
									if (sybDateTime4BindNull && indexOfType < resultCountForType_SYBDATETIME4 && sybDateTime4BindNull[indexOfType] != -1) {
										DBDATETIME4 smallDate = *sybDateTime4Bind[indexOfType];
										
										NSDateComponents *offsetCompsDays = [[NSDateComponents alloc] init];
										offsetCompsDays.day = smallDate.days;
										
										NSDate *object = [gregorian dateByAddingComponents:offsetCompsDays toDate:janFirst1990 options:0];
										
										
										NSDateComponents *smallDaysComponentsPart1 = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
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
									} else {
										resultsForRow[fieldName] = [NSNull null]; // DateTime4 NULL
									}
									break;
								}
									
								case SYBDATETIME: {
									// Robust null check for the array itself first
									if (sybDateTimeBindNull && indexOfType < resultCountForType_SYBDATETIME && sybDateTimeBindNull[indexOfType] != -1) {
										struct tds_sybase_dbdaterec dateinfo;
										// CORRECTED: Copy data INTO the malloc'd memory block
										memcpy(sybDateTimeBind[indexOfType], (DBDATETIME *) (dbdata(dbconn, (int)(columnNumber + 1))), sizeof(DBDATETIME));
										// CORRECTED: Pass the pointer to the structure to dbdatecrack
										dbdatecrack(dbconn, &dateinfo, sybDateTimeBind[indexOfType]);
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
										resultsForRow[fieldName] = [NSNull null]; // DateTime NULL
									}
									break;
								}
									
								case SYBDATETIMN: {
									// Robust null check for the array itself first
									if (sybDateTimnBindNull && indexOfType < resultCountForType_SYBDATETIMN && sybDateTimnBindNull[indexOfType] != -1) {
										struct tds_sybase_dbdaterec dateinfo;
										// CORRECTED: Copy data INTO the malloc'd memory block
										memcpy(sybDateTimnBind[indexOfType], (DBDATETIME *) (dbdata(dbconn, (int)(columnNumber + 1))), sizeof(DBDATETIME));
										// CORRECTED: Pass the pointer to the structure to dbdatecrack
										dbdatecrack(dbconn, &dateinfo, sybDateTimnBind[indexOfType]);
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
										resultsForRow[fieldName] = [NSNull null]; // DateTime N NULL
									}
									break;
								}
									
								case SYBBIT: {
									if (sybBitBindNull && indexOfType < resultCountForType_SYBBIT && sybBitBindNull[indexOfType] != -1) {
										NSNumber *object = @((BOOL)sybBitBind[indexOfType]);
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Bit NULL
									}
									break;
								}
									
								case SYBBITN: {
									if (sybBitNBindNull && indexOfType < resultCountForType_SYBBITN && sybBitNBindNull[indexOfType] != -1) {
										NSNumber *object = [[NSNumber alloc] initWithInt:(BOOL)sybBitNBind[indexOfType]];
										resultsForRow[fieldName] = object;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Bit N NULL
									}
									break;
								}
									
								case SYBIMAGE: {
									if (sybImageBindNull && indexOfType < resultCountForType_SYBIMAGE && sybImageBindNull[indexOfType] != -1) {
										// Image data processing not fully implemented, returning NSNull for non-null value
										// To properly handle, you would need to use dbreadtext/dbwritetext or similar methods.
										resultsForRow[fieldName] = [NSNull null];
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Image NULL
									}
									break;
								}
								case SYBMONEY: {
									if (sybMoneyBindNull && indexOfType < resultCountForType_SYBMONEY && sybMoneyBindNull[indexOfType] != -1) {
										double money = sybMoneyBind[indexOfType];
										NSNumber *moneyNumber = @(money);
										resultsForRow[fieldName] = moneyNumber;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Money NULL
									}
									break;
								}
								case SYBMONEYN: {
									if (sybMoneyNBindNull && indexOfType < resultCountForType_SYBMONEYN && sybMoneyNBindNull[indexOfType] != -1) {
										double money = sybMoneyNBind[indexOfType];
										NSNumber *moneyNumber = @(money);
										resultsForRow[fieldName] = moneyNumber;
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Money N NULL
									}
									break;
								}
								case SYBBINARY: {
									if (sybBinaryBindNull && indexOfType < resultCountForType_SYBBINARY && sybBinaryBindNull[indexOfType] != -1) {
										// Binary data processing not fully implemented, returning NSNull for non-null value
										resultsForRow[fieldName] = [NSNull null];
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Binary NULL
									}
									break;
								}
								case SYBVOID: {
									if (sybVoidBindNull && indexOfType < resultCountForType_SYBVOID && sybVoidBindNull[indexOfType] != -1) {
										// Void data processing not fully implemented, returning NSNull for non-null value
										resultsForRow[fieldName] = [NSNull null];
									} else {
										resultsForRow[fieldName] = [NSNull null]; // Void NULL
									}
									break;
								}
								case SYBVARBINARY: {
									if (sybVarBinaryBindNull && indexOfType < resultCountForType_SYBVARBINARY && sybVarBinaryBindNull[indexOfType] != -1) {
										// VarBinary data processing not fully implemented, returning NSNull for non-null value
										resultsForRow[fieldName] = [NSNull null];
									} else {
										resultsForRow[fieldName] = [NSNull null]; // VarBinary NULL
									}
									break;
								}
									
								default:
									// For any other unhandled types, explicitly return NSNull
									resultsForRow[fieldName] = [NSNull null];
									break;
							}
							
							columnCounter++;
						}
						
						[datatable addRowWithDataForFieldKeys:resultsForRow];
						[self readRow:rowCounter];
						rowCounter++;
					}
					
					// Frees for individual char* and DBDATETIME* pointers
					if (sybNumericBindChar) {
						for (NSInteger i=0; i<resultCountForTypeSybNumericBindChar; i++) {
							if (sybNumericBindChar[i] != NULL) free(sybNumericBindChar[i]);
						}
					}
					if (sybCharBind) {
						for (NSInteger i=0; i<resultCountForTypeSybCharBind; i++) {
							if (sybCharBind[i] != NULL) free(sybCharBind[i]);
						}
					}
					if (sybVarCharBind) {
						for (NSInteger i = 0; i < resultCountForTypeSybVarCharBind; i++) {
							if (sybVarCharBind[i] != NULL) free(sybVarCharBind[i]);
						}
					}
					if (sybnVarCharBind) {
						for (NSInteger i = 0; i < resultCountForTypeSybnVarCharBind; i++) {
							if (sybnVarCharBind[i] != NULL) free(sybnVarCharBind[i]);
						}
					}
					if (sybTextBind) {
						for (NSInteger i = 0; i < resultCountForTypeSybTextBind; i++) {
							if (sybTextBind[i] != NULL) free(sybTextBind[i]);
						}
					}
					if (sybnTextBind) {
						for (NSInteger i = 0; i < resultCountForTypeSybnTextBind; i++) {
							if (sybnTextBind[i] != NULL) free(sybnTextBind[i]);
						}
					}
					
					if (sybDateTimeBind) {
						for (NSInteger i = 0; i < resultCountForType_SYBDATETIME; i++) {
							if (sybDateTimeBind[i]) free(sybDateTimeBind[i]);
						}
					}
					if (sybDateTime4Bind) {
						for (NSInteger i = 0; i < resultCountForType_SYBDATETIME4; i++) {
							if (sybDateTime4Bind[i]) free(sybDateTime4Bind[i]);
						}
					}
					if (sybDateTimnBind) {
						for (NSInteger i = 0; i < resultCountForType_SYBDATETIMN; i++) {
							if (sybDateTimnBind[i]) free(sybDateTimnBind[i]);
						}
					}
					
					// Frees for main arrays of pointers and value arrays
					if (sybRealBind) free(sybRealBind);
					if (sybRealBindNull) free(sybRealBindNull);
					if (sybFltNBind) free(sybFltNBind);
					if (sybFltNBindNull) free(sybFltNBindNull);
					if (sybFlt8Bind) free(sybFlt8Bind);
					if (sybFlt8BindNull) free(sybFlt8BindNull);
					if (sybInt1Bind) free(sybInt1Bind);
					if (sybInt1BindNull) free(sybInt1BindNull);
					if (sybInt2Bind) free(sybInt2Bind);
					if (sybInt2BindNull) free(sybInt2BindNull);
					if (sybIntnBind) free(sybIntnBind);
					if (sybIntnBindNull) free(sybIntnBindNull);
					if (sybInt4Bind) free(sybInt4Bind);
					if (sybInt4BindNull) free(sybInt4BindNull);
					if (sybInt8Bind) free(sybInt8Bind);
					if (sybInt8BindNull) free(sybInt8BindNull);
					if (sybMoneyBind) free(sybMoneyBind);
					if (sybMoneyBindNull) free(sybMoneyBindNull);
					if (sybMoneyNBind) free(sybMoneyNBind);
					if (sybMoneyNBindNull) free(sybMoneyNBindNull);
					
					if (sybNumericBindChar) free(sybNumericBindChar);
					if (sybNumericBindNull) free(sybNumericBindNull);
					if (sybCharBind) free(sybCharBind);
					if (sybCharBindNull) free(sybCharBindNull);
					if (sybVarCharBind) free(sybVarCharBind);
					if (sybVarCharBindNull) free(sybVarCharBindNull);
					if (sybnVarCharBind) free(sybnVarCharBind);
					if (sybnVarCharBindNull) free(sybnVarCharBindNull);
					if (sybTextBind) free(sybTextBind);
					if (sybTextBindNull) free(sybTextBindNull);
					if (sybnTextBind) free(sybnTextBind);
					if (sybnTextBindNull) free(sybnTextBindNull);
					if (sybDateTimeBind) free(sybDateTimeBind);
					if (sybDateTimeBindNull) free(sybDateTimeBindNull);
					if (sybDateTime4Bind) free(sybDateTime4Bind);
					if (sybDateTime4BindNull) free(sybDateTime4BindNull);
					if (sybDateTimnBind) free(sybDateTimnBind);
					if (sybDateTimnBindNull) free(sybDateTimnBindNull);
					if (sybImageBind) free(sybImageBind);
					if (sybImageBindNull) free(sybImageBindNull);
					if (sybBinaryBind) free(sybBinaryBind);
					if (sybBinaryBindNull) free(sybBinaryBindNull);
					if (sybVarBinaryBindNull) free(sybVarBinaryBindNull);
					if (sybVoidBindNull) free(sybVoidBindNull);
					if (sybBitBind) free(sybBitBind);
					if (sybBitBindNull) free(sybBitBindNull);
					if (sybBitNBind) free(sybBitNBind);
					if (sybBitNBindNull) free(sybBitNBindNull);
					
				} // End while (dbresults(dbconn) != NO_MORE_RESULTS)
				[datatable endBulkInsert];
				rsuccess = YES;
				
			} else {
				NSString *message = @"Sql Syntax Error";
				NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
				localError = [NSError errorWithDomain:MADDomainTDS code:87635 userInfo:errorInfo]; // Assign to localError
				rsuccess = NO;
			}
			// Ownership contract: -runSQL: closes the process it is given.  Callers were
			// written against this -- MADOperationRefresh.m and
			// -executeQuery:withDataTable:andError: each open one process, run one
			// statement, and never close it themselves.  Removing this dbclose would leak
			// a DBPROCESS per query.  Do not change without first giving those callers
			// explicit ownership and a close of their own.
			dbclose(dbconn);

		} else {
			localError = [NSError errorWithDomain:MADDomainTDS // Assign to localError
											 code:4379
										 userInfo:@{
				NSLocalizedDescriptionKey : NSLocalizedString(@"Bad Process", @"Bad Process"),
				NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Could not run this query.", @"Could not run this query.")
			}];
			rsuccess = NO;
		}
		
	} else {
		localError = [NSError errorWithDomain:MADDomainTDS // Assign to localError
										 code:4378
									 userInfo:@{
			NSLocalizedDescriptionKey : NSLocalizedString(@"Bad Query", @"Bad Query"),
			NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Could not run this query.", @"Could not run this query.")
		}];
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

	// Callers may pass NULL for "I don't care"; route writes to a throwaway local then.
	// This also means the flag checks below never dereference a NULL pointer, and the
	// former `if (*error != NULL)` guard on the dbinit failure -- which was inverted and
	// so silently dropped that failure -- is gone.
	NSError * __autoreleasing localError = nil;
	NSError * __autoreleasing *err = (error != NULL) ? error : &localError;
	*err = nil;

	LOGINREC *login;
	char hostname[30];
	size_t max_len = 30;


	/* Init the DB library */
	if (dbinit() == FAIL) {
		NSString *message = @"Could not init db.";
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
		*err = [NSError errorWithDomain:MADDomainTDS code:1 userInfo:errorInfo];
	}
	dberrhandle(err_handler);

	if (*err == nil) {
		login = dblogin();
		if (login == FAIL) {
			NSString *message = @"Could not initialize dblogin() structure.";
			NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
			*err = [NSError errorWithDomain:MADDomainTDS code:2 userInfo:errorInfo];
		}

		if (*err == nil) {
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
		
		if (*err == nil) {

			// This db-lib build has no DBSETLPORT, so the port travels in the server
			// string dbopen takes ("host:port").  Resolve the host first, then append.
			NSString *serverName = [MADDatabaseSQLServer IPAddressForServer:self.databaseConnection.server];
			NSInteger port = self.databaseConnection.port;
			if (port > 0) {
				serverName = [NSString stringWithFormat:@"%@:%ld", serverName, (long)port];
			}
			char *s = (char *)[serverName cStringUsingEncoding:NSUTF8StringEncoding];
			dbconn = dbopen(login, s);
			if (dbconn == NULL) {
				NSString *message;
				NSDictionary *errorInfo;

				message = [[NSString alloc] initWithFormat:@"Could not connect to DB Server: %s\n", s];
				errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys: message, NSLocalizedDescriptionKey, nil];
				*err = [NSError errorWithDomain:MADDomainTDS code:2 userInfo:errorInfo];

			}

		}
		connected = (*err == nil);
		
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
		if (dberror != nil) {
			// Write through to the caller's pointee.  Rebinding `error` to the local
			// instead (`error = &dberror`) left the caller's error nil, so a failed
			// connection returned nil with no way to say why.
			if (error != NULL) {
				*error = dberror;
			}
			[self.errors insertObject:dberror atIndex:0];
		} else {
			dbwrap = [[MADDatabaseProcessSQLServer alloc] initWithProcess:dbconn];
		}
		
	}
	
	return dbwrap; //(__bridge id)(dbconn);
}

- (NSString *)identifier { return self.databaseConnection.identifier; }

- (id)connectionSettings { return self.databaseConnection; }

- (NSString *)fieldAliasForField:(NSString *)field withSafeTableName:(NSString *)safeTableName {
	//NSString *safeTableName = [self shortAliasFromQualifiedTable:safeTableName];	//Calling this function removes the schema part.
	return [[safeTableName stringByAppendingString:@"."] stringByAppendingString:[self newSafeIdentifier:field]];
}

- (NSString *)shortAliasFromQualifiedTable:(NSString *)qualifiedName {
	return [[qualifiedName componentsSeparatedByString:@"."] lastObject] ?: qualifiedName;
}

+ (NSString *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
	// Split the table half on its dot so a schema-qualified name yields
	// [schema].[table], not one bracket pair containing a dot -- T-SQL would read the
	// latter as a table literally named "schema.table".  Dot-free aliases are unaffected.
	NSString *safeTable = [self newSafeIdentifier:tableName];
	NSString *safeQueryField = [[NSString alloc] initWithFormat:@"%@.[%@]", safeTable, fieldName];
	return safeQueryField;
}
- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [MADDatabaseSQLServer newSafeQueryField:fieldName andTable:tableName];
}

+ (NSString *)newSafeIdentifier:(NSString *)fieldOrTableName {
	if ([fieldOrTableName rangeOfString:@"."].location == NSNotFound) {
		return [NSString stringWithFormat:@"[%@]", fieldOrTableName];
	}
	
	return [self bracketedIdentifierFromName:fieldOrTableName];
}

- (NSString *)newSafeIdentifier:(NSString *)fieldOrTableName {
	return [MADDatabaseSQLServer newSafeIdentifier:fieldOrTableName];
}

+ (NSString *)bracketedIdentifierFromName:(NSString *)name {
	NSArray<NSString *> *components = [name componentsSeparatedByString:@"."];
	NSMutableArray<NSString *> *wrappedComponents = [NSMutableArray arrayWithCapacity:components.count];
	
	for (NSString *part in components) {
		if (part.length > 0) {
			NSString *wrapped = [NSString stringWithFormat:@"[%@]", part];
			[wrappedComponents addObject:wrapped];
		}
	}
	
	return [wrappedComponents componentsJoinedByString:@"."];
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

- (NSString *)sqlRangeClauseWithLimit:(NSUInteger)limit offset:(NSUInteger)offset {
	return [NSString stringWithFormat:@"OFFSET %ld ROWS FETCH NEXT %ld ROWS ONLY", offset, limit];
}
- (NSString *)sqlDefaultRequiredOrderByClause { return @"ORDER BY (SELECT NULL)"; }

- (NSString *)sqlLimitClause { return @""; }

- (NSString *)sqlLimitClause:(NSUInteger)limit { return @""; }

// Deliberately does not compose the base -sqlSampleDataForField:andTable: despite the
// duplication.  The base implementation (MADAPI/Source/MADDatabase.m) hardcodes
// "LIMIT 511;" into its format string and does not go through -sqlLimitClause, so SQL
// Server's empty limit clause cannot neutralise it; composing would emit invalid T-SQL.
// Hence the hand-built TOP 511 below.  Do not "deduplicate" these two methods.
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
		
		dbcmd(dbconn,
			  "SELECT s.name + '.' + t.name AS full_name "
			  "FROM sys.tables t "
			  "JOIN sys.schemas s ON t.schema_id = s.schema_id "
			  "ORDER BY full_name");
		
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
		
		dbcmd(dbconn,
			  "SELECT s.name + '.' + t.name AS full_name "
			  "FROM sys.tables t "
			  "JOIN sys.schemas s ON t.schema_id = s.schema_id "
			  "ORDER BY full_name");
		
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
	if (completion) completion(error == nil, error, results);
}

- (void)getTablesFromConnection:(id)process
					 completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	
	id results = nil;
	NSError *error = nil;
	DBPROCESS *dbconn = [process process];
	if (dbconn) {
		
		dbcmd(dbconn,
			  "SELECT s.name + '.' + t.name AS full_name "
			  "FROM sys.tables t "
			  "JOIN sys.schemas s ON t.schema_id = s.schema_id "
			  "ORDER BY full_name");

		
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
	if (completion) completion(error == nil, error, results);
}

#pragma mark - Reading Fields
//Reads fields
- (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName connection:(id)process error:(NSError * __autoreleasing *)error {
	NSMutableArray *results = nil;
	RETCODE sqlReturnCode = FAIL;
	DBPROCESS *dbconn = [process process];
	if (dbconn) {
		NSString *queryFormat = @"SELECT name, system_type_id, max_length, precision, scale FROM "
								@"sys.columns WHERE object_id = OBJECT_ID('%@')";
		NSString *query = [[NSString alloc] initWithFormat:queryFormat, tableName];
		dbcmd(dbconn, [query cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
		
		sqlReturnCode = dbsqlexec(dbconn);
		
		if (sqlReturnCode != SUCCEED) {
			// Report the failure to the caller.  The old condition only ran when
			// `error == NULL`, then dereferenced that very NULL in its NSAssert -- the
			// app never saw a dbsqlexec failure, and Debug builds crashed instead.
			if (error != NULL) {
				NSString *message = @"Sql Syntax Error";
				NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
				*error = [NSError errorWithDomain:MADDomainTDS code:3456 userInfo:errorInfo];
			}
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
						// typeBind is sys.columns.system_type_id, not a sybdb type code, so it
						// must go through the system-type mapping rather than
						// +dataTypeForNativeType: (the two happen to agree for some ids,
						// which is why the old code looked like it worked).
						databaseField.fieldTypeNative = [MADDatabaseSQLServer dataTypeForSystemTypeId:typeBind];
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
