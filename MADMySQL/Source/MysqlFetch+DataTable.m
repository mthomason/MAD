//
//  MysqlFetch+DataTable.m
//  MAD
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MysqlFetch+DataTable.h"
#import "MADDataTypeMySQL.h"
#import "MysqlConnection.h"
#import "MysqlFetchField.h"
#import "MysqlException.h"

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSCalendar.h>
#import <string.h>
#import <os/log.h>

#ifndef __OBJC_GC__
#define BLOB_DEFAULT_SIZE 10000
#else
#define BLOB_DEFAULT_SIZE 1000000
#endif

#define BUFFER_SIZE_BLOB_TINY    257
#define BUFFER_SIZE_BLOB         65538
#define BUFFER_SIZE_BLOB_MEDIUM  16777219       //128 MB
#define BUFFER_SIZE_BLOB_LONG    42949667300    //~1/3 of a TB

enum enum_field_types bufferTypeForBindingAtPosition(MYSQL_BIND *bindings, int position);
char *mySqlTypeForBindingAtPosition(MYSQL_BIND *bindings, int position);

@implementation MysqlFetch (DataTable)

+ (NSString *)tableForField:(MYSQL_FIELD)field NS_RETURNS_RETAINED {
	NSString *table = [[NSString alloc]  initWithBytes: field.table
												length: field.table_length
											  encoding: NSUTF8StringEncoding];
	return table;
}

+ (NSString *)fieldNameForField:(MYSQL_FIELD)field andTable:(NSString *)table NS_RETURNS_RETAINED {
	NSString *fieldKeyName = [self fieldNameForField:field];
	NSString *fieldName;
	fieldName = table.length > 0 ? [[NSString alloc] initWithFormat:@"`%@`.`%@`", table, fieldKeyName] :
	[[NSString alloc] initWithFormat:@"`%@`", fieldKeyName];
	return fieldName;
}


+ (NSString *)fieldNameForField:(MYSQL_FIELD)field NS_RETURNS_RETAINED {
	NSString *fieldName = [[NSString alloc]  initWithBytes: field.name
													length: field.name_length
												  encoding: NSUTF8StringEncoding];
	return fieldName;
}

- (NSString *)domain {
	return NSStringFromClass([self class]);
}

- (MADDataTable *)fetchWithCommand: (NSString *)command
						dataTable: (MADDataTable * __autoreleasing *)dataTable
					 onConnection: (MysqlConnection *)connection
							error: (NSError * __autoreleasing *)error {
	return [self fetchWithCommand:command dataTable:dataTable onConnection:connection extendedNames:YES error:error];
}


- (MADDataTable *)fetchWithCommand: (NSString *)command
						dataTable: (MADDataTable * __autoreleasing *)dataTable
					 onConnection: (MysqlConnection *)connection
					extendedNames: (BOOL)useExtendedNames
							error: (NSError * __autoreleasing *)error {
	
	MysqlFetch *mf = [[MysqlFetch alloc] init];
	NSError *errorFetch = nil;
	
	if (!connection) {
		errorFetch = [NSError errorWithDomain:[self domain] code:3492 userInfo:@{
			NSLocalizedDescriptionKey : @"Connection is empty.",
			NSLocalizedFailureReasonErrorKey : @"Connection Error"
		}];
		// Without this the caller sees a nil error for a nil connection and cannot
		// tell the call apart from a successful one.
		if (error != NULL) *error = errorFetch;
	}
	
	if (errorFetch == nil) {
		
		MYSQL_STMT *myStatement = mysql_stmt_init(connection.connection);
		
		const char *cCommand = command.UTF8String;
		
		int prepareResult = mysql_stmt_prepare(myStatement, cCommand, strlen(cCommand));
		
		if (prepareResult) {
			const char *err = mysql_stmt_error(myStatement);
			unsigned int code = mysql_stmt_errno(myStatement);
			NSString *errorString = [[NSString alloc] initWithFormat:@"MySQL says %d! %s.", code, err];
			NSDictionary *errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
									   errorString, NSLocalizedDescriptionKey,
									   @"Error", NSLocalizedFailureReasonErrorKey, nil];
			errorFetch = [NSError errorWithDomain:@"mad" code:(NSInteger)code userInfo:errorInfo];
			if (error != NULL) *error = errorFetch;
			
		} else {
			
			// build out and connect the bindings
			
			MYSQL_BIND *bindings = calloc(myStatement->field_count, sizeof(MYSQL_BIND));
			
			// Notes on how MySQL numeric datatypes are handled in the code following:
			//
			// INTEGER datatype handled by MYSQL_TYPE_LONG
			// INT datatype handled by MYSQL_TYPE_LONG
			// BIGINT datatype handled by MYSQL_TYPE_LONGLONG
			// TINYINT datatype handled by MYSQL_TYPE_TINY
			// REAL datatype handled by MYSQL_TYPE_DOUBLE
			// DOUBLE datatype handled by MYSQL_TYPE_DOUBLE
			// FLOAT datatype handled by MYSQL_TYPE_FLOAT
			// DECIMAL datatype handled by MYSQL_TYPE_NEWDECIMAL
			// NUMERIC datatype handled by MYSQL_TYPE_NEWDECIMAL (note: NUMERIC is implemented as DECIMAL by MySQL)
			//
			// SMALLINT datatype handled by MYSQL_TYPE_SHORT
			// MEDIUMINT datatype handled by MYSQL_TYPE_INT24
			// BIT datatype handled by MYSQL_TYPE_BIT
			// Note: CHAR datatype isn't considered numeric and is handled by MYSQL_TYPE_STRING
			
			NSMutableArray *fieldNameCollector = [[NSMutableArray alloc] initWithCapacity:myStatement->field_count];
			NSMutableArray *fieldCollector = [[NSMutableArray alloc] initWithCapacity:myStatement->field_count];
			NSMutableSet *sourceTables = [[NSMutableSet alloc] initWithCapacity:myStatement->field_count];
			
			[*dataTable removeAllObjects];
			
			for (NSUInteger x=0; x < myStatement->field_count;x++) {
				
				NSString *table = [MysqlFetch tableForField: myStatement->fields[x]];
				[sourceTables addObject:table];
				
				NSString *fieldName = useExtendedNames || sourceTables.count > 1 ?
					[MysqlFetch fieldNameForField:myStatement->fields[x] andTable:table] :
					[MysqlFetch fieldNameForField:myStatement->fields[x]];
				[fieldNameCollector addObject:fieldName];
				
				os_log_debug(OS_LOG_DEFAULT, "Field name: %@", fieldName);
				
				MysqlFetchField *field = [[MysqlFetchField alloc] initWithField: myStatement->fields[x]
																	  fieldName: fieldName];
				[fieldCollector addObject:field];
				
				MADDataColumn *dataColumn;
				dataColumn = [MysqlFetch dataColumnForFieldName: fieldName
													 mySqlField: myStatement->fields[x]];
				[*dataTable addColumn:dataColumn];
				
				bindings[x] = [MysqlFetch bindDataForStatement: myStatement andField: x];
				
			}
			
			
			mf.fieldNames = fieldNameCollector;
			mf.fields = fieldCollector;
			
			// A statement that returns no result columns (INSERT, UPDATE, DELETE, CREATE,
			// DROP ...) reports field_count == 0, and mysql_stmt_bind_result fails
			// client-side when it is given nothing to bind. Calling it unconditionally
			// meant the bind failed and mysql_stmt_execute was never reached, so no
			// non-SELECT statement could be run at all.
			int bindResult = 0;
			if (myStatement->field_count > 0) {
				bindResult = mysql_stmt_bind_result(myStatement,(MYSQL_BIND *)bindings);
			}

			if (bindResult) {
				errorFetch = [MysqlException errorWithConnection:connection domain:[self domain] andCode:3534];
				// Report it: without this the caller sees no error and treats a failed
				// bind as success.
				if (error != NULL) *error = errorFetch;
			} else {

				if (mysql_stmt_execute(myStatement)) {
					errorFetch = [MysqlException errorWithConnection:connection domain:[self domain] andCode:4534];
					if (error != NULL) *error = errorFetch;
				} else if (myStatement->field_count > 0) {
					// Only a statement that produces a result set can be fetched.
					// mysql_stmt_fetch on one that cannot returns an error rather than
					// MYSQL_NO_DATA, which used to spin the row loop forever.
					[self fetchResultsFromConnection:connection
									   intoDataTable:dataTable
									   withStatement:myStatement
											   fetch:mf
										 andBindings:bindings];
				}
			}

			// Release the bindings and the statement on every path, not just the
			// successful one. The binding buffers are heap-allocated and the statement
			// is not owned by an autorelease pool, so the error paths leaked both.
			for (NSUInteger x=0; x < myStatement->field_count;x++) {
				free(bindings[x].buffer);
				free(bindings[x].length);
				free(bindings[x].error);
				free(bindings[x].is_null);
			}
			free(bindings);
			mysql_stmt_close(myStatement);
		}
	}

	return *dataTable;
}

- (void)fetchResultsFromConnection: (MysqlConnection *)connection
					 intoDataTable: (MADDataTable * __autoreleasing *)dataTable
					 withStatement: (MYSQL_STMT *)statement
							 fetch: (MysqlFetch *)mf
					   andBindings: (MYSQL_BIND *)bindings  {
	[*dataTable beginBulkInsert];
	int fetchResults = 0;
	NSUInteger rowCounter = 0;

	id <MADMySQLFetchProtocol> delegate = self.delegate;

	// 0 is an ordinary row and MYSQL_DATA_TRUNCATED is a row with a truncated column;
	// both are worth converting. Anything else ends the loop -- MYSQL_NO_DATA, but also
	// any fetch error. Testing only for MYSQL_NO_DATA spins forever on an error, which
	// is exactly what mysql_stmt_fetch returns for a statement with no result set.
	while ((fetchResults = [MysqlFetch fetchStatement:statement]) == 0 ||
		   fetchResults == MYSQL_DATA_TRUNCATED) {
		
		if (delegate != nil) {
			[delegate didFetchRow:rowCounter];
		}
		
		@autoreleasepool {
			
			NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:statement->field_count];
			for (unsigned int x=0; x < statement->field_count;x++) {
				
				MYSQL_FIELD stmtFieldName = statement->fields[x];
				NSString *key = mf.fieldNames[x];
				if (*bindings[x].is_null==1) {
					dict[key] = [NSNull null];
				} else {
					switch (stmtFieldName.type) {
						case MYSQL_TYPE_TINY_BLOB:
						case MYSQL_TYPE_MEDIUM_BLOB:
						case MYSQL_TYPE_LONG_BLOB:
						case MYSQL_TYPE_BLOB: {
							
							if (fetchResults== MYSQL_DATA_TRUNCATED && *(bindings[x].error)){
							
								void *previousBuffer=bindings[x].buffer;
								unsigned long previousBufferSize = bindings[x].buffer_length;
								bindings[x].buffer_length = *(bindings[x].length);
								bindings[x].buffer = malloc(bindings[x].buffer_length);
								
								mysql_stmt_fetch_column(statement, (MYSQL_BIND *)&(bindings[x]), x , 0);
								
								NSData *theData = [NSData dataWithBytes: bindings[x].buffer
																 length: *(bindings[x].length)];
								dict[key] = theData;
								free(bindings[x].buffer);
								bindings[x].buffer_length = previousBufferSize;
								bindings[x].buffer = previousBuffer;
								
							} else {
							
								NSData *theData = [[NSData alloc] initWithBytes:bindings[x].buffer length:*(bindings[x].length)];
								dict[key] = theData;
								
								//Trying to add support for MYSQL_TYPE_TEXT, which is just like a blob with a string in it.
								if (theData.bytes != nil) {
									NSString *theDataString = [[NSString alloc] initWithUTF8String:theData.bytes];
									
									if (theDataString != nil) {

										if ([theDataString isKindOfClass:[NSString class]]) {
										
											// FIXME: This is a hack.
											if (rowCounter == 0) {
												
												MADDataColumn *column = (*dataTable).columns[(*dataTable).columnKeys[x]];
												column.type = MADDataTypeString;
											
											}
											
											if (theDataString.length != 0) {
												
												dict[key] = theDataString;
												
											} else {
											
												id data = [[NSData alloc] initWithBytes: bindings[x].buffer
																				 length: *(bindings[x].length)];
												dict[key] = data;
												
											}
										} else if ([theDataString isKindOfClass:[NSNumber class]]) {
											
											if (rowCounter == 0) {
											
												MADDataColumn *column = (*dataTable).columns[(*dataTable).columnKeys[x]];
												column.type = MADDataTypeInteger;
												
											}
											
											dict[key] = theDataString;
										} else {
											dict[key] = theDataString;
										}
									}
									if (![dict[key] respondsToSelector:@selector(compare:)]) {
										NSString *utf8String = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
										dict[key] = utf8String;
									}
								} else {
									dict[key] = [NSNull null];
								}
							}
						} break;
							
							
						case MYSQL_TYPE_STRING:
						case MYSQL_TYPE_VARCHAR:
						case MYSQL_TYPE_VAR_STRING:
						case MYSQL_TYPE_ENUM:
						case MYSQL_TYPE_SET:
						case MYSQL_TYPE_YEAR:
						case MYSQL_TYPE_GEOMETRY:
						case MYSQL_TYPE_BIT:
						{
							// TODO - the encoding type should really be read from mysql
							NSString * theString = [[NSString alloc] initWithBytes: bindings[x].buffer
																			length: *(bindings[x].length)
																		  encoding: NSUTF8StringEncoding];
							dict[key] = theString;
						} break;
							
						case MYSQL_TYPE_LONGLONG:{
							SInt64 *aValue = (SInt64 *)bindings[x].buffer;
							dict[key] = @(*aValue);
						} break;
							
						case MYSQL_TYPE_LONG: {
							SInt32 *aValue = (SInt32 *)bindings[x].buffer;
							dict[key] = @((long)*aValue);
						} break;
							
						case MYSQL_TYPE_TINY: {
							char *aValue = (char *)bindings[x].buffer;
							dict[key] = @(*aValue);
						} break;
							
						case MYSQL_TYPE_NEWDECIMAL:  {
							NSString *f=[[NSString alloc] initWithBytes:bindings[x].buffer length:*(bindings[x].length) encoding:NSUTF8StringEncoding];
							NSDecimalNumber *d=[[NSDecimalNumber alloc] initWithString:f];
							dict[key] = d;
						} break;
							
							
						case MYSQL_TYPE_TIMESTAMP2:
						case MYSQL_TYPE_TIMESTAMP: {
							NSString *f=[[NSString alloc] initWithBytes:bindings[x].buffer length:*(bindings[x].length) encoding:NSUTF8StringEncoding];
							NSDateFormatter * __autoreleasing sqlFmt = [[NSDateFormatter alloc] init];
							sqlFmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
							NSDate *date = [sqlFmt dateFromString:f];
							dict[key] = date;
						} break;
							
						case MYSQL_TYPE_FLOAT:
						{
							float *aValue = (float *)bindings[x].buffer;
							dict[key] = @(*aValue);
						} break;
							
						case MYSQL_TYPE_SHORT: {
							short *aValue = (short *)bindings[x].buffer;
							dict[key] = @(*aValue);
						} break;
							
						case MYSQL_TYPE_INT24: {
							int *aValue = (int *)bindings[x].buffer;
							NSNumber * __autoreleasing v = [[NSNumber alloc] initWithInt:*aValue];
							dict[key] = v;
						} break;

						case MYSQL_TYPE_DECIMAL:
						case MYSQL_TYPE_DOUBLE:
						{
							double *aValue = (double *)bindings[x].buffer;
							NSNumber * __autoreleasing v = [[NSNumber alloc] initWithDouble: *aValue];
							dict[key] = v;
						} break;
							
						case MYSQL_TYPE_DATETIME2:
						case MYSQL_TYPE_DATETIME:
						case MYSQL_TYPE_NEWDATE:
						{
							MYSQL_TIME *aValue = (MYSQL_TIME *)bindings[x].buffer;
							NSDateComponents *comps = [[NSDateComponents alloc] init];
							comps.year      = (NSInteger)aValue->year;
							comps.month     = (NSInteger)aValue->month;
							comps.day       = (NSInteger)aValue->day;
							comps.hour      = (NSInteger)aValue->hour;
							comps.minute    = (NSInteger)aValue->minute;
							comps.second    = (NSInteger)aValue->second;
							NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
							if (date) {
								dict[key] = date;
							}
						} break;
							
						case MYSQL_TYPE_TIME:
						case MYSQL_TYPE_TIME2:
						{
							MYSQL_TIME *aValue = (MYSQL_TIME *)bindings[x].buffer;
							NSDateComponents *comps=[[NSDateComponents alloc] init];
							comps.hour =    (NSInteger)aValue->hour;
							comps.minute =  (NSInteger)aValue->minute;
							comps.second = (NSInteger)aValue->second;
							NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
							if (date) {
								dict[key] = date;
							}
						} break;
							
						case MYSQL_TYPE_DATE:
						{
							MYSQL_TIME *aValue = (MYSQL_TIME *)bindings[x].buffer;
							NSDateComponents *comps=[[NSDateComponents alloc] init];
							comps.year  = (NSInteger)aValue->year;
							comps.month = (NSInteger)aValue->month;
							comps.day   = (NSInteger)aValue->day;
							dict[key] = comps;
						} break;
							
						case MYSQL_TYPE_NULL: {
							dict[key] = [NSNull null];
						} break;
							
						default: {
							NSAssert(NO, @"No binding for key %@ with type %s.", key, mySqlTypeForBindingAtPosition(bindings, (int)x));
						} break;
					}
				}
				
			}
			
			[*dataTable addRowWithDataForFieldKeys:dict];
		}
		rowCounter++;
	}
	[*dataTable endBulkInsert];
}

enum enum_field_types bufferTypeForBindingAtPosition(MYSQL_BIND *bindings, int position) {
	MYSQL_BIND binding = bindings[position];
	return binding.buffer_type;
}

char *mySqlTypeForBindingAtPosition(MYSQL_BIND *bindings, int position) {
	MYSQL_BIND binding = bindings[position];
	return mySQLTypeForType(binding.buffer_type);
}

+ (MADDataColumn *)dataColumnForFieldName:(NSString *)fieldName
							   mySqlField:(MYSQL_FIELD)myField NS_RETURNS_RETAINED {
	
	MADDataColumn *dataColumn = [[MADDataColumn alloc] initWithIdentifier:fieldName];
	dataColumn.fieldName = fieldName;
	dataColumn.nativeType = (int16_t)myField.type;
	dataColumn.dataLength = (int64_t)myField.length;
	dataColumn.dataPercision = (int32_t)myField.decimals;
	dataColumn.primaryKey = IS_PRI_KEY(myField.flags);
	dataColumn.type = [MADDataTypeMySQL dataTypeForNativeType:myField.type];
	
	return dataColumn;
}

+ (MYSQL_BIND)bindDataForStatement:(MYSQL_STMT *)myStatement andField:(NSUInteger)x {
	MYSQL_BIND binding;
	switch(myStatement->fields[x].type) {
		case MYSQL_TYPE_LONGLONG:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=sizeof(long long);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_LONG:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=sizeof(long);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_SHORT:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=sizeof(short);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_STRING:
		case MYSQL_TYPE_VARCHAR:
		case MYSQL_TYPE_VAR_STRING:
		case MYSQL_TYPE_ENUM:
		case MYSQL_TYPE_SET:
		case MYSQL_TYPE_YEAR:
		case MYSQL_TYPE_GEOMETRY:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=myStatement->fields[x].length;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_TINY_BLOB:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=BUFFER_SIZE_BLOB_TINY;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
			
		case MYSQL_TYPE_BLOB:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=BUFFER_SIZE_BLOB;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
			
		case MYSQL_TYPE_MEDIUM_BLOB:
		case MYSQL_TYPE_LONG_BLOB:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=BUFFER_SIZE_BLOB * 2;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_TINY:
			binding.buffer_type = myStatement->fields[x].type;
			binding.buffer_length=1;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_NEWDECIMAL:
			binding.buffer_type = MYSQL_TYPE_STRING;
			binding.buffer_length=myStatement->fields[x].length;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
			
		case MYSQL_TYPE_INT24:
			binding.buffer_type = MYSQL_TYPE_INT24;
			binding.buffer_length=sizeof(int);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_TIMESTAMP2:
		case MYSQL_TYPE_TIMESTAMP:
			binding.buffer_type = MYSQL_TYPE_STRING;
			binding.buffer_length=myStatement->fields[x].length;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_FLOAT:
			binding.buffer_type = MYSQL_TYPE_FLOAT;
			binding.buffer_length=myStatement->fields[x].length;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_DECIMAL:
		case MYSQL_TYPE_DOUBLE:
			binding.buffer_type = MYSQL_TYPE_DOUBLE;
			binding.buffer_length=myStatement->fields[x].length;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_DATETIME:
		case MYSQL_TYPE_DATETIME2:
		case MYSQL_TYPE_NEWDATE:
			binding.buffer_type = MYSQL_TYPE_DATETIME;
			binding.buffer_length=sizeof(MYSQL_TIME);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
			
		case MYSQL_TYPE_DATE:
			binding.buffer_type = MYSQL_TYPE_DATETIME;
			binding.buffer_length=sizeof(MYSQL_TIME);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
			
		case MYSQL_TYPE_TIME:
		case MYSQL_TYPE_TIME2:
			binding.buffer_type = MYSQL_TYPE_DATETIME;
			binding.buffer_length=sizeof(MYSQL_TIME);
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_BIT:
			binding.buffer_type = MYSQL_TYPE_BIT;
			binding.buffer_length=1;
			binding.buffer = calloc(1,binding.buffer_length);
			binding.length= calloc(1,sizeof(unsigned long));
			binding.error= calloc(1,sizeof(bool));
			binding.is_null= calloc(1,sizeof(bool));
			break;
		case MYSQL_TYPE_NULL:
			// A column that is always NULL, such as the literal in "SELECT NULL". There
			// is no buffer to read, but the server still writes the is_null flag, so the
			// three out-parameters need real storage. They were left uninitialised here
			// and the case fell through into the default assertion below.
			binding.buffer_type = MYSQL_TYPE_NULL;
			binding.buffer_length = 0;
			binding.buffer = NULL;
			binding.length = calloc(1,sizeof(unsigned long));
			binding.error = calloc(1,sizeof(bool));
			binding.is_null = calloc(1,sizeof(bool));
			break;

		default:
			NSAssert(NO, @"No binding found for type %s.", mySQLTypeForType(binding.buffer_type));
			binding.buffer_type = MYSQL_TYPE_NULL;
			binding.buffer = NULL;
			break;
	}
	return binding;
}

@end
