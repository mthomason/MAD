//
//  MysqlFetch.m
//  mysql_connector
//
//  Created by Karl Kraft on 4/25/07.
//  Copyright 2007-2013 Karl Kraft. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MysqlFetch.h"
#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MTDataColumn.h>
#import <Foundation/NSError.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSCalendar.h>
#import <string.h>

#import "mysql.h"

#import "MysqlFetchField.h"

#import "MysqlConnection.h"
#import "MysqlException.h"
#import "MTDataTypeMySQL.h"

#ifndef __OBJC_GC__
#define BLOB_DEFAULT_SIZE 10000
#else
#define BLOB_DEFAULT_SIZE 1000000
#endif

#define BUFFER_SIZE_BLOB_TINY    257
#define BUFFER_SIZE_BLOB         65538
#define BUFFER_SIZE_BLOB_MEDIUM  16777219       //128 MB
#define BUFFER_SIZE_BLOB_LONG    42949667300    //~1/3 of a TB

@interface MysqlFetch ()

@property(strong, readwrite) NSArray *results;

@end

@implementation MysqlFetch

/*
 dataTable = [MTDataTable dataTableFactory:@{
 typeKey : type,
 numberOfColumnsKey : numberOfColumns}];
 */

- (MTDataTable *)fetchWithCommand:(NSString *)command dataTable:(MTDataTable **)dataTable onConnection:(MysqlConnection *)connection error:(NSError * __autoreleasing *)error {
    return [self fetchWithCommand:command dataTable:dataTable onConnection:connection extendedNames:YES error:error];
}

- (NSString *)domain {
    return NSStringFromClass([self class]);
}

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

+ (MTDataColumn *)dataColumnForFieldName:(NSString *)fieldName mySqlField:(MYSQL_FIELD)myField NS_RETURNS_RETAINED {
    
    MTDataColumn *dataColumn = [[MTDataColumn alloc] initWithIdentifier:fieldName];
    
    NSInteger ftype = myField.type;
    NSNumber *fieldType = @(ftype);
    NSNumber *fieldLength = @(myField.length);
    NSNumber *fieldPercision = @(myField.decimals);
    NSNumber *fieldTypeMad = @(0);
    
    dataColumn.fieldName = fieldName;
    dataColumn.nativeColumnType = fieldType;
    dataColumn.dataLength = fieldLength;
    dataColumn.dataPercision = fieldPercision;
    dataColumn.columnType = fieldTypeMad;
    dataColumn.primaryKey = IS_PRI_KEY(myField.flags) ? YES : NO;
    
    NSNumber *cType = @([MTDataTypeMySQL dataTypeForNativeType:ftype]);
    [dataColumn setColumnType:cType];

    return dataColumn;
}

- (MTDataTable *)fetchWithCommand: (NSString *)command
                        dataTable: (MTDataTable **)dataTable
                     onConnection: (MysqlConnection *)connection
                    extendedNames: (BOOL)useExtendedNames
                            error: (NSError * __autoreleasing *)error {

    MysqlFetch *mf = [[MysqlFetch alloc] init];
    NSError *errorFetch = nil;
    
    if (!connection) {
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : @"Connection is empty.",
                                    NSLocalizedFailureReasonErrorKey : @"Connection Error"};
        errorFetch = [NSError errorWithDomain:[self domain] code:3492 userInfo:errorInfo];
    }
    
    if (errorFetch == nil) {

        MYSQL_STMT *myStatement = mysql_stmt_init(connection.connection);

        const char *cCommand = command.UTF8String;

        int prepareResult = mysql_stmt_prepare(myStatement, cCommand, strlen(cCommand));

        if (prepareResult) {
            const char *err = mysql_stmt_error(myStatement);
            unsigned int code = mysql_stmt_errno(myStatement);
            NSString *errorString = [[NSString alloc] initWithFormat:@"MySQL says %d! %s.", code, err];
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : errorString,
                                        NSLocalizedFailureReasonErrorKey : @"Error"};
            errorFetch = [NSError errorWithDomain:@"mad" code:code userInfo:errorInfo];
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
            // SMALLINT datatype not handled currently - exception will occur if used
            // MEDIUMINT datatype not handled currently - exception will occur if used
            // BIT datatype not handled currently - exception will occur if used
            // Note: CHAR datatype isn't considered numeric and is handled by MYSQL_TYPE_STRING
            
            NSMutableArray *fieldNameCollector = [[NSMutableArray alloc] initWithCapacity:myStatement->field_count];
            NSMutableArray *fieldCollector = [[NSMutableArray alloc] initWithCapacity:myStatement->field_count];
            NSMutableSet *sourceTables = [[NSMutableSet alloc] initWithCapacity:myStatement->field_count];
            
            [*dataTable removeAllObjects];
            
            for (NSUInteger x=0; x < myStatement->field_count;x++) {
            
                NSString *table = [MysqlFetch tableForField: myStatement->fields[x]];
                [sourceTables addObject:table];
                
                NSString *fieldName = useExtendedNames || sourceTables.count > 1 ? [MysqlFetch fieldNameForField:myStatement->fields[x] andTable:table] :
                                                                                   [MysqlFetch fieldNameForField:myStatement->fields[x]];
                [fieldNameCollector addObject:fieldName];
                
                MysqlFetchField *field = [[MysqlFetchField alloc] initWithField:myStatement->fields[x] fieldName:fieldName];
                [fieldCollector addObject:field];
                
                MTDataColumn *dataColumn = [MysqlFetch dataColumnForFieldName:fieldName mySqlField:myStatement->fields[x]];
                [*dataTable addColumn:dataColumn];
                
                bindings[x] = [MysqlFetch bindDataForStatement: myStatement andField: x];

            }
            
            
            [mf setFieldNames:fieldNameCollector];
            [mf setFields:fieldCollector];
            
            if (mysql_stmt_bind_result(myStatement,(MYSQL_BIND *)bindings)) {
                errorFetch = [MysqlException errorWithConnection:connection domain:[self domain] andCode:3534];
            } else {
                
                if (mysql_stmt_execute(myStatement)) {
                    errorFetch = [MysqlException errorWithConnection:connection domain:[self domain] andCode:4534];
                } else {
                    
                    [self fetchResultsFromConnection:connection
                                       intoDataTable:dataTable
                                       withStatement:myStatement
                                               fetch:mf
                                         andBindings:bindings];
                    
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
        }
    }

    return *dataTable;
}

char *mySQLTypeForType(int type);
char *mySQLTypeForType(int type) {
    switch (type) {
        case MYSQL_TYPE_DECIMAL:
            return "MYSQL_TYPE_DECIMAL";
            break;
        case MYSQL_TYPE_TINY:
            return "MYSQL_TYPE_TINY";
            break;
        case MYSQL_TYPE_SHORT:
            return "MYSQL_TYPE_SHORT";
            break;
        case MYSQL_TYPE_LONG:
            return "MYSQL_TYPE_LONG";
            break;
        case MYSQL_TYPE_FLOAT:
            return "MYSQL_TYPE_FLOAT";
            break;
        case MYSQL_TYPE_DOUBLE:
            return "MYSQL_TYPE_DOUBLE";
            break;
        case MYSQL_TYPE_NULL:
            return "MYSQL_TYPE_NULL";
            break;
        case MYSQL_TYPE_TIMESTAMP:
            return "MYSQL_TYPE_TIMESTAMP";
            break;
        case MYSQL_TYPE_INT24:
            return "MYSQL_TYPE_INT24";
            break;
        case MYSQL_TYPE_DATE:
            return "MYSQL_TYPE_DATE";
            break;
        case MYSQL_TYPE_TIME:
            return "MYSQL_TYPE_TIME";
            break;
        case MYSQL_TYPE_DATETIME:
            return "MYSQL_TYPE_DATETIME";
            break;
        case MYSQL_TYPE_YEAR:
            return "MYSQL_TYPE_YEAR";
            break;
        case MYSQL_TYPE_VARCHAR:
            return "MYSQL_TYPE_VARCHAR";
            break;
        case MYSQL_TYPE_BIT:
            return "MYSQL_TYPE_BIT";
            break;
        case MYSQL_TYPE_TIMESTAMP2:
            return "MYSQL_TYPE_TIMESTAMP2";
            break;
        case MYSQL_TYPE_DATETIME2:
            return "MYSQL_TYPE_DATETIME2";
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            return "MYSQL_TYPE_NEWDECIMAL";
            break;
        case MYSQL_TYPE_ENUM:
            return "MYSQL_TYPE_ENUM";
            break;
        case MYSQL_TYPE_SET:
            return "MYSQL_TYPE_SET";
            break;
        case MYSQL_TYPE_TINY_BLOB:
            return "MYSQL_TYPE_TINY_BLOB";
            break;
        case MYSQL_TYPE_MEDIUM_BLOB:
            return "MYSQL_TYPE_DECIMAL";
            break;
        case MYSQL_TYPE_LONG_BLOB:
            return "MYSQL_TYPE_DECIMAL";
            break;
        case MYSQL_TYPE_BLOB:
            return "MYSQL_TYPE_BLOB";
            break;
        case MYSQL_TYPE_VAR_STRING:
            return "MYSQL_TYPE_VAR_STRING";
            break;
        case MYSQL_TYPE_STRING:
            return "MYSQL_TYPE_STRING";
            break;
        case MYSQL_TYPE_GEOMETRY:
            return "MYSQL_TYPE_GEOMETRY";
            break;
        default:
            return "Unknown";
            break;
    }
}

+ (void)logBindings:(MYSQL_BIND)binding {
#ifdef DEBUG
    NSLog(@"Binding %s (%lu)", mySQLTypeForType(binding.buffer_type), binding.buffer_length);
#endif
}

+ (NSData *)dataForColumnBindings:(MYSQL_BIND)bindings column:(int)x statement:(MYSQL_STMT *)statement fetchResults:(int)fetchResults NS_RETURNS_RETAINED {
    void *previousBuffer=bindings.buffer;
    unsigned long previousBufferSize=bindings.buffer_length;
    bindings.buffer_length=*(bindings.length);
    bindings.buffer=malloc(bindings.buffer_length);
    
    mysql_stmt_fetch_column(statement, (MYSQL_BIND *)&(bindings), x , 0);
    
    NSData * result = [[NSData alloc] initWithBytes:bindings.buffer length:*(bindings.length)];
    
    free(bindings.buffer);
    bindings.buffer_length=previousBufferSize;
    bindings.buffer=previousBuffer;

    return result;
}

+ (NSData *)dataForColumnBindings:(MYSQL_BIND)binding column:(int)x statement:(MYSQL_STMT *)statement NS_RETURNS_RETAINED {

    id result = [[NSData alloc] initWithBytes:binding.buffer length:*(binding.length)];
    
    //Trying to add support for MYSQL_TYPE_TEXT, which is just like a blob with a string in it.
    if (((NSData *)result).bytes != nil) {

        NSString *theDataString = [[NSString alloc] initWithUTF8String:((NSData *)result).bytes];
        if (theDataString != nil) {
        
            if ([theDataString isKindOfClass:[NSString class]]) {
                if (theDataString.length != 0) {
                    result = theDataString;
                }
                
            } else if ([theDataString isKindOfClass:[NSNumber class]]) {
                result = theDataString;
            } else {
                result = theDataString;
            }
        }
        if (![result respondsToSelector:@selector(compare:)]) {
            NSString *utf8String = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
            result = utf8String;
        }
    } else {
        result = [NSNull null];
    }
    return result;
}

- (void)fetchResultsFromConnection:(MysqlConnection *)connection intoDataTable:(MTDataTable **)dataTable withStatement:(MYSQL_STMT *)statement fetch:(MysqlFetch *)mf andBindings:(MYSQL_BIND *)bindings  {
    [*dataTable beginBulkInsert];
    int fetchResults;
    NSUInteger rowCounter = 0;
    
    
    while ((fetchResults = [MysqlFetch fetchStatement:statement]) != MYSQL_NO_DATA) {
        
        if (self.delegate != nil) {
            [self.delegate didFetchRow:rowCounter];
        }
        
        @autoreleasepool {
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:statement->field_count];
            for (unsigned int x=0; x < statement->field_count;x++) {
                
                MYSQL_FIELD stmtFieldName = statement->fields[x];
                NSString *key = [mf fieldNames][x];
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
                                unsigned long previousBufferSize=bindings[x].buffer_length;
                                bindings[x].buffer_length=*(bindings[x].length);
                                bindings[x].buffer=malloc(bindings[x].buffer_length);
                                
                                mysql_stmt_fetch_column(statement, (MYSQL_BIND *)&(bindings[x]), x , 0);
                                
                                NSData *theData = [NSData dataWithBytes:bindings[x].buffer length:*(bindings[x].length)];
                                dict[key] = theData;
                                free(bindings[x].buffer);
                                bindings[x].buffer_length=previousBufferSize;
                                bindings[x].buffer=previousBuffer;
                            } else {
                                NSData *theData = [NSData dataWithBytes:bindings[x].buffer length:*(bindings[x].length)];
                                dict[key] = theData;
                                
                                //Trying to add support for MYSQL_TYPE_TEXT, which is just like a blob with a string in it.
                                if (theData.bytes != nil) {
                                    NSString *theDataString = [NSString stringWithUTF8String:theData.bytes];
                                    if (theDataString != nil) {
                                        if ([theDataString isKindOfClass:[NSString class]]) {
                                            // FIXME: This is a hack.
                                            if (rowCounter == 0) {
                                                NSString *columnKeys = (*dataTable).columnKeys[x];
                                                MTDataColumn *column = (*dataTable).columns[columnKeys];
                                                
                                                NSNumber *columnTypeString = [[NSNumber alloc] initWithUnsignedInteger: MTDataTypeString];
                                                [column setColumnType:columnTypeString];
                                                
                                            }
                                            if (theDataString.length != 0) {
                                                dict[key] = theDataString;
                                            } else {
                                            
                                                NSData *theData = [[NSData alloc] initWithBytes:bindings[x].buffer length:*(bindings[x].length)];
                                                dict[key] = theData;
                                                
                                            }
                                        } else if ([theDataString isKindOfClass:[NSNumber class]]) {
                                            if (rowCounter == 0) {
                                                MTDataColumn *column = [*dataTable columns][[*dataTable columnKeys][x]];
                                                NSNumber *columnTypeString = [NSNumber numberWithUnsignedInteger: MTDataTypeInteger];
                                                [column setColumnType:columnTypeString];
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
                            [sqlFmt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
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
                        }
                            
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
                            NSDateComponents * __autoreleasing comps = [[NSDateComponents alloc] init];
                            [comps setYear:aValue->year];
                            [comps setMonth:aValue->month];
                            [comps setDay:aValue->day];
                            [comps setHour:aValue->hour];
                            [comps setMinute:aValue->minute];
                            [comps setSecond:aValue->second];
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
                            [comps setHour:aValue->hour];
                            [comps setMinute:aValue->minute];
                            [comps setSecond:aValue->second];
                            NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                            if (date) {
                                dict[key] = date;
                            }
                        } break;
                            
                        case MYSQL_TYPE_DATE:
                        {
                            MYSQL_TIME *aValue = (MYSQL_TIME *)bindings[x].buffer;
                            NSDateComponents *comps=[[NSDateComponents alloc] init];
                            [comps setYear:aValue->year];
                            [comps setMonth:aValue->month];
                            [comps setDay:aValue->day];
                            dict[key] = comps;
                        } break;
                            
                        case MYSQL_TYPE_NULL: {
                            dict[key] = [NSNull null];
                        } break;
                            
                        default: {
                            NSAssert(false, @"No binding for key %@ with type %s.", key, mySQLTypeForType(bindings[x].buffer_type));
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

+ (int)fetchStatement:(MYSQL_STMT *)statement {
    int result = MYSQL_NO_DATA;
    result = mysql_stmt_fetch(statement);
    return result;
}

+ (MYSQL_BIND)bindDataForStatement:(MYSQL_STMT *)myStatement andField:(NSUInteger)x {
    MYSQL_BIND binding;
    switch(myStatement->fields[x].type) {
        case MYSQL_TYPE_LONGLONG:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=sizeof(long long);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_LONG:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=sizeof(long);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_SHORT:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=sizeof(short);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
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
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_TINY_BLOB:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=BUFFER_SIZE_BLOB_TINY;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
            
        case MYSQL_TYPE_BLOB:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=BUFFER_SIZE_BLOB;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
            
        case MYSQL_TYPE_MEDIUM_BLOB:
        case MYSQL_TYPE_LONG_BLOB:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=BUFFER_SIZE_BLOB * 2;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_TINY:
            binding.buffer_type = myStatement->fields[x].type;
            binding.buffer_length=1;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            binding.buffer_type = MYSQL_TYPE_STRING;
            binding.buffer_length=myStatement->fields[x].length;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
            
        case MYSQL_TYPE_INT24:
            binding.buffer_type = MYSQL_TYPE_INT24;
            binding.buffer_length=sizeof(int);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_TIMESTAMP2:
        case MYSQL_TYPE_TIMESTAMP:
            binding.buffer_type = MYSQL_TYPE_STRING;
            binding.buffer_length=myStatement->fields[x].length;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_FLOAT:
            binding.buffer_type = MYSQL_TYPE_FLOAT;
            binding.buffer_length=myStatement->fields[x].length;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_DECIMAL:
        case MYSQL_TYPE_DOUBLE:
            binding.buffer_type = MYSQL_TYPE_DOUBLE;
            binding.buffer_length=myStatement->fields[x].length;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_DATETIME:
        case MYSQL_TYPE_DATETIME2:
        case MYSQL_TYPE_NEWDATE:
            binding.buffer_type = MYSQL_TYPE_DATETIME;
            binding.buffer_length=sizeof(MYSQL_TIME);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
            
        case MYSQL_TYPE_DATE:
            binding.buffer_type = MYSQL_TYPE_DATETIME;
            binding.buffer_length=sizeof(MYSQL_TIME);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
            
        case MYSQL_TYPE_TIME:
        case MYSQL_TYPE_TIME2:
            binding.buffer_type = MYSQL_TYPE_DATETIME;
            binding.buffer_length=sizeof(MYSQL_TIME);
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_BIT:
            binding.buffer_type = MYSQL_TYPE_BIT;
            binding.buffer_length=1;
            binding.buffer = calloc(1,binding.buffer_length);
            binding.length= calloc(1,sizeof(unsigned long));
            binding.error= calloc(1,sizeof(my_bool));
            binding.is_null= calloc(1,sizeof(my_bool));
            break;
        case MYSQL_TYPE_NULL:
            binding.buffer_type = MYSQL_TYPE_NULL;
            binding.buffer = NULL;
            
            
        default:
            NSAssert(false, @"No binding found for type %s.", mySQLTypeForType(binding.buffer_type));
            binding.buffer_type = MYSQL_TYPE_NULL;
            binding.buffer = NULL;
            break;
    }
    return binding;
    
}

@end
