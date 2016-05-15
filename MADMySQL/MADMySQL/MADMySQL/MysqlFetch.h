//
//  MysqlFetch.h
//  mysql_connector
//
//  Created by Karl Kraft on 4/25/07.
//  Copyright 2007-2010 Karl Kraft. All rights reserved.
//

#ifndef MAD_MysqlFetch_h
#define MAD_MysqlFetch_h

#import <Foundation/NSObject.h>
#import "mysql.h"

@class MysqlConnection, MTDataTable, MTQuery;

@protocol MysqlFetchDelegate
@optional
    - (MTDataTable *)dataTableForQuery:(MTQuery *)query;
    - (void)didFetchRow:(NSUInteger)row;
@end

@interface MysqlFetch : NSObject

    @property(nonatomic, weak) id <MysqlFetchDelegate> delegate;

    @property(strong, readwrite) NSArray *fieldNames;
    @property(strong, readwrite) NSArray *fields;

    - (MTDataTable *)fetchWithCommand: (NSString *)s dataTable:(MTDataTable **)dataTable
                         onConnection: (MysqlConnection *)connection error:(NSError * __autoreleasing *)error;
    + (MYSQL_BIND)bindDataForStatement: (MYSQL_STMT *)myStatement andField:(NSUInteger)x;
    - (MTDataTable *)fetchWithCommand: (NSString *)command
                            dataTable: (MTDataTable **)dataTable
                         onConnection: (MysqlConnection *)connection
                        extendedNames: (BOOL)useExtendedNames
                                error: (NSError * __autoreleasing *)error;

@end

#endif
