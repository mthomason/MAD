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
#import <Foundation/NSError.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDecimalNumber.h>
#import <Foundation/NSDateFormatter.h>
#import <Foundation/NSCalendar.h>
#import <string.h>

#import "MysqlFetchField.h"
#import "MysqlConnection.h"
#import "MysqlException.h"

#import "MTDataTypeMySQL.h"

@interface MysqlFetch ()

@property(strong, readwrite) NSArray *results;

@end

@implementation MysqlFetch

/*
 dataTable = [MTDataTable newDataTableWithDefinition:@{
 typeKey : type,
 numberOfColumnsKey : numberOfColumns}];
 */

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

+ (NSData *)dataForColumnBindings:(MYSQL_BIND)bindings
                           column:(unsigned int)column
                        statement:(MYSQL_STMT *)statement
                     fetchResults:(int)fetchResults NS_RETURNS_RETAINED {
    void *previousBuffer=bindings.buffer;
    unsigned long previousBufferSize=bindings.buffer_length;
    bindings.buffer_length=*(bindings.length);
    bindings.buffer=malloc(bindings.buffer_length);
    
    mysql_stmt_fetch_column(statement, (MYSQL_BIND *)&(bindings), column , 0);
    
    NSData * result = [[NSData alloc] initWithBytes:bindings.buffer length:*(bindings.length)];
    
    free(bindings.buffer);
    bindings.buffer_length=previousBufferSize;
    bindings.buffer=previousBuffer;

    return result;
}

+ (NSData *)dataForColumnBindings:(MYSQL_BIND)binding
                           column:(int)x
                        statement:(MYSQL_STMT *)statement NS_RETURNS_RETAINED {

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

+ (int)fetchStatement:(MYSQL_STMT *)statement {
    int result = MYSQL_NO_DATA;
    result = mysql_stmt_fetch(statement);
    return result;
}

@end
